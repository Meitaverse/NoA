// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
import {IDerivativeNFTV1} from "./interfaces/IDerivativeNFTV1.sol";
import "./interfaces/INFTDerivativeProtocolTokenV1.sol";
import {IMarketPlace} from "./interfaces/IMarketPlace.sol";
import {Constants} from './libraries/Constants.sol';
import {DataTypes} from './libraries/DataTypes.sol';
import {Events} from"./libraries/Events.sol";
import {Errors} from "./libraries/Errors.sol";
import "./libraries/SafeMathUpgradeable128.sol";
import {PriceManager} from './libraries/PriceManager.sol';
import {MarketPlaceStorage} from  "./storage/MarketPlaceStorage.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {IBankTreasury} from "./interfaces/IBankTreasury.sol";
import {IModuleGlobals} from "./interfaces/IModuleGlobals.sol";
import {IManager} from "./interfaces/IManager.sol";

contract MarketPlace is
    Initializable,
    IMarketPlace,
    MarketPlaceStorage,
    PriceManager,
    IERC165,
    IERC3525Receiver,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;
     using SafeMathUpgradeable128 for uint128;
    using Counters for Counters.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint16 internal constant BPS_MAX = 10000;

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    /**
     * @dev This modifier reverts if the caller is not the configured manager address.
     */
    modifier onlyManager() {
        _validateCallerIsManager();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address governance) external override initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        if (governance == address(0)) revert Errors.InitParamsInvalid();
        _setGovernance(governance);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    receive() external payable {
        emit Events.Deposit(msg.sender, msg.value, address(this).balance);
    }

    fallback() external payable {
        // revert();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlUpgradeable, IERC165) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(AccessControlUpgradeable).interfaceId ||
            interfaceId == type(IERC3525Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {
        newImplementation;
        if (!hasRole(UPGRADER_ROLE, _msgSender())) revert Errors.Unauthorized();
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

    function setGlobalModule(address moduleGlobals) external onlyGov {
        if (moduleGlobals == address(0)) revert Errors.InitParamsInvalid();
        MODULE_GLOBALS = moduleGlobals;
    }

    function getGlobalModule() external view returns (address) {
        return MODULE_GLOBALS;
    }

   
    function getGovernance() external override returns (address) {
         return _governance;
    }

    function publishFixedPrice(DataTypes.Sale memory sale) external override {
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(sale.soulBoundTokenId);

        uint24 saleId = _generateNextSaleId();
        _derivativeNFTSales[sale.derivativeNFT].add(saleId);
        PriceManager.setFixedPrice(saleId, sale.price);
        _publishFixedPrice(sale);
    }

    function removeSale(uint256 soulBoundTokenId, address seller, uint24 saleId) external override {
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(soulBoundTokenId);
        _removeSale(seller, saleId);
    }

    function addMarket(
        address derivativeNFT_,
        uint64 precision_,
        uint8 feePayType_,
        uint8 feeType_,
        uint128 feeAmount_,
        uint16 feeRate_
    ) external override {
        
        markets[derivativeNFT_].isValid = true;
        markets[derivativeNFT_].precision = precision_;
        markets[derivativeNFT_].feePayType = DataTypes.FeePayType(feePayType_);
        markets[derivativeNFT_].feeType = DataTypes.FeeType(feeType_);
        markets[derivativeNFT_].feeAmount = feeAmount_;
        markets[derivativeNFT_].feeRate = feeRate_;

        emit Events.AddMarket(
            derivativeNFT_,
            precision_,
            feePayType_,
            feeType_,
            feeAmount_,
            feeRate_
        );
    }

    function removeMarket(address derivativeNFT_) external override {
        delete markets[derivativeNFT_];
        emit Events.RemoveMarket(derivativeNFT_);
    }

    function buyUnits(
        uint256 soulBoundTokenId,
        address buyer,
        uint24 saleId,
        uint128 units
    ) external payable override returns (uint256 amount, uint128 fee) {
         _validateCallerIsSoulBoundTokenOwnerOrDispathcher(soulBoundTokenId);
        if (sales[saleId].max > 0) {
            require(saleRecords[sales[saleId].saleId][buyer].add(units) <= sales[saleId].max, "exceeds purchase limit");
            saleRecords[sales[saleId].saleId][buyer] = saleRecords[sales[saleId].saleId][buyer].add(units);
        }

        if (sales[saleId].useAllowList) {
            require(_allowAddresses[sales[saleId].derivativeNFT].contains(buyer), "not in allow list");
        }

        return
            _buyByUnits(
                _generateNextTradeId(),
                buyer,
                saleId,
                PriceManager.price(DataTypes.PriceType.FIXED, saleId),
                units
            );
    }
    
    function purchasedUnits(
        uint24 saleId_, 
        address buyer_
    ) external view returns(uint128) {
        return saleRecords[saleId_][buyer_];
    }

    function totalSalesOfICToken(
        address derivativeNFT_
    )
        external
        view
        returns (uint256)
    {
        return _derivativeNFTSales[derivativeNFT_].length();
    }

    function saleIdOfICTokenByIndex(
        address derivativeNFT_, 
        uint256 index_
    )
        external
        view
        returns (uint256)
    {
        return _derivativeNFTSales[derivativeNFT_].at(index_);
    }
    //--- internal  ---//


    function _generateNextTradeId() internal returns (uint24) {
        _nextTradeId.increment();
        return uint24(_nextTradeId.current());
    } 

    function  _validateCallerIsSoulBoundTokenOwnerOrDispathcher(uint256 soulBoundTokenId_) internal view {
         address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
         address _manager = IModuleGlobals(MODULE_GLOBALS).getManager();

         if (IERC3525(_sbt).ownerOf(soulBoundTokenId_) == msg.sender || 
            IManager(_manager).getDispatcher(soulBoundTokenId_) == msg.sender) {
            return;
         }

         revert Errors.NotProfileOwnerOrDispatcher();
    }

    function _setGovernance(address newGovernance) internal {
        _governance = newGovernance;
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }

    function _validateCallerIsManager() internal view {
        address _manager = IModuleGlobals(MODULE_GLOBALS).getManager();
        if (msg.sender != _manager) revert Errors.NotManager();
    }

    function _generateNextSaleId() internal returns (uint24) {
        _nextSaleId.increment();
        return uint24(_nextSaleId.current());
    }

    function _publishFixedPrice(
        DataTypes.Sale memory sale
    ) internal {

        // DataTypes.PriceType priceType_ = DataTypes.PriceType.FIXED;

        require(markets[sale.derivativeNFT].isValid, "unsupported derivativeNFT");
        if (sale.max > 0) {
            require(sale.min <= sale.max, "min > max");
        }

        uint128 units = uint128(IERC3525(sale.derivativeNFT).balanceOf(sale.tokenId));
        require(units <= type(uint128).max, "exceeds uint128 max");
        sales[sale.saleId] = DataTypes.Sale({
            saleId: sale.saleId,
            soulBoundTokenId: sale.soulBoundTokenId,
            projectId : sale.projectId,
            seller: msg.sender,
            price: sale.price,
            tokenId: sale.tokenId,
            total: uint128(units),
            units: uint128(units),
            startTime: sale.startTime,
            min: sale.min,
            max: sale.max,
            derivativeNFT: sale.derivativeNFT,
            currency: sale.currency,
            priceType: sale.priceType,
            useAllowList: sale.useAllowList,
            isValid: true
        });

        emit Events.PublishSale(
            sale.derivativeNFT,
            sale.seller,
            sale.tokenId,
            sale.saleId,
            uint8(sale.priceType),
            sale.units,
            sale.startTime,
            sale.currency,
            sale.min,
            sale.max,   
            sale.useAllowList
        );
        
        emit Events.FixedPriceSet(
            sale.derivativeNFT,
            sale.saleId,
            sale.projectId,
            sale.tokenId,
            uint128(units),
            uint8(sale.priceType),
            sale.price
        );
    }


    function _removeSale(
        address seller,
        uint24 saleId_
    ) internal {
        DataTypes.Sale memory sale = sales[saleId_];
        if (!sale.isValid) revert Errors.InvalidSale();

        if(sale.seller != seller) revert Errors.OnlySeller();

        delete sales[saleId_];

        emit Events.RemoveSale(
            sale.derivativeNFT,
            sale.seller,
            sale.saleId,
            sale.total,
            sale.total - sale.units
        );
    }


    function _buyByUnits(
        uint256 nextTradeId_,
        address buyer_,
        uint24 saleId_, 
        uint128 price_,
        uint128 units_
    ) internal returns (uint256 amount_, uint128 fee_) {
        DataTypes.Sale storage sale_ = sales[saleId_];

        amount_ = uint256(units_).mul(uint256(price_)).div(
            uint256(markets[sale_.derivativeNFT].precision)
        );

        emit Events.Traded(
            buyer_,
            sale_.saleId,
            sale_.derivativeNFT,
            sale_.tokenId,
            nextTradeId_,
            uint32(block.timestamp),
            sale_.currency,
            uint8(sale_.priceType),
            price_,
            units_,
            amount_,
            // uint8(feePayType),
            fee_
        );  

        if (sale_.units == 0) {
            emit Events.RemoveSale(
                sale_.derivativeNFT,
                sale_.seller,
                sale_.saleId,
                sale_.total,
                sale_.total - sale_.units
            );
            delete sales[sale_.saleId];
        }
        return (amount_, fee_);
    }

}