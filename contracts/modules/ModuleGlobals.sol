// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';
import {IModuleGlobals} from '../interfaces/IModuleGlobals.sol';
import {INFTDerivativeProtocolTokenV1} from "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import {IManager} from "../interfaces/IManager.sol";

/**
 * @title ModuleGlobals
 * @author Bitsoul Protocol
 * 
 * @notice This contract contains data relevant to dNFT modules, such as the module governance address, treasury
 * address and treasury fee BPS.
 * 本合同包含与dNFT模块相关的数据，如模块管理地址、资金地址和国库费用税点BPS。
 *
 * NOTE: The reason we have an additional governance address instead of just fetching it from the manager is to
 * allow the flexibility of using different governance executors.
 * 我们之所以有一个额外的治理地址，而不是仅仅从中心获取它，是为了允许灵活使用不同的治理执行者。
 * 
 * 充当模块的中心数据提供者。它由一个特定的治理地址控制，与中心治理相比，
 * 该地址可以设置为不同的执行者。预计模块将获取动态变化的数据，例如模块全局治理地址、资金地址、资金费用以及白名单货币列表。
 */
contract ModuleGlobals is IModuleGlobals {
    uint16 internal constant BPS_MAX = 10000;
    mapping(address => bool) internal _currencyWhitelisted;
    address internal _MANAGER; //管理合约地址
    address internal _NDPT; //NDPT地址
    address internal _governance; //治理地址
    address internal _treasury; //金库地址
    uint16 internal _treasuryFee; //手续费率
    
    
    mapping(address => uint256) internal _publishCurrencyTaxes; //publish的币种及数量

    modifier onlyGov() {
        if (msg.sender != _governance) revert Errors.NotGovernance();
        _;
    }

    /**
     * @notice Initializes the governance, treasury and treasury fee amounts.
     *
     * @param manager The manager address
     * @param ndpt The ndpt address
     * @param governance The governance address which has additional control over setting certain parameters.
     * @param treasury The treasury address to direct fees to.
     * @param treasuryFee The treasury fee in BPS to levy on collects.
     * @param publishRoyalty The fee when every dNFT publish or combo, count one is free

     */
    constructor(
        address manager,
        address ndpt,
        address governance,
        address treasury,
        uint16 treasuryFee,
        uint256 publishRoyalty
    ) {
        _setGovernance(governance);
        _setTreasury(treasury);
        _setTreasuryFee(treasuryFee);
        _setPublishRoyalty(publishRoyalty);
        _publishCurrencyTaxes[ndpt] = publishRoyalty;
        _whitelistCurrency(ndpt, true);
        _setManager(manager);
        _setNDPT(ndpt);
    } 

    function setManager(address newManager) external override onlyGov {
        _setManager(newManager);
    }

    function setNDPT(address newNDPT) external override onlyGov {
        _setNDPT(newNDPT);
    }

    /// @inheritdoc IModuleGlobals
    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    /// @inheritdoc IModuleGlobals
    function setTreasury(address newTreasury) external override onlyGov {
        _setTreasury(newTreasury);
    }

    /// @inheritdoc IModuleGlobals
    function setTreasuryFee(uint16 newTreasuryFee) external override onlyGov {
        _setTreasuryFee(newTreasuryFee);
    }

    /// @inheritdoc IModuleGlobals
    function whitelistCurrency(address currency, bool toWhitelist) external override onlyGov {
        _whitelistCurrency(currency, toWhitelist);
    }

    /// @inheritdoc IModuleGlobals
    function isCurrencyWhitelisted(address currency) external view override returns (bool) {
        return _currencyWhitelisted[currency];
    }

    /// @inheritdoc IModuleGlobals
    function getGovernance() external view override returns (address) {
        return _governance;
    }

    /// @inheritdoc IModuleGlobals
    function getTreasury() external view override returns (address) {
        return _treasury;
    }
    
    /// @inheritdoc IModuleGlobals
    function getNDPT() external view override returns (address) {
        return _NDPT;

    }
    
    /// @inheritdoc IModuleGlobals
    function getTreasuryFee() external view override returns (uint16) {
        return _treasuryFee;
    }

    //@inheritdoc IModuleGlobals
    function getTreasuryData() external view override returns (address, uint16) {
        return (_treasury, _treasuryFee);
    }

    function getWallet(uint256 soulBoundTokenId) external view returns (address) {
        return IManager(_MANAGER).getWalletBySoulBoundTokenId(soulBoundTokenId);
    }

    function _setGovernance(address newGovernance) internal {
        if (newGovernance == address(0)) revert Errors.InitParamsInvalid();
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.ModuleGlobalsGovernanceSet(prevGovernance, newGovernance, block.timestamp);
    }

    function _setTreasury(address newTreasury) internal {
        if (newTreasury == address(0)) revert Errors.InitParamsInvalid();
        address prevTreasury = _treasury;
        _treasury = newTreasury;
        emit Events.ModuleGlobalsTreasurySet(prevTreasury, newTreasury, block.timestamp);
    }

    function _setManager(address newManager) internal {
        if (newManager == address(0)) revert Errors.InitParamsInvalid();
        address prevManager = _MANAGER;
        _MANAGER = newManager;
        emit Events.ModuleGlobalsManagerSet(prevManager, newManager, block.timestamp);
    }

    function _setNDPT(address newNDPT) internal {
        if (newNDPT == address(0)) revert Errors.InitParamsInvalid();
        address prevNDPT = _NDPT;
        _NDPT = newNDPT;
        emit Events.ModuleGlobalsNDPTSet(prevNDPT, newNDPT, block.timestamp);
    }

    function _setPublishRoyalty(uint256 publishRoyalty) internal {
        uint256 prevPublishRoyalty = _publishCurrencyTaxes[_NDPT];
        _publishCurrencyTaxes[_NDPT] = publishRoyalty;
        emit Events.ModuleGlobalsPublishRoyaltySet(prevPublishRoyalty, publishRoyalty, block.timestamp);
    }

    function _setTreasuryFee(uint16 newTreasuryFee) internal {
        if (newTreasuryFee >= BPS_MAX / 2) revert Errors.InitParamsInvalid();
        uint16 prevTreasuryFee = _treasuryFee;
        _treasuryFee = newTreasuryFee;
        emit Events.ModuleGlobalsTreasuryFeeSet(prevTreasuryFee, newTreasuryFee, block.timestamp);
    }

    function _whitelistCurrency(address currency, bool toWhitelist) internal {
        if (currency == address(0)) revert Errors.InitParamsInvalid();
        bool prevWhitelisted = _currencyWhitelisted[currency];
        _currencyWhitelisted[currency] = toWhitelist;
        emit Events.ModuleGlobalsCurrencyWhitelisted(
            currency,
            prevWhitelisted,
            toWhitelist,
            block.timestamp
        );
    }

    function setPublishRoyalty(uint256 publishRoyalty) external onlyGov override {
        _setPublishRoyalty(publishRoyalty);
    }

    function getPublishCurrencyTax(address currency) external view override returns(uint256) {
       return _publishCurrencyTaxes[currency];
    }
    
}
