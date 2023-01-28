// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
// import "../libraries/SafeMathUpgradeable128.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Events} from "../libraries/Events.sol";
import {Errors} from "../libraries/Errors.sol";
import {IManager} from "../interfaces/IManager.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";

import "./DNFTMarketCore.sol";
import {MarketFees} from "./MarketFees.sol";

/**
 * @title Allows collectors to make an offer for an DNFT, valid for 24-25 hours.
 * @notice Funds are escrowed in the SBT token contract.
 * @author batu-inal & HardlyDifficult
 */
abstract contract DNFTMarketOffer is
  Initializable,
  DNFTMarketCore,
  MarketFees
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
   * @param units The units of the buyer want.
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
    uint128 units,
    address offerFrom,
    uint256 minAmount
  ) external {
    if ( units == 0 || minAmount == 0 )
      revert Errors.InvalidParameter();

    // validate martket is open for this contract?
    if (!_getMarketInfo(derivativeNFT).isOpen)
        revert Errors.Market_DNFT_Is_Not_Open(derivativeNFT);
       
    address account = _getWallet(soulBoundTokenId);
    if (account != msg.sender) {
      revert Errors.NotProfileOwner();
    }
  
    DataTypes.Offer storage offer = nftContractToIdToOffer[derivativeNFT][tokenId];

    // Validate offer expiry and amount and units
    if (offer.expiration < block.timestamp) {
      revert Errors.DNFTMarketOffer_Offer_Expired(offer.expiration);
    } else if (offer.amount < minAmount) {
      revert Errors.DNFTMarketOffer_Offer_Below_Min_Amount(offer.amount);
    } else if (offer.units < units) {
       revert Errors.DNFTMarketOffer_Offer_Insufficient_Units(offer.units);
    }
    // Validate the buyer
    if (offer.buyer != offerFrom) {
      revert Errors.DNFTMarketOffer_Offer_From_Does_Not_Match(offer.buyer);
    }

    _acceptOffer(soulBoundTokenId, derivativeNFT, tokenId, units);
  }

  /**
   * @notice Make an offer for any DNFT which is valid for 24-25 hours.
   * The funds will be locked in the SBT token contract and become available once the offer is outbid or has expired.
   * @dev An offer may be made for an DNFT before it is minted, although we generally not recommend you do that.
   * If there is a buy price set at this price or lower, that will be accepted instead of making an offer.
   * `msg.value` must be <= `amount` and any delta will be taken from the account's available SBT balance.
   * @param soulBoundTokenIdBuyer The soulBoundTokenId of offer.
   * @param derivativeNFT The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   * @param units The units buyer want to buy.
   * @param amount The amount(price) to offer for this DNFT.
   * @param soulBoundTokenIdReferrer The SBt id of refrerrer for the offer.
   * @return expiration The timestamp for when this offer will expire.
   * This is provided as a return value in case another contract would like to leverage this information,
   * user's should refer to the expiration in the `OfferMade` event log.
   * If the buy price is accepted instead, `0` is returned as the expiration since that's n/a.
   */
  function makeOffer(
    uint256 soulBoundTokenIdBuyer,
    address derivativeNFT,
    uint256 tokenId,
    uint128 units,
    uint256 amount,
    uint256 soulBoundTokenIdReferrer
  ) external payable returns (uint256 expiration) {
    if ( units == 0 || amount == 0 )
      revert Errors.InvalidParameter();    
      
    // validate martket is open for this contract?
    if (!_getMarketInfo(derivativeNFT).isOpen)
        revert Errors.Market_DNFT_Is_Not_Open(derivativeNFT);
       
    address buyer = _getWallet(soulBoundTokenIdBuyer);
    if (buyer != msg.sender) {
      revert Errors.NotProfileOwner();
    }    

    // If there is a buy price set at this price or lower, accept that instead.
    
    if (_autoAcceptBuyPrice(soulBoundTokenIdBuyer, derivativeNFT, tokenId, units, amount)) {
      // If the buy price is accepted, `0` is returned as the expiration since that's n/a.
      return 0;
    }

    if (_isInActiveAuction(derivativeNFT, tokenId)) {
      revert Errors.DNFTMarketOffer_Cannot_Be_Made_While_In_Auction();
    }

    DataTypes.Offer storage offer = nftContractToIdToOffer[derivativeNFT][tokenId];

    if (offer.expiration < block.timestamp) {
      // This is a new offer for the DNFT (no other offer found or the previous offer expired)
      // Lock the offer amount in SBT until the offer expires in 24-25 hours.
      expiration = treasury.marketLockupFor(buyer, soulBoundTokenIdBuyer, units * amount);

    } else {
      // A previous offer exists and has not expired

      uint256 minIncrement = _getMinIncrement(offer.amount);
      if (amount < minIncrement) {
        // A non-trivial increase in price is required to avoid sniping
        revert Errors.DNFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(minIncrement);
      }

      // Unlock the previous offer so that the earnest money are available for other offers or to transfer / withdraw
      // and lock the new offer amounts in treasury until the offer expires in 24-25 hours.
      
      expiration = treasury.marketChangeLockup(
        offer.soulBoundTokenIdBuyer, // unlock previous offer
        offer.expiration,
        offer.units * offer.amount,
        soulBoundTokenIdBuyer, // current offer's SBT id
        units * amount
      );
    }

    // Record offer details
    offer.buyer = msg.sender;
    offer.soulBoundTokenIdBuyer = soulBoundTokenIdBuyer;
    // The SBT contract guarantees that the expiration fits into 32 bits.
    offer.expiration = uint32(expiration);
    offer.amount = uint96(amount);
    offer.units = uint128(units);
    offer.soulBoundTokenIdReferrer = soulBoundTokenIdReferrer;

    emit Events.OfferMade(derivativeNFT, tokenId, msg.sender, units * amount, expiration);
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
    uint256 tokenId, 
    uint128 units
    ) private returns(uint256 newTokenId){
    DataTypes.Offer memory offer = nftContractToIdToOffer[derivativeNFT][tokenId];

    // Remove offer when units is all buy.
    if (offer.units == units)
      delete nftContractToIdToOffer[derivativeNFT][tokenId];
   
    // Withdraw earnest money from the buyer's account in the BankTreasury contract.
    treasury.marketWithdrawLocked(offer.buyer, offer.soulBoundTokenIdBuyer, msg.sender, soulBoundTokenIdOwner, offer.expiration, offer.amount);

    uint256 publishId = IDerivativeNFT(derivativeNFT).getPublishIdByTokenId(tokenId);
  
    // Transfer the DNFT to the buyer.
    uint256 newTokenIdBuyer = IDerivativeNFT(derivativeNFT).split(
            publishId, 
            tokenId, 
            msg.sender,
            units
    );

    uint256 projectId = manager.getProjectIdByContract(derivativeNFT);
    if (projectId == 0) 
        revert Errors.InvalidParameter();

    // Distribute revenue for this sale leveraging the SBT Value received from the SBT contract in the line above.
    DataTypes.CollectFeeUsers memory collectFeeUsers =  DataTypes.CollectFeeUsers({
            ownershipSoulBoundTokenId: soulBoundTokenIdOwner,
            collectorSoulBoundTokenId: offer.soulBoundTokenIdBuyer,
            genesisSoulBoundTokenId: 0,
            previousSoulBoundTokenId: 0,
            referrerSoulBoundTokenId: offer.soulBoundTokenIdReferrer
    });

    DataTypes.RoyaltyAmounts memory royaltyAmounts = _distributeFunds(
      collectFeeUsers,
      projectId,
      derivativeNFT,
      newTokenIdBuyer,
      units * offer.amount
    );

    emit Events.OfferAccepted(
      derivativeNFT, 
      newTokenIdBuyer, 
      offer.buyer, 
      msg.sender, 
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
    DataTypes.SaleParam memory saleParam
  ) internal override returns (uint256, uint128) {
    DataTypes.Offer storage offer = nftContractToIdToOffer[saleParam.derivativeNFT][saleParam.tokenId];
    if (offer.expiration < block.timestamp || offer.amount < saleParam.salePrice) {
      // No offer found, the most recent offer is now expired, or the highest offer is below the minimum amount.
      return (0, saleParam.putOnListUnits);
    }
    
    uint128 leftUnits;
    if (offer.units > saleParam.putOnListUnits) {
      leftUnits = saleParam.putOnListUnits - offer.units;
    }
    uint256 newTokenId =  _acceptOffer(saleParam.soulBoundTokenId, saleParam.derivativeNFT, saleParam.tokenId, offer.units);
    return (newTokenId, leftUnits);
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

      // Remove offer?
      delete nftContractToIdToOffer[derivativeNFT][tokenId];

      // Unlock the offer so that the SBT tokens are available for other offers or to transfer / withdraw
      treasury.marketUnlockFor(offer.buyer, offer.soulBoundTokenIdBuyer, offer.expiration, offer.amount);

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
      uint256 amount,
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
  uint256[1_000] private __gap;
}
