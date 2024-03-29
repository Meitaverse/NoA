// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../shared/MarketFees.sol";
import "../shared/FoundationTreasuryNode.sol";
import "../shared/FETHNode.sol";
import "../shared/SendValueWithFallbackWithdraw.sol";

import "./VoucherMarketCore.sol";

error NFTMarketOffer_Cannot_Be_Made_While_In_Auction();
/// @param currentOfferAmount The current highest offer available for this dNFT.
error NFTMarketOffer_Offer_Below_Min_Amount(uint256 currentOfferAmount);
/// @param expiry The time at which the offer had expired.
error NFTMarketOffer_Offer_Expired(uint256 expiry);
/// @param currentOfferFrom The address of the collector which has made the current highest offer.
error NFTMarketOffer_Offer_From_Does_Not_Match(address currentOfferFrom);
/// @param minOfferAmount The minimum amount that must be offered in order for it to be accepted.
error NFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(uint256 minOfferAmount);

/**
 * @title Allows collectors to make an offer for an dNFT, valid for 24-25 hours.
 * @notice Funds are escrowed in the FETH ERC-20 token contract.
 * @author batu-inal & HardlyDifficult
 */
abstract contract VoucherMarketOffer is
  Initializable,
  FoundationTreasuryNode,
  FETHNode,
  VoucherMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  MarketFees
{
  using AddressUpgradeable for address;

  /// @notice Stores offer details for a specific dNFT.
  struct Offer {
    // Slot 1: When increasing an offer, only this slot is updated.
    /// @notice The expiration timestamp of when this offer expires.
    uint32 expiration;
    /// @notice The amount, in wei, of the highest offer.
    uint96 amount;
    /// @notice First slot (of 16B) used for the offerReferrerAddress.
    // The offerReferrerAddress is the address used to pay the
    // referrer on an accepted offer.
    uint128 offerReferrerAddressSlot0;
    // Slot 2: When the buyer changes, both slots need updating
    /// @notice The address of the collector who made this offer.
    address buyer;
    /// @notice Second slot (of 4B) used for the offerReferrerAddress.
    uint32 offerReferrerAddressSlot1;
    // 96 bits (12B) are available in slot 1.
  }

  /// @notice Stores the highest offer for each dNFT.
  mapping(address => mapping(uint256 => Offer)) private nftContractToIdToOffer;

  /**
   * @notice Emitted when an offer is accepted,
   * indicating that the dNFT has been transferred and revenue from the sale distributed.
   * @dev The accepted total offer amount is `totalFees` + `creatorRev` + `sellerRev`.
   * @param voucherNFT The address of the dNFT contract.
   * @param tokenId The id of the dNFT.
   * @param buyer The address of the collector that made the offer which was accepted.
   * @param seller The address of the seller which accepted the offer.
   * @param totalFees The amount of ETH that was sent to Foundation & referrals for this sale.
   * @param creatorRev The amount of ETH that was sent to the creator for this sale.
   * @param sellerRev The amount of ETH that was sent to the owner for this sale.
   */
  event VoucherOfferAccepted(
    address indexed voucherNFT,
    uint256 indexed tokenId,
    address indexed buyer,
    address seller,
    uint256 totalFees,
    uint256 creatorRev,
    uint256 sellerRev
  );
  /**
   * @notice Emitted when an offer is invalidated due to other market activity.
   * When this occurs, the collector which made the offer has their FETH balance unlocked
   * and the funds are available to place other offers or to be withdrawn.
   * @dev This occurs when the offer is no longer eligible to be accepted,
   * e.g. when a bid is placed in an auction for this dNFT.
   * @param voucherNFT The address of the dNFT contract.
   * @param tokenId The id of the dNFT.
   */
  event VoucherOfferInvalidated(address indexed voucherNFT, uint256 indexed tokenId);
  /**
   * @notice Emitted when an offer is made.
   * @dev The `amount` of the offer is locked in the FETH ERC-20 contract, guaranteeing that the funds
   * remain available until the `expiration` date.
   * @param voucherNFT The address of the dNFT contract.
   * @param tokenId The id of the dNFT.
   * @param buyer The address of the collector that made the offer to buy this dNFT.
   * @param amount The amount, in wei, of the offer.
   * @param expiration The expiration timestamp for the offer.
   */
  event VoucherOfferMade(
    address indexed voucherNFT,
    uint256 indexed tokenId,
    address indexed buyer,
    uint256 amount,
    uint256 expiration
  );

  /**
   * @notice Accept the highest offer for an dNFT.
   * @dev The offer must not be expired and the dNFT owned + approved by the seller or
   * available in the market contract's escrow.
   * @param voucherNFT The address of the dNFT contract.
   * @param tokenId The id of the dNFT.
   * @param offerFrom The address of the collector that you wish to sell to.
   * If the current highest offer is not from this user, the transaction will revert.
   * This could happen if a last minute offer was made by another collector,
   * and would require the seller to try accepting again.
   * @param minAmount The minimum value of the highest offer for it to be accepted.
   * If the value is less than this amount, the transaction will revert.
   * This could happen if the original offer expires and is replaced with a smaller offer.
   */
  function acceptOffer(
    address voucherNFT,
    uint256 tokenId,
    address offerFrom,
    uint256 minAmount
  ) external nonReentrant {
    Offer storage offer = nftContractToIdToOffer[voucherNFT][tokenId];
    // Validate offer expiry and amount
    if (offer.expiration < block.timestamp) {
      revert NFTMarketOffer_Offer_Expired(offer.expiration);
    } else if (offer.amount < minAmount) {
      revert NFTMarketOffer_Offer_Below_Min_Amount(offer.amount);
    }
    // Validate the buyer
    if (offer.buyer != offerFrom) {
      revert NFTMarketOffer_Offer_From_Does_Not_Match(offer.buyer);
    }
    _acceptOffer(voucherNFT, tokenId);
  }

  /**
   * @notice Make an offer for any dNFT which is valid for 24-25 hours.
   * The funds will be locked in the FETH token contract and become available once the offer is outbid or has expired.
   * @dev An offer may be made for an dNFT before it is minted, although we generally not recommend you do that.
   * If there is a buy price set at this price or lower, that will be accepted instead of making an offer.
   * `msg.value` must be <= `amount` and any delta will be taken from the account's available FETH balance.
   * @param voucherNFT The address of the dNFT contract.
   * @param tokenId The id of the dNFT.
   * @param amount The amount to offer for this dNFT.
   * @param referrer The refrerrer address for the offer.
   * @return expiration The timestamp for when this offer will expire.
   * This is provided as a return value in case another contract would like to leverage this information,
   * user's should refer to the expiration in the `OfferMade` event log.
   * If the buy price is accepted instead, `0` is returned as the expiration since that's n/a.
   */
  function makeOffer(
    address voucherNFT,
    uint256 tokenId,
    uint256 amount,
    address payable referrer
  ) external payable returns (uint256 expiration) {
    // If there is a buy price set at this price or lower, accept that instead.
    if (_autoAcceptBuyPrice(voucherNFT, tokenId, amount)) {
      // If the buy price is accepted, `0` is returned as the expiration since that's n/a.
      return 0;
    }

    //TODO
    // if (_isInActiveAuction(voucherNFT, tokenId)) {
    //   revert NFTMarketOffer_Cannot_Be_Made_While_In_Auction();
    // }

    Offer storage offer = nftContractToIdToOffer[voucherNFT][tokenId];

    if (offer.expiration < block.timestamp) {
      // This is a new offer for the dNFT (no other offer found or the previous offer expired)

      // Lock the offer amount in FETH until the offer expires in 24-25 hours.
      expiration = feth.marketLockupFor{ value: msg.value }(msg.sender, amount);
    } else {
      // A previous offer exists and has not expired

      uint256 minIncrement = _getMinIncrement(offer.amount);
      if (amount < minIncrement) {
        // A non-trivial increase in price is required to avoid sniping
        revert NFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(minIncrement);
      }

      // Unlock the previous offer so that the FETH tokens are available for other offers or to transfer / withdraw
      // and lock the new offer amount in FETH until the offer expires in 24-25 hours.
      expiration = feth.marketChangeLockup{ value: msg.value }(
        offer.buyer,
        offer.expiration,
        offer.amount,
        msg.sender,
        amount
      );
    }

    // Record offer details
    offer.buyer = msg.sender;
    // The FETH contract guarantees that the expiration fits into 32 bits.
    offer.expiration = uint32(expiration);
    // `amount` is capped by the ETH provided, which cannot realistically overflow 96 bits.
    offer.amount = uint96(amount);
    // Set offerReferrerAddressSlot0 to the first 16B of the referrer address.
    // By shifting the referrer 32 bits to the right we obtain the first 16B.
    offer.offerReferrerAddressSlot0 = uint128(uint160(address(referrer)) >> 32);
    // Set offerReferrerAddressSlot1 to the last 4B of the referrer address.
    // By casting the referrer address to 32bits we discard the first 16B.
    offer.offerReferrerAddressSlot1 = uint32(uint160(address(referrer)));

    emit VoucherOfferMade(voucherNFT, tokenId, msg.sender, amount, expiration);
  }

  /**
   * @notice Accept the highest offer for an dNFT from the `msg.sender` account.
   * The dNFT will be transferred to the buyer and revenue from the sale will be distributed.
   * @dev The caller must validate the expiry and amount before calling this helper.
   * This may invalidate other market tools, such as clearing the buy price if set.
   */
  function _acceptOffer(address voucherNFT, uint256 tokenId) private {
    Offer memory offer = nftContractToIdToOffer[voucherNFT][tokenId];

    // Remove offer
    delete nftContractToIdToOffer[voucherNFT][tokenId];
    // Withdraw ETH from the buyer's account in the FETH token contract.
    feth.marketWithdrawLocked(offer.buyer, offer.expiration, offer.amount);
      
    uint256 amountOfToken = IERC1155Upgradeable(voucherNFT).balanceOf(msg.sender, tokenId);

    // Transfer the dNFT to the buyer.
    try
      IERC1155Upgradeable(voucherNFT).safeTransferFrom(msg.sender, offer.buyer, tokenId, amountOfToken, bytes('0')) // solhint-disable-next-line no-empty-blocks
    {
      // dNFT was in the seller's wallet so the transfer is complete.
    } catch {
      // If the transfer fails then attempt to transfer from escrow instead.
      // This should revert if `msg.sender` is not the owner of this dNFT.
      _transferFromEscrow(voucherNFT, tokenId, offer.buyer, msg.sender);
    }

    // Distribute revenue for this sale leveraging the ETH received from the FETH contract in the line above.
    (uint256 totalFees, uint256 creatorRev, uint256 sellerRev) = _distributeFunds(
      voucherNFT,
      tokenId,
      payable(msg.sender),
      offer.amount,
      _getOfferReferrerFromSlots(offer.offerReferrerAddressSlot0, offer.offerReferrerAddressSlot1)
    );

    emit VoucherOfferAccepted(voucherNFT, tokenId, offer.buyer, msg.sender, totalFees, creatorRev, sellerRev);
  }

  /**
   * @inheritdoc VoucherMarketCore
   * @dev Invalidates the highest offer when an auction is kicked off, if one is found.
   */
  // function _beforeAuctionStarted(address voucherNFT, uint256 tokenId) internal virtual override {
  //   _invalidateOffer(voucherNFT, tokenId);
  //   super._beforeAuctionStarted(voucherNFT, tokenId);
  // }

  /**
   * @inheritdoc VoucherMarketCore
   */
  function _autoAcceptOffer(
    address voucherNFT,
    uint256 tokenId,
    uint256 minAmount
  ) internal override returns (bool) {
    Offer storage offer = nftContractToIdToOffer[voucherNFT][tokenId];
    if (offer.expiration < block.timestamp || offer.amount < minAmount) {
      // No offer found, the most recent offer is now expired, or the highest offer is below the minimum amount.
      return false;
    }

    _acceptOffer(voucherNFT, tokenId);
    return true;
  }

  /**
   * @inheritdoc VoucherMarketCore
   */
  function _cancelSendersOffer(address voucherNFT, uint256 tokenId) internal override {
    Offer storage offer = nftContractToIdToOffer[voucherNFT][tokenId];
    if (offer.buyer == msg.sender) {
      _invalidateOffer(voucherNFT, tokenId);
    }
  }

  /**
   * @notice Invalidates the offer and frees ETH from escrow, if the offer has not already expired.
   * @dev Offers are not invalidated when the dNFT is purchased by accepting the buy price unless it
   * was purchased by the same user.
   * The user which just purchased the dNFT may have buyer's remorse and promptly decide they want a fast exit,
   * accepting a small loss to limit their exposure.
   */
  function _invalidateOffer(address voucherNFT, uint256 tokenId) private {
    if (nftContractToIdToOffer[voucherNFT][tokenId].expiration >= block.timestamp) {
      // An offer was found and it has not already expired
      Offer memory offer = nftContractToIdToOffer[voucherNFT][tokenId];

      // Remove offer
      delete nftContractToIdToOffer[voucherNFT][tokenId];

      // Unlock the offer so that the FETH tokens are available for other offers or to transfer / withdraw
      feth.marketUnlockFor(offer.buyer, offer.expiration, offer.amount);

      emit VoucherOfferInvalidated(voucherNFT, tokenId);
    }
  }

  /**
   * @notice Returns the minimum amount a collector must offer for this dNFT in order for the offer to be valid.
   * @dev Offers for this dNFT which are less than this value will revert.
   * Once the previous offer has expired smaller offers can be made.
   * @param voucherNFT The address of the dNFT contract.
   * @param tokenId The id of the dNFT.
   * @return minimum The minimum amount that must be offered for this dNFT.
   */
  function getMinOfferAmount(address voucherNFT, uint256 tokenId) external view returns (uint256 minimum) {
    Offer storage offer = nftContractToIdToOffer[voucherNFT][tokenId];
    if (offer.expiration >= block.timestamp) {
      return _getMinIncrement(offer.amount);
    }
    // Absolute min is anything > 0
    return 1;
  }

  /**
   * @notice Returns details about the current highest offer for an dNFT.
   * @dev Default values are returned if there is no offer or the offer has expired.
   * @param voucherNFT The address of the dNFT contract.
   * @param tokenId The id of the dNFT.
   * @return buyer The address of the buyer that made the current highest offer.
   * Returns `address(0)` if there is no offer or the most recent offer has expired.
   * @return expiration The timestamp that the current highest offer expires.
   * Returns `0` if there is no offer or the most recent offer has expired.
   * @return amount The amount being offered for this dNFT.
   * Returns `0` if there is no offer or the most recent offer has expired.
   */
  function getOffer(address voucherNFT, uint256 tokenId)
    external
    view
    returns (
      address buyer,
      uint256 expiration,
      uint256 amount
    )
  {
    Offer storage offer = nftContractToIdToOffer[voucherNFT][tokenId];
    if (offer.expiration < block.timestamp) {
      // Offer not found or has expired
      return (address(0), 0, 0);
    }

    // An offer was found and it has not yet expired.
    return (offer.buyer, offer.expiration, offer.amount);
  }

  /**
   * @notice Returns the current highest offer's referral for an dNFT.
   * @dev Default value of `payable(0)` is returned if
   * there is no offer, the offer has expired or does not have a referral.
   * @param voucherNFT The address of the dNFT contract.
   * @param tokenId The id of the dNFT.
   * @return referrer The payable address of the referrer for the offer.
   */
  function getOfferReferrer(address voucherNFT, uint256 tokenId) external view returns (address payable referrer) {
    Offer storage offer = nftContractToIdToOffer[voucherNFT][tokenId];
    if (offer.expiration < block.timestamp) {
      // Offer not found or has expired
      return payable(0);
    }
    return _getOfferReferrerFromSlots(offer.offerReferrerAddressSlot0, offer.offerReferrerAddressSlot1);
  }

  function _getOfferReferrerFromSlots(uint128 offerReferrerAddressSlot0, uint32 offerReferrerAddressSlot1)
    private
    pure
    returns (address payable referrer)
  {
    // Stitch offerReferrerAddressSlot0 and offerReferrerAddressSlot1 to obtain the payable offerReferrerAddress.
    // Left shift offerReferrerAddressSlot0 by 32 bits OR it with offerReferrerAddressSlot1.
    referrer = payable(address((uint160(offerReferrerAddressSlot0) << 32) | uint160(offerReferrerAddressSlot1)));
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1_000] private __gap;
}
