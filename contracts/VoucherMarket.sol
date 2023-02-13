// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import './libraries/Constants.sol';
import {IVoucherMarket} from "./interfaces/IVoucherMarket.sol";
import {DataTypes} from './libraries/DataTypes.sol';
import {Errors} from "./libraries/Errors.sol";
import "./shared/FETHNode.sol";
import "./shared/FoundationTreasuryNode.sol";
import "./shared/MarketSharedCore.sol";
import "./shared/MarketFees.sol";
import "./shared/SendValueWithFallbackWithdraw.sol";
import "./voucher/VoucherMarketCore.sol";
import "./voucher/VoucherMarketBuyPrice.sol";
import "./voucher/VoucherMarketOffer.sol";
import {IModuleGlobals} from "./interfaces/IModuleGlobals.sol";
import {AdminRoleEnumerable} from "./market/AdminRoleEnumerable.sol";
import {OperatorRoleEnumerable} from "./market/OperatorRoleEnumerable.sol";

import "hardhat/console.sol";

contract VoucherMarket is
    Initializable,
    IVoucherMarket,
    FoundationTreasuryNode,
    FETHNode,
    MarketSharedCore,
    VoucherMarketCore,
    ReentrancyGuardUpgradeable,
    SendValueWithFallbackWithdraw,
    MarketFees,
    VoucherMarketBuyPrice,
    VoucherMarketOffer,
    PausableUpgradeable,
    AdminRoleEnumerable,
    OperatorRoleEnumerable,
    UUPSUpgradeable 
{
    using Counters for Counters.Counter;

    //Voucher market
    event VoucherMarketERC1155Received(
        address indexed sender,
        address indexed operator, 
        address indexed from, 
        uint256 id, 
        uint256 value, 
        bytes data, 
        uint256 gas
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address payable treasury,
        address feth,
        address royaltyRegistry
    ) 
    FoundationTreasuryNode(treasury)
    VoucherMarketCore()
    FETHNode(feth)
    MarketFees(
      /* protocolFeeInBasisPoints: */
      500,
      royaltyRegistry,
      /* assumePrimarySale: */
      false
    )    
    initializer {}

    function initialize(address admin) external initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        AdminRoleEnumerable._initializeAdminRole(admin);
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    // --- override --- //

    function _transferFromEscrow(
        address voucherNFT,
        uint256 tokenId,
        address recipient,
        address authorizeSeller
    ) internal override(VoucherMarketCore, VoucherMarketBuyPrice){
        // This is a no-op function required to avoid compile errors.
        super._transferFromEscrow(voucherNFT, tokenId, recipient, authorizeSeller);
    }
 
    function _transferFromEscrowIfAvailable(
        address voucherNFT,
        uint256 tokenId,
        address recipient
    ) internal override(VoucherMarketCore, VoucherMarketBuyPrice) {
        // This is a no-op function required to avoid compile errors.
        super._transferFromEscrowIfAvailable(voucherNFT, tokenId, recipient);
    }

    function _transferToEscrow(address voucherNFT, uint256 tokenId)
        internal
        override(VoucherMarketCore, VoucherMarketBuyPrice)
    {
        // This is a no-op function required to avoid compile errors.
        super._transferToEscrow(voucherNFT, tokenId);
    }


    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {
        newImplementation;
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert Errors.Unauthorized();
    }

    // our contract can recieve ERC1155 tokens
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public virtual returns (bytes4) {
        console.log('onERC1155Received:', msg.sender);
        console.log('onERC1155Received, operator:', operator);
        console.log('onERC1155Received, from:', from);
        if (value == 0) {
            revert Errors.Must_Escrow_Non_Zero_Amount();
        } 

//TODO
/*
        if (msg.sender != getVoucherContract()) {
            revert Errors.Only_BITSOUL_Voucher_Allowed();
        }
*/

        emit VoucherMarketERC1155Received(msg.sender, operator, from, id, value, data, gasleft());
 
        return this.onERC1155Received.selector;
    }

/*
    //must set after moduleGlobals deployed
    function setGlobalModules(address moduleGlobals) 
        external
        whenNotPaused  
        onlyAdmin 
    {
        if (moduleGlobals == address(0)) revert Errors.InitParamsInvalid();
        MODULE_GLOBALS = moduleGlobals;
    }

    function getGlobalModule() external view returns (address) {
        return MODULE_GLOBALS;
    }
    */


   /**
     * @inheritdoc MarketSharedCore
     */
    function _getSellerOf(address voucherNFT, uint256 tokenId)
        internal
        view
        override(MarketSharedCore, VoucherMarketCore, VoucherMarketBuyPrice)
        // override(MarketSharedCore, NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice)
        returns (address payable seller)
    {
        // This is a no-op function required to avoid compile errors.
        seller = super._getSellerOf(voucherNFT, tokenId);

    }
}