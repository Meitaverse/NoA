// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Events} from "../libraries/Events.sol";
import {Errors} from "../libraries/Errors.sol";
import "./DNFTMarketCore.sol";
import {ICollectModule} from "../interfaces/ICollectModule.sol";
// import "hardhat/console.sol";

/**
 * @title Allows the owner of an DNFT to list it in auction.
 * @notice DNFTs in auction are escrowed in the market contract.
 * @dev There is room to optimize the storage for auctions, significantly reducing gas costs.
 * This may be done in the future, but for now it will remain as is in order to ease upgrade compatibility.
 * @author bitsoul Protocol
 */
abstract contract DNFTMarketReserveAuction is
  Initializable,
  DNFTMarketCore
{

  /// @notice The auction configuration for a specific auction id.
  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToAuctionId;
  
  /// @notice The auction id for a specific DNFT.
  /// @dev This is deleted when an auction is finalized or canceled.
  mapping(uint256 => DataTypes.ReserveAuctionStorage) private auctionIdToAuction;

  /**
   * @dev Removing old unused variables in an upgrade safe way. Was:
   * uint256 private __gap_was_minPercentIncrementInBasisPoints;
   * uint256 private __gap_was_maxBidIncrementRequirement;
   * uint256 private __gap_was_duration;
   * uint256 private __gap_was_extensionDuration;
   * uint256 private __gap_was_goLiveDate;
   */
  // uint256[5] private __gap_was_config;

  /// @notice How long an auction lasts for once the first bid has been received.
  uint256 private  DURATION; //immutable

  /// @notice The window for auction extensions, any bid placed in the final 15 minutes
  /// of an auction will reset the time remaining to 15 minutes.
  uint256 private constant EXTENSION_DURATION = 15 minutes;

  /// @notice Caps the max duration that may be configured so that overflows will not occur.
  uint256 private constant MAX_MAX_DURATION = 1_000 days;

  /// @notice Confirms that the reserve price is not zero.
  modifier onlyValidAuctionConfig(uint256 reservePrice) {
    if (reservePrice == 0) {
      revert Errors.DNFTMarketReserveAuction_Must_Set_Non_Zero_Reserve_Price();
    }
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer{}

  /**
   * @notice Configures the duration for auctions.
   * @param duration The duration for auctions, in seconds.
   */
  function __dNFT_market_reserve_auction_init(uint256 duration) internal onlyInitializing{
    if (duration > MAX_MAX_DURATION) {
      // This ensures that math in this file will not overflow due to a huge duration.
      revert Errors.DNFTMarketReserveAuction_Exceeds_Max_Duration(MAX_MAX_DURATION);
    }
    if (duration < EXTENSION_DURATION) {
      // The auction duration configuration must be greater than the extension window of 15 minutes
      revert Errors.DNFTMarketReserveAuction_Less_Than_Extension_Duration(EXTENSION_DURATION);
    }
    DURATION = duration;
  }

  /**
   * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
   * @dev The DNFT is transferred back to the owner unless there is still a buy price set.
   * @param auctionId The id of the auction to cancel.
   */
  function cancelReserveAuction(uint256 auctionId) external  {
    DataTypes.ReserveAuctionStorage memory auction = auctionIdToAuction[auctionId];
    if (auction.seller != msg.sender) {
      revert Errors.DNFTMarketReserveAuction_Only_Owner_Can_Update_Auction(auction.seller);
    }
    if (auction.endTime != 0) {
      revert Errors.DNFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
    }

    // Remove the auction.
    delete nftContractToTokenIdToAuctionId[auction.derivativeNFT][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    // Transfer the DNFT unless it still has a buy price set.
    _transferFromEscrowIfAvailable(auction.derivativeNFT, auction.tokenId, auction.seller);

    emit Events.ReserveAuctionCanceled(auctionId);
  }

  /**
   * @notice Creates an auction for the given DNFT.
   * The DNFT is held in escrow until the auction is finalized or canceled.
   * @param soulBoundTokenId The SBT id of the DNFT owner.
   * @param derivativeNFT The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   * @param currency The ERC20 currency
   * @param reservePrice The initial reserve price for the auction.
   */
  function createReserveAuction(
    uint256 soulBoundTokenId,
    address derivativeNFT,
    uint256 tokenId,
    address currency,
    uint256 reservePrice
  ) external onlyValidAuctionConfig(reservePrice) {
    if ( soulBoundTokenId == 0 || derivativeNFT == address(0) || tokenId == 0 || currency == address(0) || reservePrice == 0)
      revert Errors.InvalidParameter();    
      
    // validate martket is open for this contract?
    if (!_getMarketInfo(derivativeNFT).isOpen)
        revert Errors.Market_DNFT_Is_Not_Open(derivativeNFT);    

    uint256 auctionId = _getNextAndIncrementAuctionId();

    // If the `msg.sender` is not the owner of the DNFT, transferring into escrow should fail.
    _transferToEscrow(derivativeNFT, tokenId);

    // This check must be after _transferToEscrow in case auto-settle was required
    if (nftContractToTokenIdToAuctionId[derivativeNFT][tokenId] != 0) {
      revert Errors.DNFTMarketReserveAuction_Already_Listed(nftContractToTokenIdToAuctionId[derivativeNFT][tokenId]);
    }

    uint256 projectId = _getMarketInfo(derivativeNFT).projectId;
    if (projectId == 0) 
        revert Errors.InvalidParameter();

    uint256 publishId = IDerivativeNFT(derivativeNFT).getPublishIdByTokenId(tokenId);

    uint128 units = uint128(IERC3525(derivativeNFT).balanceOf(tokenId));

    // Store the auction details
    nftContractToTokenIdToAuctionId[derivativeNFT][tokenId] = auctionId;

    DataTypes.ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    auction.soulBoundTokenId = soulBoundTokenId;
    auction.derivativeNFT = derivativeNFT;
    auction.projectId = projectId;
    auction.publishId = publishId;

    auction.tokenId = tokenId;
    auction.units = units;
    auction.seller = payable(msg.sender);
    auction.currency = currency;
    auction.reservePrice = reservePrice;
    auction.amount = uint96(reservePrice * units);
    
    emit Events.ReserveAuctionCreated(
      msg.sender, 
      auctionId
    );
  }

  /**
   * @notice Once the countdown has expired for an auction, anyone can settle the auction.
   * This will send the DNFT to the highest bidder and distribute revenue for this sale.
   * @param auctionId The id of the auction to settle.
   */
  function finalizeReserveAuction(uint256 auctionId) external {
    if (auctionIdToAuction[auctionId].endTime == 0) {
      revert Errors.DNFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
    }
    _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: false });
  }

  /**
   * @notice Place a bid in an auction.
   * A bidder may place a bid which is at least the amount defined by `getMinBidAmount`.
   * If this is the first bid on the auction, the countdown will begin.
   * If there is already an outstanding bid, the previous bidder will be refunded at this time
   * and if the bid is placed in the final moments of the auction, the countdown may be extended.
   * 
   * @param auctionId The id of the auction to bid on.
   * @param amount The total amount to bid.
   */
  /* solhint-disable-next-line code-complexity */
  function placeBid(
    uint256 soulBoundTokenIdBidder,
    uint256 auctionId,
    uint96 amount, //new total amount to bid
    uint256 soulBoundTokenIdReferrer
  ) public {
    if (soulBoundTokenIdBidder == 0 || auctionId == 0)
      revert Errors.InvalidParameter();

    DataTypes.ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];

    if (auction.amount == 0) {
      // No auction found
      revert Errors.DNFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
    }

    uint256 endTime = auction.endTime;
    uint256 originalSoulBoundTokenIdBidder;
    uint256 originalAmount;

    // Store the bid referral
    if (soulBoundTokenIdReferrer != 0 || endTime != 0) {
      auction.soulBoundTokenIdReferrer = soulBoundTokenIdReferrer;
    }

    if (endTime == 0) {
      // This is the first bid, kicking off the auction.

      if (amount < auction.amount) {
        // The bid must be >= the reserve price.
        revert Errors.DNFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(auction.amount);
      }

      // Notify other market tools that an auction for this DNFT has been kicked off.
      // The only state change before this call is potentially withdrawing funds from SBT.
      _beforeAuctionStarted(auction.derivativeNFT, auction.tokenId);

      // Store the bid details.
      auction.amount = uint96(amount);
      auction.bidder = payable(msg.sender);
      auction.soulBoundTokenIdBidder = soulBoundTokenIdBidder;

      // On the first bid, set the endTime to now + duration.
      unchecked {
        // Duration is always set to 24hrs so the below can't overflow.
        endTime = block.timestamp + DURATION;
      }
      auction.endTime = endTime;
    } else {
      if (endTime < block.timestamp) {
        // The auction has already ended.
        revert Errors.DNFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(endTime);
      } else if (auction.bidder == msg.sender) {
        // We currently do not allow a bidder to increase their bid unless another user has outbid them first.
        revert Errors.DNFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
      } else {
        uint256 minIncrement = _getMinIncrement(auction.amount);
        if (amount < minIncrement) {
          // If this bid outbids another, it must be at least 10% greater than the last bid.
          revert Errors.DNFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(minIncrement);
        }
      }

      // Cache and update bidder state
      originalAmount = auction.amount;
      originalSoulBoundTokenIdBidder = auction.soulBoundTokenIdBidder;
      auction.amount = uint96(amount); // update
      auction.bidder = payable(msg.sender);
      auction.soulBoundTokenIdBidder = soulBoundTokenIdBidder;

      unchecked {
        // When a bid outbids another, check to see if a time extension should apply.
        // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
        // Current time plus extension duration (always 15 mins) cannot overflow.
        uint256 endTimeWithExtension = block.timestamp + EXTENSION_DURATION;
        if (endTime < endTimeWithExtension) {
          endTime = endTimeWithExtension;
          auction.endTime = endTime;
        }
      }

      //Refund the previous escrow earnest funds to bidder
      treasury.refundEarnestFunds(
            originalSoulBoundTokenIdBidder,
            auction.currency,
            originalAmount
      );
    }

    //Use SBT Value or ERC20 currency free balance for pay 
    treasury.useEarnestFundsForPay(
            soulBoundTokenIdBidder,
            auction.currency,
            amount
    );
    
    emit Events.ReserveAuctionBidPlaced(
      auctionId, 
      originalSoulBoundTokenIdBidder,
      originalAmount,
      soulBoundTokenIdBidder,
      msg.sender,
      auction.currency,
      amount, 
      endTime
    );
  } 

  /**
   * @notice If an auction has been created but has not yet received bids, the reservePrice may be
   * changed by the seller.
   * @param auctionId The id of the auction to change.
   * @param reservePrice The new reserve price for this auction.
   */
  function updateReserveAuction(uint256 auctionId, uint96 reservePrice) external onlyValidAuctionConfig(reservePrice) {
    DataTypes.ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    if (auction.seller != msg.sender) {
      revert Errors.DNFTMarketReserveAuction_Only_Owner_Can_Update_Auction(auction.seller);
    } else if (auction.endTime != 0) {
      revert Errors.DNFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
    } else if (auction.amount == uint96(reservePrice * auction.units)) {
      revert Errors.DNFTMarketReserveAuction_Price_Already_Set();
    }

    // Update the current amount by reserve price * units.
    auction.amount = uint96(reservePrice * auction.units);

    emit Events.ReserveAuctionUpdated(auctionId, reservePrice);
  }

  /**
   * @notice Settle an auction that has already ended.
   * This will send the DNFT to the highest bidder and distribute revenue for this sale.
   * @param keepInEscrow If true, the DNFT will be kept in escrow to save gas by avoiding
   * redundant transfers if the DNFT should remain in escrow, such as when the new owner
   * sets a buy price or lists it in a new auction.
   */
  function _finalizeReserveAuction(
    uint256 auctionId, 
    bool keepInEscrow
  ) private {
    DataTypes.ReserveAuctionStorage memory auction = auctionIdToAuction[auctionId];

    if (auction.endTime >= block.timestamp) {
      revert Errors.DNFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(auction.endTime);
    }

    if (!keepInEscrow) {
      // The seller was authorized when the auction was originally created
      super._transferFromEscrow(auction.derivativeNFT, auction.tokenId, auction.bidder,  address(0));
    }

    // Distribute revenue for this sale.
    address collectModule = _getMarketInfo(auction.derivativeNFT).collectModule;
    bytes memory collectModuleInitData = abi.encode(
      auction.soulBoundTokenIdReferrer, 
      BUY_REFERRER_FEE_DENOMINATOR,
      auction.units
    );
    DataTypes.RoyaltyAmounts memory royaltyAmounts = ICollectModule(collectModule).processCollect(
        auction.soulBoundTokenId,
        auction.soulBoundTokenIdBidder,
        auction.publishId,
        auction.amount,
        collectModuleInitData
    );

    // Remove the auction.
    delete nftContractToTokenIdToAuctionId[auction.derivativeNFT][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    emit Events.ReserveAuctionFinalized(
      auctionId, 
      auction.seller, 
      auction.bidder,
      royaltyAmounts
    );    

  }
  
  /**
   * @inheritdoc DNFTMarketCore
   * @dev If an auction is found:
   *  - If the auction is over, it will settle the auction and confirm the new seller won the auction.
   *  - If the auction has not received a bid, it will invalidate the auction.
   *  - If the auction is in progress, this will revert.
   */
  function _transferFromEscrow(
      address derivativeNFT,
      uint256 tokenId,
      address recipient,
      address authorizeSeller
  ) internal virtual override{
    uint256 auctionId = nftContractToTokenIdToAuctionId[derivativeNFT][tokenId];

    if (auctionId != 0) {
      DataTypes.ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
      if (auction.endTime == 0) {
        // The auction has not received any bids yet so it may be invalided.

        if (authorizeSeller != address(0) && auction.seller != authorizeSeller) {
          // The account trying to transfer the DNFT is not the current owner.
          revert Errors.DNFTMarketReserveAuction_Not_Matching_Seller(auction.seller);
        }

        // Remove the auction ?
        delete nftContractToTokenIdToAuctionId[derivativeNFT][tokenId];
        delete auctionIdToAuction[auctionId];

        emit Events.ReserveAuctionInvalidated(auctionId);
      } else {
        // If the auction has ended, the highest bidder will be the new owner
        // and if the auction is in progress, this will revert.

        // `authorizeSeller != address(0)` does not apply here since an unsettled auction must go
        // through this path to know who the authorized seller should be.
        if (auction.bidder != authorizeSeller) {
          revert Errors.DNFTMarketReserveAuction_Not_Matching_Seller(auction.bidder);
        }

        // Finalization will revert if the auction has not yet ended.
        _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: true });
      }
      // The seller authorization has been confirmed.
      authorizeSeller = address(0);

    }

    super._transferFromEscrow(derivativeNFT, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc DNFTMarketCore
   * @dev Checks if there is an auction for this DNFT before allowing the transfer to continue.
   */
  function _transferFromEscrowIfAvailable(
        address derivativeNFT,
        uint256 tokenId,
        address recipient
  ) internal virtual override {
    if (nftContractToTokenIdToAuctionId[derivativeNFT][tokenId] == 0) {
      // No auction was found
      super._transferFromEscrowIfAvailable(derivativeNFT, tokenId, recipient);
    }
  }

  /**
   * @inheritdoc DNFTMarketCore
   */
  function _transferToEscrow(address derivativeNFT, uint256 tokenId) 
    internal virtual override
  {
    uint256 auctionId = nftContractToTokenIdToAuctionId[derivativeNFT][tokenId];
    if (auctionId == 0) {
      // DNFT is not in auction
      super._transferToEscrow(derivativeNFT, tokenId);
      return;
    }

    // auctionId != 0 will trigger finalize auction
    // Using storage saves gas since most of the data is not needed
    DataTypes.ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      // Reserve price set, confirm the seller is a match
      if (auction.seller != msg.sender) {
        revert Errors.DNFTMarketReserveAuction_Not_Matching_Seller(auction.seller);
      }
    } else {
      // Auction in progress, confirm the highest bidder is a match
      if (auction.bidder != msg.sender) {
        revert Errors.DNFTMarketReserveAuction_Not_Matching_Seller(auction.bidder);
      }

      // Finalize auction but leave DNFT in escrow, reverts if the auction has not ended
      _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: true });
    }
  }

  /**
   * @notice Returns the minimum amount(price) a bidder must spend to participate in an auction.
   * Bids must be greater than or equal to this value or they will revert.
   * @param auctionId The id of the auction to check.
   * @return minimum The minimum amount for a bid to be accepted.
   */
  function getMinBidAmount(uint256 auctionId) external view returns (uint256 minimum) {
    DataTypes.ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      return auction.amount;
    }
    return _getMinIncrement(auction.amount);
  }

  /**
   * @notice Returns auction details for a given auctionId.
   * @param auctionId The id of the auction to lookup.
   */
  function getReserveAuction(uint256 auctionId) external view returns (DataTypes.ReserveAuction memory auction) {
    DataTypes.ReserveAuctionStorage storage auctionStorage = auctionIdToAuction[auctionId];
    auction = DataTypes.ReserveAuction(
      auctionStorage.soulBoundTokenId,
      auctionStorage.derivativeNFT,
      auctionStorage.projectId,
      auctionStorage.publishId,
      auctionStorage.tokenId,
      auctionStorage.units,
      auctionStorage.seller,
      DURATION,
      EXTENSION_DURATION,
      auctionStorage.endTime,
      auctionStorage.bidder,
      auctionStorage.soulBoundTokenIdBidder,
      auctionStorage.currency,
      auctionStorage.reservePrice,
      auctionStorage.amount
    );
  }

  /**
   * @notice Returns the auctionId for a given DNFT, or 0 if no auction is found.
   * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
   * @param derivativeNFT The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   * @return auctionId The id of the auction, or 0 if no auction is found.
   */
  function getReserveAuctionIdFor(address derivativeNFT, uint256 tokenId) external view returns (uint256 auctionId) {
    auctionId = nftContractToTokenIdToAuctionId[derivativeNFT][tokenId];
  }

  /**
   * @notice Returns the SBT id of referrer for the current highest bid in the auction, or 0.
   */
  function getReserveAuctionBidReferrer(uint256 auctionId) external view returns (uint256 soulBoundTokenIdReferrer) {
    DataTypes.ReserveAuctionStorage storage auction = auctionIdToAuction[auctionId];
    return auction.soulBoundTokenIdReferrer;
  }


  /**
   * @inheritdoc DNFTMarketCore
   */
  function _isInActiveAuction(address derivativeNFT, uint256 tokenId) internal view override returns (bool) {
    uint256 auctionId = nftContractToTokenIdToAuctionId[derivativeNFT][tokenId];
    return auctionId != 0 && auctionIdToAuction[auctionId].endTime >= block.timestamp;
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  // uint256[1_000] private __gap;
}
