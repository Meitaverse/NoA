// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {Events} from "../libraries/Events.sol";
import {Errors} from "../libraries/Errors.sol";
import {DataTypes} from '../libraries/DataTypes.sol';
import {IDerivativeNFTV1} from "../interfaces/IDerivativeNFTV1.sol";

import "../libraries/Constants.sol";
import "./MarketSharedCore.sol";

error DNFTMarketCore_Seller_Not_Found();

/**
 * @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 * @author batu-inal & HardlyDifficult
 */
abstract contract DNFTMarketCore is Initializable, MarketSharedCore {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;
  
  function _validateCallerIsSoulBoundTokenOwner(uint256 soulBoundTokenId_) internal virtual;

  function _getTreasuryData() internal virtual view returns (address, uint16);

  function _getMarketInfo(address derivativeNFT) internal virtual view returns (DataTypes.Market memory);

  function _validUnitsAndAmount(uint128 units, uint256 amount) internal view virtual {
    if ( units == 0  ||  amount == 0 )
      revert Errors.InvalidParameter();
  }

  /**
   * @notice If there is a buy price at this amount or lower, accept that and return true.
   */
  function _autoAcceptBuyPrice(
    uint256 soulBoundTokenIdBuyer,
    address derivativeNFT,
    uint256 tokenId,
    uint128 units,
    uint256 amount
  ) internal virtual returns (bool);

  /**
   * @notice If there is a valid offer at the given price or higher, accept that and return true.
   */
  
  function _autoAcceptOffer(
    DataTypes.SaleParam memory saleParam
  ) internal virtual returns (uint256, uint128);

  /**
   * @notice Notify implementors when an auction has received its first bid.
   * Once a bid is received the sale is guaranteed to the auction winner
   * and other sale mechanisms become unavailable.
   * @dev Implementors of this interface should update internal state to reflect an auction has been kicked off.
   */
  function _beforeAuctionStarted(
    address, /*derivativeNFT*/
    uint256 /*tokenId*/ // solhint-disable-next-line no-empty-blocks
  ) internal virtual {
    // No-op
  }


  /**
   * @notice Cancel the `msg.sender`'s offer if there is one, freeing up their SBT balance.
   * @dev This should be used when it does not make sense to keep the original offer around,
   * e.g. if a collector accepts a Buy Price then keeping the offer around is not necessary.
   */
  function _cancelSendersOffer(address derivativeNFT, uint256 tokenId) internal virtual;

  /**
   * @notice Transfers the DNFT from escrow and clears any state tracking this escrowed DNFT.
   * @param authorizeSeller The address of the seller pending authorization.
   * Once it's been authorized by one of the escrow managers, it should be set to address(0)
   * indicated that it's no longer pending authorization.
   */
  function _transferFromEscrow(
    address derivativeNFT,
    uint256 fromTokenId,
    uint256 toTokenId,
    uint128 units,
    address authorizeSeller
  ) internal virtual{
    if (authorizeSeller != address(0)) {
      revert DNFTMarketCore_Seller_Not_Found();
    }

    //transfer units from escrow to toTokenId
    IDerivativeNFTV1(derivativeNFT).transferValue(fromTokenId, toTokenId, uint256(units));

  }

  /**
   * @notice Transfers the DNFT from escrow unless there is another reason for it to remain in escrow.
   */
  function _transferFromEscrowIfAvailable(
    address derivativeNFT,
    uint256 fromTokenId,
    uint256 toTokenId,
    uint128 units
  ) internal virtual {
    _transferFromEscrow(derivativeNFT, fromTokenId, toTokenId, units, address(0));
  }

  /**
   * @notice Transfers an DNFT units into escrow,
   * if already there this requires the msg.sender is authorized to manage the sale of this DNFT.
   */
  function _transferToEscrow(address derivativeNFT, uint256 tokenId, uint128 units) 
    internal virtual returns(uint256)
  {
    return IERC3525(derivativeNFT).transferFrom(tokenId, address(this), uint256(units));
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
  function _getSellerOf(address derivativeNFT, uint256 tokenId)
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
  
  function _getSellerOrOwnerOf(address derivativeNFT, uint256 tokenId)
    internal
    view
    override
    returns (address payable sellerOrOwner)
  {
    sellerOrOwner = _getSellerOf(derivativeNFT, tokenId);
    if (sellerOrOwner == address(0)) {
      sellerOrOwner = payable(IERC3525(derivativeNFT).ownerOf(tokenId));
    }
  }
  

  /**
   * @notice Checks if an escrowed DNFT is currently in active auction.
   * @return Returns false if the auction has ended, even if it has not yet been settled.
   */
  function _isInActiveAuction(address derivativeNFT, uint256 tokenId) internal view virtual returns (bool);


  
  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev 50 slots were consumed by adding `ReentrancyGuard`.
   */
  uint256[450] private __gap;
}
