// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Events} from "../libraries/Events.sol";
import {Errors} from "../libraries/Errors.sol";
import {ICollectModule} from "../interfaces/ICollectModule.sol";
import "./DNFTMarketCore.sol";

// import "hardhat/console.sol";

/**
 * @title Allows collectors to make an offer for an DNFT, valid for 24-25 hours.
 * @notice Funds are escrowed in the Bank Treasury token contract.
 * @author bitsoul Protocol
 */
abstract contract DNFTMarketOffer is
  Initializable,
  DNFTMarketCore
{
  // using AddressUpgradeable for address;
  // using SafeMathUpgradeable for uint256;
  // using SafeMathUpgradeable128 for uint128;

    /// @notice Stores the highest offer for each DNFT.
  mapping(address => mapping(uint256 => DataTypes.Offer)) internal nftContractToIdToOffer;

  /**
   * @notice Accept the highest offer for an DNFT.
   * @dev The offer must not be expired and the DNFT owned + approved by the seller or
   * available in the market contract's escrow.
   * @param soulBoundTokenId The soulBoundTokenId of owner.
   * @param derivativeNFT The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   * @param offerFrom The address of the collector that you wish to sell to.
   * If the current highest offer is not from this user, the transaction will revert.
   * This could happen if a last minute offer was made by another collector,
   * and would require the seller to try accepting again.
   * @param minAmount The minimum value of the highest offer for it to be accepted.
   * If the value is less than this amount, the transaction will revert.
   * This could happen if the original offer expires and is replaced with a smaller offer.
   */
  function acceptOffer(
    uint256 soulBoundTokenId,
    address derivativeNFT,
    uint256 tokenId,
    address offerFrom,
    uint96 minAmount
  ) external{
    if ( soulBoundTokenId == 0 || minAmount == 0 || derivativeNFT == address(0))
      revert Errors.InvalidParameter();

    // validate martket is open for this contract
    if (!_getMarketInfo(derivativeNFT).isOpen)
        revert Errors.Market_DNFT_Is_Not_Open(derivativeNFT);
       
    address account = _getWallet(soulBoundTokenId);
    if (account != msg.sender) {
      revert Errors.NotProfileOwner();
    }
  
    DataTypes.Offer storage offer = nftContractToIdToOffer[derivativeNFT][tokenId];

    // Validate offer expiry and amount
    if (offer.expiration < block.timestamp) {
      revert Errors.DNFTMarketOffer_Offer_Expired(offer.expiration);
    } else if (offer.amount < minAmount) {
      revert Errors.DNFTMarketOffer_Offer_Below_Min_Amount(offer.amount);
    } 
    
    // Validate the buyer
    if (offer.buyer != offerFrom) {
      revert Errors.DNFTMarketOffer_Offer_From_Does_Not_Match(offer.buyer);
    }

    _acceptOffer(soulBoundTokenId, derivativeNFT, tokenId);
  }

  /**
   * @notice Make an offer for any DNFT which is valid for 24-25 hours.
   * The funds will be locked in the Treasury contract and become available once the offer is outbid or has expired.
   * @dev An offer may be made for an DNFT before it is minted, although we generally not recommend you do that.
   * If there is a buy price set at this price or lower, that will be accepted instead of making an offer.
   * The account's available balance must be >= `amount`.
   * 
   * @param offerParam The parameters of offer.
   * @return expiration The timestamp for when this offer will expire.
   * This is provided as a return value in case another contract would like to leverage this information,
   * user's should refer to the expiration in the `OfferMade` event log.
   * If the buy price is accepted instead, `0` is returned as the expiration since that's n/a.
   */
  function makeOffer(
    DataTypes.OfferParam memory offerParam
  ) external returns (uint256 expiration) {
 if (
      offerParam.soulBoundTokenIdBuyer == 0 || 
      offerParam.derivativeNFT == address(0) || 
      offerParam.amount == 0 
    )    
      revert Errors.InvalidParameter();    
      
    // validate martket is open for this contract?
    if (!_getMarketInfo(offerParam.derivativeNFT).isOpen)
        revert Errors.Market_DNFT_Is_Not_Open(offerParam.derivativeNFT);

    // validate currency is in whitelisted
    if (!_isCurrencyWhitelisted(offerParam.currency))
        revert Errors.CurrencyNotInWhitelisted(offerParam.currency);

    address buyer = _getWallet(offerParam.soulBoundTokenIdBuyer);
    if (buyer != msg.sender) {
      revert Errors.NotProfileOwner();
    }

    // If there is a buy price set at this price or lower, accept that instead.
    if (_autoAcceptBuyPrice(
        offerParam.soulBoundTokenIdBuyer, 
        offerParam.derivativeNFT, 
        offerParam.tokenId, 
        offerParam.amount
    )) {
      // If the buy price is accepted, `0` is returned as the expiration since that's n/a.
      return 0;
    }

    if (_isInActiveAuction(offerParam.derivativeNFT, offerParam.tokenId)) {
      revert Errors.DNFTMarketOffer_Cannot_Be_Made_While_In_Auction();
    }
      
    uint128 units = uint128(IERC3525(offerParam.derivativeNFT).balanceOf(offerParam.tokenId));

    DataTypes.Offer storage offer = nftContractToIdToOffer[offerParam.derivativeNFT][offerParam.tokenId];

    if (offer.expiration < block.timestamp) {
      // This is a new offer for the DNFT (no other offer found or the previous offer expired)
      // Lock the offer amount in Treasury until the offer expires in 24-25 hours.
      expiration = treasury.marketLockupFor(
        buyer, 
        offerParam.soulBoundTokenIdBuyer, 
        offerParam.currency, 
        offerParam.amount
      );

    } else {
      // A previous offer exists and has not expired

      uint256 minIncrement = _getMinIncrement(offer.amount);
      if (offerParam.amount < minIncrement) {
        // A non-trivial increase in price is required to avoid sniping
        revert Errors.DNFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(minIncrement);
      }

      // Unlock the previous offer so that the earnest funds are available for other offers or to transfer / withdraw
      // and lock the new offer amounts in treasury until the offer expires in 24-25 hours.
      
      expiration = treasury.marketChangeLockup(
        offer.soulBoundTokenIdBuyer, // unlock previous offer
        offer.currency,
        offer.expiration,
        offer.amount,
        offer.soulBoundTokenIdBuyer, // current offer's SBT id
        offer.amount
      );
    }

    // Record offer details
    offer.derivativeNFT = offerParam.derivativeNFT;

    uint256 publishId = IDerivativeNFT(offerParam.derivativeNFT).getPublishIdByTokenId(offerParam.tokenId);
    offer.publishId = publishId;

    offer.buyer = buyer;
    offer.soulBoundTokenIdBuyer = offerParam.soulBoundTokenIdBuyer;
    // The SBT contract guarantees that the expiration fits into 32 bits.
    offer.expiration = uint32(expiration);

    //@notice not change
    offer.currency = offerParam.currency;
    offer.amount = uint96(offerParam.amount);
    offer.units = units;
    offer.soulBoundTokenIdReferrer = offerParam.soulBoundTokenIdReferrer;

    emit Events.OfferMade(
      offer.derivativeNFT, 
      offerParam.tokenId,
      offer.units,
      buyer, 
      offer.currency, 
      offer.amount, 
      expiration
    );

  }

  /**
   * @notice Accept the highest offer for an DNFT from the `msg.sender` account.
   * The DNFT will be transferred to the buyer and revenue from the sale will be distributed.
   * @dev The caller must validate the expiry and amount before calling this helper.
   * This may invalidate other market tools, such as clearing the buy price if set.
   */
  function _acceptOffer(
    uint256 soulBoundTokenIdOwner,
    address derivativeNFT, 
    uint256 tokenId
  ) private{
    DataTypes.Offer memory offer = nftContractToIdToOffer[derivativeNFT][tokenId];

    // Remove offer
    delete nftContractToIdToOffer[derivativeNFT][tokenId];
   
    // After accept the highest offer, Transfer earnest funds from the buyer's escrpw balance in the BankTreasury contract.
    treasury.marketTransferLocked(
      offer.buyer, 
      offer.soulBoundTokenIdBuyer, 
      msg.sender, //seller
      soulBoundTokenIdOwner, 
      offer.expiration, 
      offer.currency,
      offer.amount
    );

    if (IERC3525(derivativeNFT).ownerOf(tokenId) == msg.sender) {
        IERC3525(derivativeNFT).transferFrom(msg.sender, offer.buyer, tokenId);
    } else {
        _transferFromEscrow(derivativeNFT, tokenId, offer.buyer, address(0));
    }

    // Distribute revenue for this sale leveraging the SBT Value received from the SBT contract in the line above.
    address collectModule = _getMarketInfo(derivativeNFT).collectModule;
    bytes memory collectModuleInitData = abi.encode(
      offer.soulBoundTokenIdReferrer, 
      BUY_REFERRER_FEE_DENOMINATOR,
      offer.units
    );
    
    DataTypes.RoyaltyAmounts memory royaltyAmounts = ICollectModule(collectModule).processCollect(
        soulBoundTokenIdOwner,
        offer.soulBoundTokenIdBuyer,
        offer.publishId,
        uint96(offer.amount),
        collectModuleInitData
    );

    emit Events.OfferAccepted(
      derivativeNFT, 
      tokenId, 
      offer.buyer, 
      msg.sender,  //seller
      offer.currency,
      royaltyAmounts
    );

  }

  /**
   * @inheritdoc DNFTMarketCore
   * @dev Invalidates the highest offer when an auction is kicked off, if one is found.
   */
  function _beforeAuctionStarted(address derivativeNFT, uint256 tokenId) internal virtual override {
    _invalidateOffer(derivativeNFT, tokenId);
    super._beforeAuctionStarted(derivativeNFT, tokenId);
  }
 
  /**
   * @inheritdoc DNFTMarketCore
   */
  function _autoAcceptOffer(
    DataTypes.BuyPriceParam memory buyPriceParam,
    uint128 units 
  ) internal override {
    DataTypes.Offer storage offer = nftContractToIdToOffer[buyPriceParam.derivativeNFT][buyPriceParam.tokenId];
    if (offer.expiration < block.timestamp || offer.amount < buyPriceParam.salePrice * units) {
      // No offer found, the most recent offer is now expired, or the highest offer is below the minimum amount.
      return;
    }
    
    _acceptOffer(
          buyPriceParam.soulBoundTokenId, 
          buyPriceParam.derivativeNFT, 
          buyPriceParam.tokenId
    );
  }

  /**
   * @inheritdoc DNFTMarketCore
   */
  function _cancelSendersOffer(address derivativeNFT, uint256 tokenId) internal override {
    DataTypes.Offer storage offer = nftContractToIdToOffer[derivativeNFT][tokenId];
    if (offer.buyer == msg.sender) {
      _invalidateOffer(derivativeNFT, tokenId);
    }
  } 

  /**
   * @notice Invalidates the offer and frees SBT Value from escrow, if the offer has not already expired.
   * @dev Offers are not invalidated when the DNFT is purchased by accepting the buy price unless it
   * was purchased by the same user.
   * The user which just purchased the DNFT may have buyer's remorse and promptly decide they want a fast exit,
   * accepting a small loss to limit their exposure.
   */
  function _invalidateOffer(address derivativeNFT, uint256 tokenId) private {
    if (nftContractToIdToOffer[derivativeNFT][tokenId].expiration >= block.timestamp) {
      // An offer was found and it has not already expired
      DataTypes.Offer memory offer = nftContractToIdToOffer[derivativeNFT][tokenId];

      // Remove offer
      delete nftContractToIdToOffer[derivativeNFT][tokenId];

      // Unlock the offer so that the SBT tokens are available for other offers or to transfer / withdraw
      treasury.marketUnlockFor(
         offer.buyer,
         offer.soulBoundTokenIdBuyer, 
         offer.expiration, 
         offer.currency, 
         offer.amount
      );

      emit Events.OfferInvalidated(derivativeNFT, tokenId);
    }
  }

  /**
   * @notice Returns the minimum amount a collector must offer for this DNFT in order for the offer to be valid.
   * @dev Offers for this DNFT which are less than this value will revert.
   * Once the previous offer has expired smaller offers can be made.
   * @param derivativeNFT The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   * @return minimum The minimum amount that must be offered for this DNFT.
   */
  function getMinOfferAmount(address derivativeNFT, uint256 tokenId) external view returns (uint256 minimum) {
    DataTypes.Offer storage offer = nftContractToIdToOffer[derivativeNFT][tokenId];
    if (offer.expiration >= block.timestamp) {
      return _getMinIncrement(offer.amount);
    }
    // Absolute min is anything > 0
    return 1;
  }

  /**
   * @notice Returns details about the current highest offer for an DNFT.
   * @dev Default values are returned if there is no offer or the offer has expired.
   * @param derivativeNFT The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   * @return buyer The address of the buyer that made the current highest offer.
   * Returns `address(0)` if there is no offer or the most recent offer has expired.
   * @return expiration The timestamp that the current highest offer expires.
   * Returns `0` if there is no offer or the most recent offer has expired.
   * @return amount The amount being offered for this DNFT.
   * @return soulBoundTokenIdReferrer The SBT id of referrer
   * Returns `0` if there is no offer or the most recent offer has expired.
   */
  function getOffer(address derivativeNFT, uint256 tokenId)
    external
    view
    returns (
      address buyer,
      uint256 expiration,
      uint96 amount,
      uint256 soulBoundTokenIdReferrer
    )
  {
    DataTypes.Offer storage offer = nftContractToIdToOffer[derivativeNFT][tokenId];
    if (offer.expiration < block.timestamp) {
      // offer not found or has expired
      return (address(0), 0, 0, 0);
    }

    // An offer was found and it has not yet expired.
    return (offer.buyer, offer.expiration, offer.amount, offer.soulBoundTokenIdReferrer);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  // uint256[1_000] private __gap;
}
