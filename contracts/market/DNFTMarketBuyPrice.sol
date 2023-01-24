// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../libraries/SafeMathUpgradeable128.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Events} from "../libraries/Events.sol";
import {Errors} from "../libraries/Errors.sol";
import {IModuleGlobals} from "../interfaces/IModuleGlobals.sol";
import {IManager} from "../interfaces/IManager.sol";
import "./MarketSharedCore.sol";
import "./DNFTMarketCore.sol";
import {MarketFees} from "./MarketFees.sol";
/**
 * @title Allows sellers to set a buy price of their DNFTs that may be accepted and instantly transferred to the buyer.
 * @notice DNFTs with a buy price set are escrowed in the market contract.
 * @author batu-inal & HardlyDifficult
 */
abstract contract DNFTMarketBuyPrice is
  Initializable,
  MarketSharedCore,
  DNFTMarketCore,
  MarketFees
{
  using AddressUpgradeable for address payable;
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;
  using SafeMathUpgradeable128 for uint128;

  /// @notice Stores the current buy price for each DNFT.
  mapping(address => mapping(uint256 => DataTypes.BuyPrice)) internal dnftContractToTokenIdToBuyPrice;

  /**
   * @notice Buy the DNFT at the set buy price.
   * `msg.value` must be <= `maxPrice` and any delta will be taken from the account's available FETH balance.
   * @dev `maxPrice` protects the buyer in case a the price is increased but allows the transaction to continue
   * when the price is reduced (and any surplus funds provided are refunded).
   * @param soulBoundTokenIdBuyer The SBT id of buyer.
   * @param derivativeNFT The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   * @param maxPrice The maximum price to pay for the DNFT.
   * @param soulBoundTokenIdReferrer The SBT id of the referrer.
   */
  function buy(
    uint256 soulBoundTokenIdBuyer,
    address derivativeNFT,
    uint256 tokenId,
    uint128 units,
    uint256 maxPrice,
    uint256 soulBoundTokenIdReferrer
  ) public payable {
    DataTypes.BuyPrice storage buyPrice = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];
    if (buyPrice.salePrice > maxPrice) {
      revert Errors.DNFTMarketBuyPrice_Cannot_Buy_At_Lower_Price(buyPrice.salePrice);
    } else if (buyPrice.seller == address(0)) {
      revert Errors.DNFTMarketBuyPrice_Cannot_Buy_Unset_Price();
    }

    if (soulBoundTokenIdBuyer == 0) revert Errors.Unauthorized();

    _buy(soulBoundTokenIdBuyer, derivativeNFT, tokenId, units, soulBoundTokenIdReferrer);
  }

  /**
   * @notice Removes the buy price set for an DNFT.
   * @dev The DNFT is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * 
   * @param derivativeNFT The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   * @param units The units of the DNFT.
   */
  function cancelBuyPrice(address derivativeNFT, uint256 tokenId, uint128 units) external  { 
    uint256 tokenIdEscrow = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId].tokenIdEscrow;
    address seller = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId].seller;
    if (seller == address(0)) {
      // This check is redundant with the next one, but done in order to provide a more clear error message.
      revert Errors.DNFTMarketBuyPrice_Cannot_Cancel_Unset_Price();
    } else if (seller != msg.sender) {
      revert Errors.DNFTMarketBuyPrice_Only_Owner_Can_Cancel_Price(seller);
    }

    // Remove the buy price
    delete dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];

    // Transfer the DNFT units back to the owner if it is not listed in auction.
    _transferFromEscrowIfAvailable(derivativeNFT, tokenIdEscrow, tokenId, units);

    emit Events.BuyPriceCanceled(derivativeNFT, tokenId);
  }

  /**
   * @notice Sets the buy price for an DNFT and escrows it in the market contract.
   * A 0 price is acceptable and valid price you can set, enabling a giveaway to the first collector that calls `buy`.
   * @dev If there is an offer for this amount or higher, that will be accepted instead of setting a buy price.
   * @param saleParam The sale param to set buy price
   *       
   */
  function setBuyPrice(
    DataTypes.SaleParam memory saleParam
  ) external returns(uint256 newTokenId) { 
    if (saleParam.max > 0) {
        if (saleParam.min > saleParam.max) revert Errors.MinGTMax();
    }

    if (saleParam.derivativeNFT == address(0)) 
        revert Errors.InvalidParameter();

    if (!saleParam.derivativeNFT.isContract()) {
      revert Errors.DerivativeNFT_Must_Be_A_Contract();
    }          
        
    uint128 total = uint128(IERC3525(saleParam.derivativeNFT).balanceOf(saleParam.tokenId));
    if(total > type(uint128).max) revert Errors.ExceedsUint128Max();
    if(total == 0) revert Errors.TotalIsZero();
    if(saleParam.max > total) revert Errors.MaxGTTotal(); 
    if(saleParam.onSellUnits > total) revert Errors.UnitsGTTotal(); 

    // validate martket is open for this contract?
    if (!_getMarketInfo(saleParam.derivativeNFT).isOpen)
        revert Errors.UnsupportedDerivativeNFT();
        
    address _manager = _getManager() ;
    uint256 projectId = IManager(_manager).getProjectIdByContract(msg.sender);
    if (projectId == 0) 
        revert Errors.InvalidParameter();

    uint256 publishId = IDerivativeNFTV1(saleParam.derivativeNFT).getPublishIdByTokenId(saleParam.tokenId);

    //save to  
    DataTypes.BuyPrice storage buyPrice = dnftContractToTokenIdToBuyPrice[saleParam.derivativeNFT][saleParam.tokenId];
    address seller = buyPrice.seller;

    if (buyPrice.salePrice == saleParam.salePrice && seller != address(0)) {
      revert Errors.DNFTMarketBuyPrice_Price_Already_Set();
    }
    if (buyPrice.salePrice > type(uint96).max) {
      // This ensures that no data is lost when storing the price as `uint96`.
      revert Errors.DNFTMarketBuyPrice_Price_Too_High();
    }

    buyPrice.projectId = projectId;    
    buyPrice.publishId = publishId;    
    buyPrice.min = saleParam.min;    
    buyPrice.max = saleParam.max;    

    uint128 units;
    // If there is a valid offer at this salePrice or higher, accept that instead.
    (newTokenId, units) = _autoAcceptOffer(saleParam);

    // offer is done
    if (newTokenId > 0 && units == saleParam.onSellUnits) {
        return newTokenId;
    } 

    buyPrice.onSellUnits = saleParam.onSellUnits - units;

    // Store the new salePrice for this DNFT.
    buyPrice.salePrice = uint96(saleParam.salePrice);

    if (seller == address(0)) {
      // Transfer the DNFT into escrow, if it's already in escrow confirm the `msg.sender` is the owner.
      //must approve manager before
      uint256 tokenIdEscrow = _transferToEscrow(saleParam.derivativeNFT, saleParam.tokenId, buyPrice.onSellUnits);

      buyPrice.tokenIdEscrow = tokenIdEscrow;

      // The salePrice was not previously set for this DNFT, store the seller.
      buyPrice.seller = payable(msg.sender);

    } else if (seller != msg.sender) {
      // Buy price was previously set by a different user
      revert Errors.DNFTMarketBuyPrice_Only_Owner_Can_Set_Price(seller);
    }

    emit Events.BuyPriceSet(saleParam.derivativeNFT, saleParam.tokenId, msg.sender, saleParam.salePrice);

    return newTokenId;
  }

  /**
   * @notice If there is a buy price at this price or lower, accept that and return true.
   */
  function _autoAcceptBuyPrice(
    uint256 soulBoundTokenIdBuyer, 
    address derivativeNFT,
    uint256 tokenId,
    uint128 units,
    uint256 maxPrice
  ) internal override returns (bool) {
    DataTypes.BuyPrice storage buyPrice = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];
    if (buyPrice.seller == address(0) || buyPrice.salePrice > maxPrice) {
      // No buy price was found, or the price is too high.
      return false;
    }

    _buy(soulBoundTokenIdBuyer, derivativeNFT, tokenId, units, 0);
    return true;
  }
  
  /**
   * @inheritdoc DNFTMarketCore
   * @dev Invalidates the buy price on a auction start, if one is found.
   */
  function _beforeAuctionStarted(address derivativeNFT, uint256 tokenId) internal virtual override(DNFTMarketCore) {
    DataTypes.BuyPrice storage buyPrice = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];
    if (buyPrice.seller != address(0)) {
      // A buy price was set for this DNFT, invalidate it.
      _invalidateBuyPrice(derivativeNFT, tokenId);
    }
    super._beforeAuctionStarted(derivativeNFT, tokenId);
  }

  /**
   * @notice Process the purchase of an DNFT at the current buy price.
   * @dev The caller must confirm that the seller != address(0) before calling this function.
   */
  function _buy(
    uint256 soulBoundTokenIdBuyer, 
    address derivativeNFT,
    uint256 tokenId,
    uint128 units,
    uint256 soulBoundTokenIdReferrer
  ) private  { 
    DataTypes.BuyPrice memory buyPrice = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];

    if (buyPrice.onSellUnits == units) {
      // Remove the buy now price?
      delete dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];
    }

    // Cancel the buyer's offer if there is one in order to free up their FETH balance
    // even if they don't need the FETH for this specific purchase.
    _cancelSendersOffer(derivativeNFT, tokenId);

    //TODO SBT value
    // _tryUseFETHBalance(buyPrice.price, true);

    // Transfer the DNFT units to the buyer.
    // The seller was already authorized when the buyPrice was set originally set.
    uint256 newTokenIdBuyer = IDerivativeNFTV1(derivativeNFT).split(
            buyPrice.publishId, 
            tokenId, 
            msg.sender,
            units
    );

    // Distribute revenue for this sale.
    DataTypes.CollectFeeUsers memory collectFeeUsers =  DataTypes.CollectFeeUsers({
            ownershipSoulBoundTokenId: 0,
            collectorSoulBoundTokenId: soulBoundTokenIdBuyer,
            genesisSoulBoundTokenId: 0,
            previousSoulBoundTokenId: 0,
            referrerSoulBoundTokenId: soulBoundTokenIdReferrer
    });
    // uint256 payValue = uint256(units).mul(buyPrice.salePrice);
    DataTypes.RoyaltyAmounts memory royaltyAmounts = _distributeFunds(
      collectFeeUsers,
      buyPrice.projectId,
      derivativeNFT,
      tokenId,
      uint256(units).mul(buyPrice.salePrice)
    );
    
    emit Events.BuyPriceAccepted( 
      derivativeNFT,
      tokenId, 
      newTokenIdBuyer,
      buyPrice.seller, 
      msg.sender, 
      soulBoundTokenIdReferrer,
      royaltyAmounts
    );
  }

  /**
   * @notice Clear a buy price and emit BuyPriceInvalidated.
   * @dev The caller must confirm the buy price is set before calling this function.
   */
  function _invalidateBuyPrice(address derivativeNFT, uint256 tokenId) private {
    delete dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];
    emit Events.BuyPriceInvalidated(derivativeNFT, tokenId);
  }

  /**
   * @inheritdoc DNFTMarketCore
   * @dev Checks if there is a buy price set, if not then allow the transfer to proceed.
   */
  function _transferFromEscrowIfAvailable(
    address derivativeNFT,
    uint256 fromTokenId,
    uint256 toTokenId,
    uint128 units
  ) internal virtual override {
    address seller = dnftContractToTokenIdToBuyPrice[derivativeNFT][toTokenId].seller;
    if (seller == address(0)) {
      // A buy price has been set for this DNFT so it should remain in escrow.
      super._transferFromEscrowIfAvailable(derivativeNFT, fromTokenId, toTokenId, units);
    }
  }

  /**
   * @inheritdoc DNFTMarketCore
   * @dev Checks if the DNFT is already in escrow for buy now.
   */
  function _transferToEscrow(address derivativeNFT, uint256 tokenId, uint128 onSellUnits) 
      internal virtual override returns(uint256){
    address seller = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId].seller;
    if (seller == address(0)) {
      // The DNFT is not in escrow for buy now.
      return super._transferToEscrow(derivativeNFT, tokenId, onSellUnits);
    } else if (seller != msg.sender) {
      // When there is a buy price set, the `seller` is the owner of the DNFT.
      revert Errors.DNFTMarketBuyPrice_Seller_Mismatch(seller);
    }
  }

  /**
   * @notice Returns the buy price details for an DNFT if one is available.
   * @dev If no price is found, seller will be address(0) and price will be max uint256.
   * @param derivativeNFT The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   * @return seller The address of the owner that listed a buy price for this DNFT.
   * Returns `address(0)` if there is no buy price set for this DNFT.
   * @return price The price of the DNFT.
   * Returns max uint256 if there is no buy price set for this DNFT (since a price of 0 is supported).
   */
  function getBuyPrice(address derivativeNFT, uint256 tokenId) external view returns (address seller, uint256 price) {
    seller = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId].seller;
    if (seller == address(0)) {
      return (seller, type(uint256).max);
    }
    price = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId].salePrice;
  }

  /**
   * @inheritdoc MarketSharedCore
   * @dev Returns the seller if there is a buy price set for this DNFT, otherwise
   * bubbles the call up for other considerations.
   */
  function _getSellerOf(address derivativeNFT, uint256 tokenId)
    internal
    view
    virtual
    override(MarketSharedCore, DNFTMarketCore)
    returns (address payable seller)
  {
    seller = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId].seller;
    if (seller == address(0)) {
      seller = super._getSellerOf(derivativeNFT, tokenId);
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;
}
