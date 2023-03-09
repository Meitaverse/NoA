// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import '../libraries/Constants.sol';
import {DataTypes} from '../libraries/DataTypes.sol';
import {Events} from"../libraries/Events.sol";
import {Errors} from "../libraries/Errors.sol";
import {MarketPlaceStorage} from  "../storage/MarketPlaceStorage.sol";
import {IModuleGlobals} from "../interfaces/IModuleGlobals.sol";
import {DNFTMarketCore} from "../market/DNFTMarketCore.sol";
import {DNFTMarketOffer} from "../market/DNFTMarketOffer.sol";
import {DNFTMarketBuyPrice} from "../market/DNFTMarketBuyPrice.sol";
import {DNFTMarketReserveAuction} from "../market/DNFTMarketReserveAuction.sol";
import {AdminRoleEnumerable} from "../market/AdminRoleEnumerable.sol";
import {OperatorRoleEnumerable} from "../market/OperatorRoleEnumerable.sol";


contract MarketPlaceV2 is
    Initializable,
    MarketPlaceStorage,
    DNFTMarketCore,
    DNFTMarketReserveAuction,    
    DNFTMarketBuyPrice,
    DNFTMarketOffer,
    IERC165,
    IERC3525Receiver,
    PausableUpgradeable,
    AdminRoleEnumerable,
    OperatorRoleEnumerable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 internal _additionalValue;

    // --- override --- //

    /**
     * @notice Returns id to assign to the next auction.
     */
    function _getNextAndIncrementAuctionId() internal virtual override returns (uint256) {
        _nextAuctionId.increment();
        return uint24(_nextAuctionId.current());
    }

    function _getWallet(uint256 soulBoundTokenId) internal virtual view override returns(address) {
        if (MODULE_GLOBALS == address(0)) revert Errors.ModuleGlobasNotSet();
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        return IERC3525(_sbt).ownerOf(soulBoundTokenId);
    }

    function _isCurrencyWhitelisted(address currency) internal virtual view override returns(bool) {
        if (MODULE_GLOBALS == address(0)) revert Errors.ModuleGlobasNotSet();
        return IModuleGlobals(MODULE_GLOBALS).isCurrencyWhitelisted(currency);
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
        uint256 tokenId,
        address recipient,
        address authorizeSeller
    ) internal override(DNFTMarketCore, DNFTMarketReserveAuction){
        // This is a no-op function required to avoid compile errors.
        super._transferFromEscrow(derivativeNFT, tokenId, recipient, authorizeSeller);
    }
 
    function _transferFromEscrowIfAvailable(
        address derivativeNFT,
        uint256 tokenId,
        address recipient
    ) internal override(DNFTMarketCore, DNFTMarketReserveAuction, DNFTMarketBuyPrice) {
        // This is a no-op function required to avoid compile errors.
        super._transferFromEscrowIfAvailable(derivativeNFT, tokenId, recipient);
    }

    function _transferToEscrow(address derivativeNFT, uint256 tokenId)
        internal
        override(DNFTMarketCore, DNFTMarketReserveAuction, DNFTMarketBuyPrice)
    {
        // This is a no-op function required to avoid compile errors.
        super._transferToEscrow(derivativeNFT, tokenId);
    }


    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    receive() external payable {
        emit Events.MarketPlaceDeposit(msg.sender, msg.value, address(this), address(this).balance);
    }

    fallback() external payable {
        emit Events.MarketPlaceDepositByFallback(msg.sender, msg.value, address(this), address(this).balance, msg.data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC3525Receiver).interfaceId;
    }

    /// @notice When DNFT tranfer to market contract, via `escrow`
    function onERC3525Received(
        address operator,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        if (!markets[msg.sender].isOpen) {
            revert Errors.Market_DNFT_Is_Not_Open(msg.sender);
        }
        
        if (value == 0) {
            revert Errors.Must_Escrow_Non_Zero_Amount();
        }

        emit Events.MarketPlaceERC3525Received(msg.sender, operator, fromTokenId, toTokenId, value, data, gasleft());
        return 0x009ce20b;
    }
    
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

    function addMarket(
        address derivativeNFT_,
        uint256 projectId_,
        address collectModule_,
        DataTypes.FeePayType feePayType_,
        DataTypes.FeeShareType feeShareType_,
        uint16 royaltySharesPoints_
    ) 
        external
        whenNotPaused   
        onlyOperator 
    {
        if (projectId_ == 0) revert Errors.InvalidParameter();
        if (_getMarketInfo(derivativeNFT_).projectId == projectId_) revert Errors.DerivativeNFTIsInMarket();

        markets[derivativeNFT_].isOpen = true;
        markets[derivativeNFT_].feePayType = DataTypes.FeePayType(feePayType_);
        markets[derivativeNFT_].feeShareType = DataTypes.FeeShareType(feeShareType_);
        markets[derivativeNFT_].royaltySharesPoints = royaltySharesPoints_;
        markets[derivativeNFT_].projectId = projectId_;
        markets[derivativeNFT_].collectModule = collectModule_;
        
        emit Events.AddMarket(
            derivativeNFT_,
            projectId_,
            feePayType_,
            feeShareType_,
            royaltySharesPoints_,
            collectModule_
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

        //V2

    function setAdditionalValue(uint256 newValue) external {
        _additionalValue = newValue;
    }

    function getAdditionalValue() external view returns (uint256) {
        return _additionalValue;
    }

    function version() external pure  returns (uint256) {
        return 2;
    }
}