// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import './libraries/Constants.sol';
import {IMarketPlace} from "./interfaces/IMarketPlace.sol";
import {DataTypes} from './libraries/DataTypes.sol';
import {Events} from"./libraries/Events.sol";
import {Errors} from "./libraries/Errors.sol";
import {MarketLogic} from './libraries/MarketLogic.sol';
import {MarketPlaceStorage} from  "./storage/MarketPlaceStorage.sol";
import {IModuleGlobals} from "./interfaces/IModuleGlobals.sol";
import {DNFTMarketAuction} from "./market/DNFTMarketAuction.sol";
import {MarketSharedCore} from "./market/MarketSharedCore.sol";
import {DNFTMarketCore} from "./market/DNFTMarketCore.sol";
import {MarketFees} from "./market/MarketFees.sol";
import {DNFTMarketOffer} from "./market/DNFTMarketOffer.sol";
import {DNFTMarketBuyPrice} from "./market/DNFTMarketBuyPrice.sol";
import {DNFTMarketReserveAuction} from "./market/DNFTMarketReserveAuction.sol";
import {AdminRoleEnumerable} from "./market/AdminRoleEnumerable.sol";
import {OperatorRoleEnumerable} from "./market/OperatorRoleEnumerable.sol";

import "hardhat/console.sol";

contract MarketPlace is
    Initializable,
    IMarketPlace,
    MarketPlaceStorage,
    MarketSharedCore,
    DNFTMarketCore,
    MarketFees,
    DNFTMarketAuction,
    DNFTMarketReserveAuction,    
    DNFTMarketBuyPrice,
    DNFTMarketOffer,
    IERC165,
    IERC3525Receiver,
    PausableUpgradeable,
    AdminRoleEnumerable,
    OperatorRoleEnumerable,
    UUPSUpgradeable
{

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address manager,
        address treasury,
        address sbt,
        uint256 duration  //24h
    ) 
    DNFTMarketReserveAuction(duration) 
    MarketFees(manager, treasury, sbt)
    initializer {}

    function initialize(address admin) external override initializer {
        AdminRoleEnumerable._initializeAdminRole(admin);
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    // --- override --- //
    function _getWallet(uint256 soulBoundTokenId) internal virtual view override returns(address) {
        if (MODULE_GLOBALS == address(0)) revert Errors.ModuleGlobasNotSet();
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        return IERC3525(_sbt).ownerOf(soulBoundTokenId);
    }

    function _getTreasuryData() internal virtual view override returns (address, uint16) {
        return IModuleGlobals(MODULE_GLOBALS).getTreasuryData();
    }

    function _getMarketInfo(address derivativeNFT) internal virtual view override returns (DataTypes.Market memory) {
        return markets[derivativeNFT];
    }

    function _beforeAuctionStarted(address derivativeNFT, uint256 tokenId)
        internal
        override(DNFTMarketCore, DNFTMarketBuyPrice, DNFTMarketOffer)
    {
        // This is a no-op function required to avoid compile errors.
        super._beforeAuctionStarted(derivativeNFT, tokenId);
    }

    function _transferFromEscrow(
        address derivativeNFT,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint128 units,
        address authorizeSeller
    ) internal override(DNFTMarketCore, DNFTMarketReserveAuction){
        // This is a no-op function required to avoid compile errors.
        super._transferFromEscrow(derivativeNFT, fromTokenId, toTokenId, units, authorizeSeller);
    }
 
    function _transferFromEscrowIfAvailable(
        address derivativeNFT,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint128 units
    ) internal override(DNFTMarketCore, DNFTMarketReserveAuction, DNFTMarketBuyPrice) {
        // This is a no-op function required to avoid compile errors.
        super._transferFromEscrowIfAvailable(derivativeNFT, fromTokenId, toTokenId, units);
    }

    function _transferToEscrow(address derivativeNFT, uint256 tokenId, uint128 onSellUnits)
        internal
        override(DNFTMarketCore, DNFTMarketReserveAuction, DNFTMarketBuyPrice)
        returns(uint256)
    {
        // This is a no-op function required to avoid compile errors.
        return super._transferToEscrow(derivativeNFT, tokenId, onSellUnits);
    }
        
    function _getSellerOf(address derivativeNFT, uint256 tokenId)
        internal
        view
        override(MarketSharedCore, DNFTMarketCore, DNFTMarketReserveAuction, DNFTMarketBuyPrice)
        returns (address payable seller)
    {
        // This is a no-op function required to avoid compile errors.
        seller = super._getSellerOf(derivativeNFT, tokenId);
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    receive() external payable {
        // if (msg.value > 0) {
        //     (address treasury, ) = IModuleGlobals(MODULE_GLOBALS).getTreasuryData();
        //     address payable _to = payable(treasury);
        //     (bool success, ) = _to.call{value: msg.value}("");
        //     if (!success) revert Errors.TransferEtherToBankTreasuryFailed();
        // }
        emit Events.MarketPlaceDeposit(msg.sender, msg.value, address(this), address(this).balance);
    }

    fallback() external payable {
        // if (msg.value > 0) {
        //     (address treasury, ) = IModuleGlobals(MODULE_GLOBALS).getTreasuryData();
        //     address payable _to = payable(treasury);
        //     (bool success, ) = _to.call{value: msg.value}("");
        //     if (!success) revert Errors.TransferEtherToBankTreasuryFailed();
        // }        
        emit Events.MarketPlaceDepositByFallback(msg.sender, msg.value, address(this), address(this).balance, msg.data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC3525Receiver).interfaceId;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {
        newImplementation;
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert Errors.Unauthorized();
    }

    function onERC3525Received(
        address operator,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        emit Events.MarketPlaceERC3525Received(operator, fromTokenId, toTokenId, value, data, gasleft());
        return 0x009ce20b;
    }

    //must set after moduleGlobals deployed
    function setGlobalModule(address moduleGlobals) 
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

    function addMarket(
        address derivativeNFT_,
        DataTypes.FeePayType feePayType_,
        DataTypes.FeeShareType feeShareType_,
        uint16 royaltyBasisPoints_
    ) 
        external 
        whenNotPaused   
        onlyOperator 
    {
        MarketLogic.addMarket(
            derivativeNFT_,
            feePayType_,
            feeShareType_,
            royaltyBasisPoints_,
            markets
        );
    }

    function getMarketInfo(address derivativeNFT) external view returns(DataTypes.Market memory) {
        return _getMarketInfo(derivativeNFT);
    }

    function removeMarket(address derivativeNFT_) 
        external 
        whenNotPaused   
        onlyOperator
    {
        delete markets[derivativeNFT_];
        emit Events.RemoveMarket(derivativeNFT_);
    }

    function setMarketOpen(address derivativeNFT, bool isOpen) 
        external 
        whenNotPaused          
        onlyOperator
    {
        markets[derivativeNFT].isOpen = isOpen;
    }
}