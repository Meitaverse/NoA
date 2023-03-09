// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {Events} from "../libraries/Events.sol";
import {Errors} from "../libraries/Errors.sol";
import {DataTypes} from '../libraries/DataTypes.sol';
import {IDerivativeNFT} from "../interfaces/IDerivativeNFT.sol";
import {IManager} from "../interfaces/IManager.sol";
import {IBankTreasury} from '../interfaces/IBankTreasury.sol';
import {INFTDerivativeProtocolTokenV1} from "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import {IModuleGlobals} from "../interfaces/IModuleGlobals.sol";

import "../libraries/Constants.sol";
// import "hardhat/console.sol";

error DNFTMarketCore_Seller_Not_Found();

/**
 * @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 * @author bitsoul Protocol
 */
abstract contract DNFTMarketCore is Initializable {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;
    
  /// @notice The fee collected by the buy referrer for sales facilitated by this market contract.
  ///         This fee is calculated from the total protocol fee.
  uint16 internal constant BUY_REFERRER_FEE_DENOMINATOR = 100; //BASIS_POINTS / 100; // 1%
  

  IBankTreasury internal treasury;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function __dNFT_market_core_init(address treasury_) internal onlyInitializing{
     treasury = IBankTreasury(treasury_);
  }

  function _getWallet(uint256 soulBoundTokenId) internal virtual returns(address);

  function _isCurrencyWhitelisted(address currency) internal virtual returns(bool);

  function _getTreasuryData() internal virtual view returns (address, uint16);

  function _getMarketInfo(address derivativeNFT) internal virtual view returns (DataTypes.Market memory);

  /**
   * @notice Returns id to assign to the next auction.
   */
  function _getNextAndIncrementAuctionId() internal virtual returns (uint256);


  /**
   * @notice If there is a buy price at this amount or lower, accept that and return true.
   */
  function _autoAcceptBuyPrice(
    uint256 soulBoundTokenIdBuyer,
    address derivativeNFT,
    uint256 tokenId,
    uint96 amount
  ) internal virtual returns (bool);

  /**
   * @notice If there is a valid offer at the given price or higher, accept that and return true.
   */
  
  function _autoAcceptOffer(
    DataTypes.BuyPriceParam memory buyPriceParam,
    uint128 units
  ) internal virtual;

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
      uint256 tokenId,
      address recipient,
      address authorizeSeller
  ) internal virtual{
    if (authorizeSeller != address(0)) {
      revert DNFTMarketCore_Seller_Not_Found();
    }

    //transfer the tokenId from escrow to recipient
    if (tokenId != 0) {
      IERC3525(derivativeNFT).transferFrom(address(this), recipient, tokenId);
    }
  }

  /**
   * @notice Transfers the DNFT from escrow unless there is another reason for it to remain in escrow.
   */
  function _transferFromEscrowIfAvailable(
      address derivativeNFT,
      uint256 tokenId,
      address recipient
  ) internal virtual {
    _transferFromEscrow(derivativeNFT, tokenId, recipient, address(0));
  }
 
  /**
   * @notice Transfers an DNFT units into escrow,
   * if insufficient value , it will fail.
   * if already there this requires the msg.sender is authorized to manage the sale of this DNFT.
   */
  function _transferToEscrow(address derivativeNFT, uint256 tokenId) 
    internal virtual
  {
   IERC3525(derivativeNFT).transferFrom(msg.sender, address(this), tokenId);
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
  // uint256[450] private __gap;
}
