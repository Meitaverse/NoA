// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/internal/IFethMarket.sol";

import "../libraries/Constants.sol";
import "../shared/MarketSharedCore.sol";

error VoucherMarketCore_Seller_Not_Found();

/**
 * @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 * @author batu-inal & HardlyDifficult
 */
abstract contract VoucherMarketCore is Initializable, MarketSharedCore {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;

  // address immutable private voucherContract;

  constructor() {
    // voucherContract = voucherNFT_;
  }

  // function getVoucherContract() internal view virtual returns(address) {
  //   return voucherContract;
  // }

  /**
   * @notice If there is a buy price at this amount or lower, accept that and return true.
   */

  function _autoAcceptBuyPrice(
    address voucherNFT,
    uint256 tokenId,
    uint256 amount
  ) internal virtual returns (bool);

  /**
   * @notice If there is a valid offer at the given price or higher, accept that and return true.
   */

  function _autoAcceptOffer(
    address voucherNFT,
    uint256 tokenId,
    uint256 minAmount
  ) internal virtual returns (bool);

  /**
   * @notice Notify implementors when an auction has received its first bid.
   * Once a bid is received the sale is guaranteed to the auction winner
   * and other sale mechanisms become unavailable.
   * @dev Implementors of this interface should update internal state to reflect an auction has been kicked off.
   */
  // function _beforeAuctionStarted(
  //   address, /*voucherNFT*/
  //   uint256 /*tokenId*/ // solhint-disable-next-line no-empty-blocks
  // ) internal virtual {
  //   // No-op
  // }

  /**
   * @notice Cancel the `msg.sender`'s offer if there is one, freeing up their FETH balance.
   * @dev This should be used when it does not make sense to keep the original offer around,
   * e.g. if a collector accepts a Buy Price then keeping the offer around is not necessary.
   */
  function _cancelSendersOffer(address voucherNFT, uint256 tokenId) internal virtual;

  /**
   * @notice Transfers the dNFT from escrow and clears any state tracking this escrowed dNFT.
   * @param authorizeSeller The address of the seller pending authorization.
   * Once it's been authorized by one of the escrow managers, it should be set to address(0)
   * indicated that it's no longer pending authorization.
   */
  function _transferFromEscrow(
    address voucherNFT,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal virtual {
    if (authorizeSeller != address(0)) {
      revert VoucherMarketCore_Seller_Not_Found();
    }

    uint256 amountOfToken = IERC1155Upgradeable(voucherNFT).balanceOf(address(this), tokenId);
    IERC1155Upgradeable(voucherNFT).safeTransferFrom(address(this), recipient, tokenId, amountOfToken, bytes('0'));
  }

  /**
   * @notice Transfers the dNFT from escrow unless there is another reason for it to remain in escrow.
   */
  function _transferFromEscrowIfAvailable(
    address voucherNFT,
    uint256 tokenId,
    address recipient
  ) internal virtual {
    _transferFromEscrow(voucherNFT, tokenId, recipient, address(0));
  }

  /**
   * @notice Transfers an dNFT into escrow,
   * if already there this requires the msg.sender is authorized to manage the sale of this dNFT.
   */
  function _transferToEscrow(address voucherNFT, uint256 tokenId) internal virtual {

    uint256 amountOfToken = IERC1155Upgradeable(voucherNFT).balanceOf(msg.sender, tokenId);

    IERC1155Upgradeable(voucherNFT).safeTransferFrom(msg.sender, address(this), tokenId, amountOfToken, bytes('0'));
  }

  /**
   * @dev Determines the minimum amount when increasing an existing offer or bid.
   */
  function _getMinIncrement(uint256 currentAmount) internal pure returns (uint256) {
    uint256 minIncrement = currentAmount;
    unchecked {
      minIncrement /= MIN_PERCENT_INCREMENT_DENOMINATOR;
    }
    if (minIncrement == 0) {
      // Since minIncrement reduces from the currentAmount, this cannot overflow.
      // The next amount must be at least 1 wei greater than the current.
      return currentAmount + 1;
    }

    return minIncrement + currentAmount;
  }

  /**
   * @inheritdoc MarketSharedCore
   */
  function _getSellerOf(address voucherNFT, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (address payable seller)
  // solhint-disable-next-line no-empty-blocks
  {
    // No-op by default
  }

  /**
   * @inheritdoc MarketSharedCore
   */
  function _getSellerOrOwnerOf(address voucherNFT, uint256 tokenId)
    internal
    view
    override
    returns (address payable sellerOrOwner)
  {
    sellerOrOwner = _getSellerOf(voucherNFT, tokenId);
    //TODO
    // if (sellerOrOwner == address(0)) {
      // sellerOrOwner = payable(IERC1155Upgradeable(voucherNFT).ownerOf(tokenId));
    // }
  }

  /**
   * @notice Checks if an escrowed dNFT is currently in active auction.
   * @return Returns false if the auction has ended, even if it has not yet been settled.
   */
  // function _isInActiveAuction(address voucherNFT, uint256 tokenId) internal view virtual returns (bool);

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev 50 slots were consumed by adding `ReentrancyGuard`.
   */
  uint256[450] private __gap;
}
