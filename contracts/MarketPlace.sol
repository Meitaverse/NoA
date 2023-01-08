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
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
    ReentrancyGuard,
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

    function setGlobalModule(address moduleGlobals) 
        external
        nonReentrant
        whenNotPaused  
        onlyGov 
    {
        if (moduleGlobals == address(0)) revert Errors.InitParamsInvalid();
        MODULE_GLOBALS = moduleGlobals;
    }

    function getGlobalModule() external view returns (address) {
        return MODULE_GLOBALS;
    }
   
    function getGovernance() external view returns (address) {
         return _governance;
    }

    function publishSale(
        DataTypes.SaleParam memory saleParam
    ) 
        external 
        nonReentrant
        whenNotPaused  
    {
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(saleParam.soulBoundTokenId);
        
        if (saleParam.max > 0) {
            if (saleParam.min > saleParam.max) revert Errors.MinGTMax();
        }

        address _manager = IModuleGlobals(MODULE_GLOBALS).getManager();
        address derivativeNFT = IManager(_manager).getDerivativeNFT(saleParam.projectId);
        if (derivativeNFT == address(0)) 
            revert Errors.InvalidParameter();
        
        if (!markets[derivativeNFT].isValid)
            revert Errors.UnsupportedDerivativeNFT();
        
        uint128 total = uint128(IERC3525(derivativeNFT).balanceOf(saleParam.tokenId));
        if(total > type(uint128).max) revert Errors.ExceedsUint128Max();
        if(total == 0) revert Errors.TotalIsZero();
        if(saleParam.max > total) revert Errors.MaxGTTotal(); 
        
        uint24 saleId = _generateNextSaleId();
        _derivativeNFTSales[derivativeNFT].add(saleId);
        PriceManager.setFixedPrice(saleId, saleParam.salePrice);

        //must approve manager before
        uint256 newTokenId = IERC3525(derivativeNFT).transferFrom(saleParam.tokenId, address(this), saleParam.onSellUnits);
        
        //genesis
        uint256 genesisPublishId = IManager(IModuleGlobals(MODULE_GLOBALS).getManager()).getGenesisPublishIdByProjectId(saleParam.projectId);
        DataTypes.PublishData memory gengesisPublishData  = IManager(IModuleGlobals(MODULE_GLOBALS).getManager()).getPublishInfo(genesisPublishId);
        DataTypes.ProjectData memory genesisProjectData = IManager(IModuleGlobals(MODULE_GLOBALS).getManager()).getProjectInfo(saleParam.projectId);
   
        //previous 
        (uint256 publishId, )  = IManager(IModuleGlobals(MODULE_GLOBALS).getManager()).getPublicationByTokenId(saleParam.tokenId);
        DataTypes.PublishData memory publishData  = IManager(IModuleGlobals(MODULE_GLOBALS).getManager()).getPublishInfo(publishId);
        
        DataTypes.PublishData memory previousPublishData = IManager(IModuleGlobals(MODULE_GLOBALS).getManager()).getPublishInfo(publishData.previousPublishId);
 
        _publishFixedPrice(
            saleId, 
            newTokenId, 
            derivativeNFT, 
            saleParam,
            genesisProjectData.soulBoundTokenId,
            gengesisPublishData.publication.royaltyBasisPoints,
            previousPublishData.publication.soulBoundTokenId,
            previousPublishData.publication.royaltyBasisPoints
        ); 
    }

    function fixedPriceSet(uint24 saleId, uint128 newSalePrice) external  {
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(sales[saleId].soulBoundTokenId);

        DataTypes.Sale memory sale = sales[saleId];

        if (!sale.isValid) revert Errors.InvalidSale();

        uint128 preSalePrice = sale.salePrice;
        
        emit Events.FixedPriceSet(
            sales[saleId].soulBoundTokenId,
            saleId,
            preSalePrice,
            newSalePrice,
            block.timestamp
        );
    }

    function setSaleValid(uint24 saleId, bool isValid) external onlyGov{
        DataTypes.Sale storage sale = sales[saleId];
        sale.isValid = isValid;
    }

    function setMarketValid(address derivativeNFT, bool isValid) external onlyGov{
        markets[derivativeNFT].isValid = isValid;
    }

    function removeSale(uint24 saleId) external nonReentrant {
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(sales[saleId].soulBoundTokenId);
       
        _removeSale(saleId);
    }

    function addMarket(
        address derivativeNFT_,
        DataTypes.FeePayType feePayType_,
        DataTypes.FeeShareType feeShareType_,
        uint16 royaltyBasisPoints_
    ) 
        external 
        nonReentrant
        whenNotPaused   
        onlyGov 
    {
        markets[derivativeNFT_].isValid = true;
        markets[derivativeNFT_].feePayType = DataTypes.FeePayType(feePayType_);
        markets[derivativeNFT_].feeShareType = DataTypes.FeeShareType(feeShareType_);
        markets[derivativeNFT_].royaltyBasisPoints = royaltyBasisPoints_;

        emit Events.AddMarket(
            derivativeNFT_,
            feePayType_,
            feeShareType_,
            royaltyBasisPoints_
        );
    }

    function removeMarket(address derivativeNFT_) 
        external 
        nonReentrant
        whenNotPaused   
        onlyGov
    {
        delete markets[derivativeNFT_];
        emit Events.RemoveMarket(derivativeNFT_);
    }

    function buyUnits(
        uint256 buyerSoulBoundTokenId,
        uint24 saleId,
        uint128 units
    )
        external 
        payable 
        nonReentrant
        whenNotPaused 
    {
         _validateCallerIsSoulBoundTokenOwnerOrDispathcher(buyerSoulBoundTokenId);

        address _manager = IModuleGlobals(MODULE_GLOBALS).getManager();
        address buyer = IManager(_manager).getWalletBySoulBoundTokenId(buyerSoulBoundTokenId);
 
        if (sales[saleId].max > 0) {
            if (saleRecords[saleId][buyer].add(units) > sales[saleId].max) 
                revert Errors.ExceedsPurchaseLimit(); 

            saleRecords[saleId][buyer] = saleRecords[saleId][buyer].add(units);
        }

        if (sales[saleId].min > units) {
           
            revert Errors.UnitsLTMin();
        }

        if (units > sales[saleId].max) {
           
            revert Errors.UnitsGTMax();
        }

        _buyByUnits(
            buyerSoulBoundTokenId,
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

    function _validateCallerIsSoulBoundTokenOwnerOrDispathcher(uint256 soulBoundTokenId_) internal view {
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
        uint24 saleId,
        uint256 newTokenId, 
        address derivativeNFT, 
        DataTypes.SaleParam memory saleParam,
        uint256 genesisSoulBoundTokenId,
        uint256 genesisRoyaltyBasisPoints,
        uint256 previousSoulBoundTokenId,
        uint256 previousRoyaltyBasisPoints
    ) internal {

        sales[saleId] = DataTypes.Sale({
            soulBoundTokenId: saleParam.soulBoundTokenId,
            projectId : saleParam.projectId,
            salePrice: saleParam.salePrice,
            tokenId: saleParam.tokenId,
            newTokenId: newTokenId,
            onSellUnits: saleParam.onSellUnits, 
            seledUnits: 0,
            startTime: saleParam.startTime,
            min: saleParam.min,
            max: saleParam.max,
            derivativeNFT: derivativeNFT,
            priceType: saleParam.priceType,
            isValid: true, 
            genesisSoulBoundTokenId: genesisSoulBoundTokenId,
            genesisRoyaltyBasisPoints: genesisRoyaltyBasisPoints,
            previousSoulBoundTokenId: previousSoulBoundTokenId,
            previousRoyaltyBasisPoints: previousRoyaltyBasisPoints
        });

        emit Events.PublishSale(
            saleParam,
            derivativeNFT,
            newTokenId,
            saleId
        );
    }

    function _removeSale(
        uint24 saleId_
    ) internal {
        DataTypes.Sale memory sale = sales[saleId_];

        if (!sale.isValid) revert Errors.InvalidSale();

        delete sales[saleId_];

        emit Events.RemoveSale(
            sale.soulBoundTokenId,
            saleId_,
            sale.onSellUnits,
            sale.seledUnits
        );
    }

    function _buyByUnits(
        uint256 buyerSoulBoundTokenId_,
        uint256 nextTradeId_,
        address buyer_,
        uint24 saleId_, 
        uint128 price_,
        uint128 units_
    ) internal {
        DataTypes.Sale storage sale_ = sales[saleId_];   

        //transfer units to buyer
        uint256 newTokenIdBuyer_ = IERC3525(sale_.derivativeNFT).transferFrom(sale_.newTokenId, buyer_, uint256(units_));

        uint256 payValue = units_.mul(sale_.salePrice);

        //get realtime bank treasury fee points
        (, uint16 treasuryFee) = IModuleGlobals(MODULE_GLOBALS).getTreasuryData();

        DataTypes.RoyaltyAmounts memory royaltyAmounts;
        royaltyAmounts.treasuryAmount = payValue.mul(treasuryFee).div(BPS_MAX);

        royaltyAmounts.genesisAmount = payValue.mul(sale_.genesisRoyaltyBasisPoints).div(BPS_MAX);
        royaltyAmounts.previousAmount = payValue.mul(sale_.previousRoyaltyBasisPoints).div(BPS_MAX);
            
        if (royaltyAmounts.treasuryAmount > 0){
            if (markets[sale_.derivativeNFT].feePayType == DataTypes.FeePayType.BUYER_PAY) {
                INFTDerivativeProtocolTokenV1(IModuleGlobals(MODULE_GLOBALS).getSBT()).transferValue(buyerSoulBoundTokenId_, Constants._BANK_TREASURY_SOUL_BOUND_TOKENID, royaltyAmounts.treasuryAmount);
                royaltyAmounts.adjustedAmount = payValue.sub(royaltyAmounts.treasuryAmount).sub(royaltyAmounts.genesisAmount).sub(royaltyAmounts.previousAmount);
                
            } else {
                INFTDerivativeProtocolTokenV1(IModuleGlobals(MODULE_GLOBALS).getSBT()).transferValue(sale_.soulBoundTokenId, Constants._BANK_TREASURY_SOUL_BOUND_TOKENID, royaltyAmounts.treasuryAmount);
                royaltyAmounts.adjustedAmount = payValue.sub(royaltyAmounts.genesisAmount).sub(royaltyAmounts.previousAmount);
                
            }
        } 

        if(markets[sale_.derivativeNFT].feeShareType == DataTypes.FeeShareType.LEVEL_TWO ) {

            if ( royaltyAmounts.adjustedAmount > 0) 
                INFTDerivativeProtocolTokenV1(IModuleGlobals(MODULE_GLOBALS).getSBT()).transferValue(buyerSoulBoundTokenId_, sale_.soulBoundTokenId, royaltyAmounts.adjustedAmount);
            
            if (royaltyAmounts.genesisAmount > 0) INFTDerivativeProtocolTokenV1(IModuleGlobals(MODULE_GLOBALS).getSBT()).transferValue(buyerSoulBoundTokenId_, sale_.genesisSoulBoundTokenId, royaltyAmounts.genesisAmount);
            if (royaltyAmounts.previousAmount > 0) INFTDerivativeProtocolTokenV1(IModuleGlobals(MODULE_GLOBALS).getSBT()).transferValue(buyerSoulBoundTokenId_, sale_.previousSoulBoundTokenId, royaltyAmounts.previousAmount);
        
        } else if(markets[sale_.derivativeNFT].feeShareType == DataTypes.FeeShareType.LEVEL_FIVE) {
            royaltyAmounts.adjustedAmount = payValue.mul(markets[sale_.derivativeNFT].royaltyBasisPoints);
            if ( royaltyAmounts.adjustedAmount > 0 ) 
                INFTDerivativeProtocolTokenV1(IModuleGlobals(MODULE_GLOBALS).getSBT()).transferValue(buyerSoulBoundTokenId_, sale_.soulBoundTokenId, royaltyAmounts.adjustedAmount);
            
            INFTDerivativeProtocolTokenV1(IModuleGlobals(MODULE_GLOBALS).getSBT()).transferValue(buyerSoulBoundTokenId_, Constants._BANK_TREASURY_SOUL_BOUND_TOKENID, payValue.sub(royaltyAmounts.adjustedAmount).sub(royaltyAmounts.treasuryAmount));
        }

        sale_.onSellUnits -= units_;
        sale_.seledUnits += units_;

        emit Events.Traded(
            saleId_,
            nextTradeId_,
            uint32(block.timestamp),
            price_,
            newTokenIdBuyer_,
            units_
        );

        if (sale_.onSellUnits == 0) {
            emit Events.RemoveSale(
                sale_.soulBoundTokenId,
                saleId_,
                sale_.onSellUnits,
                sale_.seledUnits
            );
            delete sales[saleId_];
        }
    }

}