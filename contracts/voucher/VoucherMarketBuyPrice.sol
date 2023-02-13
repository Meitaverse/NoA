// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../shared/MarketFees.sol";
import "../shared/FoundationTreasuryNode.sol";
import "../shared/FETHNode.sol";
import "../shared/MarketSharedCore.sol";
import "../shared/SendValueWithFallbackWithdraw.sol";

import "./VoucherMarketCore.sol";

/// @param buyPrice The current buy price set for this Voucher.
error VoucherMarketBuyPrice_Cannot_Buy_At_Lower_Price(uint256 buyPrice);
error VoucherMarketBuyPrice_Cannot_Buy_Unset_Price();
error VoucherMarketBuyPrice_Cannot_Cancel_Unset_Price();
/// @param owner The current owner of this Voucher.
error VoucherMarketBuyPrice_Only_Owner_Can_Cancel_Price(address owner);
/// @param owner The current owner of this Voucher.
error VoucherMarketBuyPrice_Only_Owner_Can_Set_Price(address owner);
error VoucherMarketBuyPrice_Price_Already_Set();
error VoucherMarketBuyPrice_Price_Too_High();
/// @param seller The current owner of this Voucher.
error VoucherMarketBuyPrice_Seller_Mismatch(address seller);

/**
 * @title Allows sellers to set a buy price of their Vouchers that may be accepted and instantly transferred to the buyer.
 * @notice Vouchers with a buy price set are escrowed in the market contract.
 * @author batu-inal & HardlyDifficult
 */
abstract contract VoucherMarketBuyPrice is
   Initializable,
   FoundationTreasuryNode,
   FETHNode,
   MarketSharedCore,
   VoucherMarketCore,
   ReentrancyGuardUpgradeable,
   SendValueWithFallbackWithdraw,
   MarketFees
{
  using AddressUpgradeable for address payable;

  /// @notice Stores the buy price details for a specific Voucher.
  /// @dev The struct is packed into a single slot to optimize gas.
  struct BuyPrice {
    /// @notice The current owner of this Voucher which set a buy price.
    /// @dev A zero price is acceptable so a non-zero address determines whether a price has been set.
    address payable seller;
    /// @notice The current buy price set for this Voucher.
    uint96 price;
  }

  /// @notice Stores the current buy price for each Voucher.
  mapping(address => mapping(uint256 => BuyPrice)) private nftContractToTokenIdToBuyPrice;

  /**
   * @notice Emitted when an Voucher is bought by accepting the buy price,
   * indicating that the Voucher has been transferred and revenue from the sale distributed.
   * @dev The total buy price that was accepted is `totalFees` + `creatorRev` + `sellerRev`.
   * @param voucherNFT The address of the Voucher contract.
   * @param tokenId The id of the Voucher.
   * @param buyer The address of the collector that purchased the Voucher using `buy`.
   * @param seller The address of the seller which originally set the buy price.
   * @param totalFees The amount of ETH that was sent to Foundation & referrals for this sale.
   * @param creatorRev The amount of ETH that was sent to the creator for this sale.
   * @param sellerRev The amount of ETH that was sent to the owner for this sale.
   */
  event VoucherBuyPriceAccepted(
    address indexed voucherNFT,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    uint256 totalFees,
    uint256 creatorRev,
    uint256 sellerRev
  );
  /**
   * @notice Emitted when the buy price is removed by the owner of an Voucher.
   * @dev The Voucher is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * @param voucherNFT The address of the Voucher contract.
   * @param tokenId The id of the Voucher.
   */
  event VoucherBuyPriceCanceled(address indexed voucherNFT, uint256 indexed tokenId);
  /**
   * @notice Emitted when a buy price is invalidated due to other market activity.
   * @dev This occurs when the buy price is no longer eligible to be accepted,
   * e.g. when a bid is placed in an auction for this Voucher.
   * @param voucherNFT The address of the Voucher contract.
   * @param tokenId The id of the Voucher.
   */
  event VoucherBuyPriceInvalidated(address indexed voucherNFT, uint256 indexed tokenId);
  /**
   * @notice Emitted when a buy price is set by the owner of an Voucher.
   * @dev The Voucher is transferred into the market contract for escrow unless it was already escrowed,
   * e.g. for auction listing.
   * @param voucherNFT The address of the Voucher contract.
   * @param tokenId The id of the Voucher.
   * @param seller The address of the Voucher owner which set the buy price.
   * @param price The price of the Voucher.
   */
  event VoucherBuyPriceSet(address indexed voucherNFT, uint256 indexed tokenId, address indexed seller, uint256 price);

  /**
   * @notice Buy the Voucher at the set buy price.
   * `msg.value` must be <= `maxPrice` and any delta will be taken from the account's available FETH balance.
   * @dev `maxPrice` protects the buyer in case a the price is increased but allows the transaction to continue
   * when the price is reduced (and any surplus funds provided are refunded).
   * @param voucherNFT The address of the Voucher contract.
   * @param tokenId The id of the Voucher.
   * @param maxPrice The maximum price to pay for the Voucher.
   * @param referrer The address of the referrer.
   */
  function buy(
    address voucherNFT,
    uint256 tokenId,
    uint256 maxPrice,
    address payable referrer
  ) public payable {
    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[voucherNFT][tokenId];
    if (buyPrice.price > maxPrice) {
      revert VoucherMarketBuyPrice_Cannot_Buy_At_Lower_Price(buyPrice.price);
    } else if (buyPrice.seller == address(0)) {
      revert VoucherMarketBuyPrice_Cannot_Buy_Unset_Price();
    }
    
    _buy(voucherNFT, tokenId, referrer);
  }

  /**
   * @notice Removes the buy price set for an Voucher.
   * @dev The Voucher is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * @param voucherNFT The address of the Voucher contract.
   * @param tokenId The id of the Voucher.
   */
  function cancelBuyPrice(address voucherNFT, uint256 tokenId) external nonReentrant {
    address seller = nftContractToTokenIdToBuyPrice[voucherNFT][tokenId].seller;
    if (seller == address(0)) {
      // This check is redundant with the next one, but done in order to provide a more clear error message.
      revert VoucherMarketBuyPrice_Cannot_Cancel_Unset_Price();
    } else if (seller != msg.sender) {
      revert VoucherMarketBuyPrice_Only_Owner_Can_Cancel_Price(seller);
    }

    // Remove the buy price
    delete nftContractToTokenIdToBuyPrice[voucherNFT][tokenId];

    // Transfer the Voucher back to the owner if it is not listed in auction.
    _transferFromEscrowIfAvailable(voucherNFT, tokenId, msg.sender);

    emit VoucherBuyPriceCanceled(voucherNFT, tokenId);
  }

  /**
   * @notice Sets the buy price for an Voucher and escrows it in the market contract.
   * A 0 price is acceptable and valid price you can set, enabling a giveaway to the first collector that calls `buy`.
   * @dev If there is an offer for this amount or higher, that will be accepted instead of setting a buy price.
   * @param voucherNFT The address of the Voucher contract.
   * @param tokenId The id of the Voucher.
   * @param price The price at which someone could buy this Voucher.
   */
  function setBuyPrice(
    address voucherNFT,
    uint256 tokenId,
    uint256 price
  ) external nonReentrant {
    // If there is a valid offer at this price or higher, accept that instead.
    if (_autoAcceptOffer(voucherNFT, tokenId, price)) {
      return;
    }

    if (price > type(uint96).max) {
      // This ensures that no data is lost when storing the price as `uint96`.
      revert VoucherMarketBuyPrice_Price_Too_High();
    }

    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[voucherNFT][tokenId];
    address seller = buyPrice.seller;

    if (buyPrice.price == price && seller != address(0)) {
      revert VoucherMarketBuyPrice_Price_Already_Set();
    }

    // Store the new price for this Voucher.
    buyPrice.price = uint96(price);

    if (seller == address(0)) {
      // Transfer the Voucher into escrow, if it's already in escrow confirm the `msg.sender` is the owner.
      _transferToEscrow(voucherNFT, tokenId);

      // The price was not previously set for this Voucher, store the seller.
      buyPrice.seller = payable(msg.sender);
    } else if (seller != msg.sender) {
      // Buy price was previously set by a different user
      revert VoucherMarketBuyPrice_Only_Owner_Can_Set_Price(seller);
    }

    emit VoucherBuyPriceSet(voucherNFT, tokenId, msg.sender, price);
  }

  /**
   * @notice If there is a buy price at this price or lower, accept that and return true.
   */
  function _autoAcceptBuyPrice(
    address voucherNFT,
    uint256 tokenId,
    uint256 maxPrice
  ) internal override returns (bool) {
    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[voucherNFT][tokenId];
    if (buyPrice.seller == address(0) || buyPrice.price > maxPrice) {
      // No buy price was found, or the price is too high.
      return false;
    }

    _buy(voucherNFT, tokenId, payable(0));
    return true;
  }


  /**
   * @notice Process the purchase of an Voucher at the current buy price.
   * @dev The caller must confirm that the seller != address(0) before calling this function.
   */
  function _buy(
    address voucherNFT,
    uint256 tokenId,
    address payable referrer
  ) private nonReentrant {
    BuyPrice memory buyPrice = nftContractToTokenIdToBuyPrice[voucherNFT][tokenId];

    // Remove the buy now price
    delete nftContractToTokenIdToBuyPrice[voucherNFT][tokenId];

    // Cancel the buyer's offer if there is one in order to free up their FETH balance
    // even if they don't need the FETH for this specific purchase.
    _cancelSendersOffer(voucherNFT, tokenId);

    _tryUseFETHBalance(buyPrice.price, true);

    // Transfer the Voucher to the buyer.
    // The seller was already authorized when the buyPrice was set originally set.
    _transferFromEscrow(voucherNFT, tokenId, msg.sender, address(0));

    // Distribute revenue for this sale.
    (uint256 totalFees, uint256 creatorRev, uint256 sellerRev) = _distributeFunds(
      voucherNFT,
      tokenId,
      buyPrice.seller,
      buyPrice.price,
      referrer
    );

    emit VoucherBuyPriceAccepted(voucherNFT, tokenId, buyPrice.seller, msg.sender, totalFees, creatorRev, sellerRev);
  }

  /**
   * @notice Clear a buy price and emit BuyPriceInvalidated.
   * @dev The caller must confirm the buy price is set before calling this function.
   */
  function _invalidateBuyPrice(address voucherNFT, uint256 tokenId) private {
    delete nftContractToTokenIdToBuyPrice[voucherNFT][tokenId];
    emit VoucherBuyPriceInvalidated(voucherNFT, tokenId);
  }

  /**
   * @inheritdoc VoucherMarketCore
   * @dev Invalidates the buy price if one is found before transferring the Voucher.
   * This will revert if there is a buy price set but the `authorizeSeller` is not the owner.
   */
  function _transferFromEscrow(
    address voucherNFT,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[voucherNFT][tokenId].seller;
    if (seller != address(0)) {
      // A buy price was set for this Voucher.
      // `authorizeSeller != address(0) &&` could be added when other mixins use this flow.
      // ATM that additional check would never return false.
      if (seller != authorizeSeller) {
        // When there is a buy price set, the `buyPrice.seller` is the owner of the Voucher.
        revert VoucherMarketBuyPrice_Seller_Mismatch(seller);
      }
      // The seller authorization has been confirmed.
      authorizeSeller = address(0);

      // Invalidate the buy price as the Voucher will no longer be in escrow.
      _invalidateBuyPrice(voucherNFT, tokenId);
    }

    super._transferFromEscrow(voucherNFT, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc VoucherMarketCore
   * @dev Checks if there is a buy price set, if not then allow the transfer to proceed.
   */
  function _transferFromEscrowIfAvailable(
    address voucherNFT,
    uint256 tokenId,
    address recipient
  ) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[voucherNFT][tokenId].seller;
    if (seller == address(0)) {
      // A buy price has been set for this Voucher so it should remain in escrow.
      super._transferFromEscrowIfAvailable(voucherNFT, tokenId, recipient);
    }
  }
  
  /**
   * @inheritdoc VoucherMarketCore
   * @dev Checks if the Voucher is already in escrow for buy now.
   */
  function _transferToEscrow(address voucherNFT, uint256 tokenId) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[voucherNFT][tokenId].seller;
    if (seller == address(0)) {
      // The Voucher is not in escrow for buy now.
      super._transferToEscrow(voucherNFT, tokenId);
    } else if (seller != msg.sender) {
      // When there is a buy price set, the `seller` is the owner of the Voucher.
      revert VoucherMarketBuyPrice_Seller_Mismatch(seller);
    }
  }

  /**
   * @notice Returns the buy price details for an Voucher if one is available.
   * @dev If no price is found, seller will be address(0) and price will be max uint256.
   * @param voucherNFT The address of the Voucher contract.
   * @param tokenId The id of the Voucher.
   * @return seller The address of the owner that listed a buy price for this Voucher.
   * Returns `address(0)` if there is no buy price set for this Voucher.
   * @return price The price of the Voucher.
   * Returns max uint256 if there is no buy price set for this Voucher (since a price of 0 is supported).
   */
  function getBuyPrice(address voucherNFT, uint256 tokenId) external view returns (address seller, uint256 price) {
    seller = nftContractToTokenIdToBuyPrice[voucherNFT][tokenId].seller;
    if (seller == address(0)) {
      return (seller, type(uint256).max);
    }
    price = nftContractToTokenIdToBuyPrice[voucherNFT][tokenId].price;
  }

  /**
   * @inheritdoc MarketSharedCore
   * @dev Returns the seller if there is a buy price set for this Voucher, otherwise
   * bubbles the call up for other considerations.
   */
  function _getSellerOf(address voucherNFT, uint256 tokenId)
    internal
    view
    virtual
    override(MarketSharedCore, VoucherMarketCore)
    returns (address payable seller)
  {
    seller = nftContractToTokenIdToBuyPrice[voucherNFT][tokenId].seller;
    if (seller == address(0)) {
      seller = super._getSellerOf(voucherNFT, tokenId);
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;
}
