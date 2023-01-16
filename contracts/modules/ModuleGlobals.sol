// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';
import {IModuleGlobals} from '../interfaces/IModuleGlobals.sol';
import {INFTDerivativeProtocolTokenV1} from "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import {IManager} from "../interfaces/IManager.sol";
import {GlobalStorage} from "../storage/GlobalStorage.sol";

/**
 * @title ModuleGlobals
 * @author Bitsoul Protocol
 * 
 * @notice This contract contains data relevant to dNFT modules, such as the module governance address, treasury
 * address and treasury fee BPS.
 *
 * NOTE: The reason we have an additional governance address instead of just fetching it from the manager is to
 * allow the flexibility of using different governance executors.
 * 
 */
contract ModuleGlobals is IModuleGlobals, GlobalStorage {
    uint16 internal constant BPS_MAX = 10000;

    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    /**
     * @notice Initializes the governance, treasury and treasury fee amounts.
     *
     * @param manager The manager address
     * @param sbt The sbt address
     * @param governance The governance address which has additional control over setting certain parameters.
     * @param treasury The treasury address to direct fees to.
     * @param voucher The voucher(ERC1155) address 
     * @param treasuryFee The treasury fee in BPS to levy on collects.
     * @param publishRoyalty The fee when every dNFT publish or combo, count one is free

     */
    constructor(
        address manager,
        address sbt,
        address governance,
        address treasury,
        address voucher,
        uint16 treasuryFee,
        uint256 publishRoyalty
    ) {
        _setManager(manager);
        _setSBT(sbt);
        _setGovernance(governance);
        _setTreasury(treasury);
        _setVoucher(voucher);
        _setTreasuryFee(treasuryFee);
        _setPublishRoyalty(publishRoyalty);
    }

    function setManager(address newManager) external override onlyGov {
        _setManager(newManager);
    }

    function setSBT(address newSBT) external override onlyGov {
        _setSBT(newSBT);
    }

    /// @inheritdoc IModuleGlobals
    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    /// @inheritdoc IModuleGlobals
    function setTreasury(address newTreasury) external override onlyGov {
        _setTreasury(newTreasury);
    }

    function setVoucher(address newVoucher) external override onlyGov {
        _setVoucher(newVoucher);
    }
    
    function getVoucher() external view override returns (address) {
        return _voucher;
    }

    /// @inheritdoc IModuleGlobals
    function setTreasuryFee(uint16 newTreasuryFee) external override onlyGov {
        _setTreasuryFee(newTreasuryFee);
    }

    /// @inheritdoc IModuleGlobals
    function getManager() external view override returns (address) {
        return _manager;
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
    function getSBT() external view override returns (address) {
        return _sbt;
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
        return IManager(_manager).getWalletBySoulBoundTokenId(soulBoundTokenId);
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

    function _setVoucher(address newVoucher) internal {
        if (newVoucher == address(0)) revert Errors.InitParamsInvalid();
        address prevVoucher = _voucher;
        _voucher = newVoucher;
        emit Events.ModuleGlobalsVoucherSet(prevVoucher, newVoucher, block.timestamp);
    }

    function _setManager(address newManager) internal {
        if (newManager == address(0)) revert Errors.InitParamsInvalid();
        address prevManager = _manager;
        _manager = newManager;
        emit Events.ModuleGlobalsManagerSet(prevManager, newManager, block.timestamp);
    }

    function _setSBT(address newSBT) internal {
        if (newSBT == address(0)) revert Errors.InitParamsInvalid();
        address prevSBT = _sbt;
        _sbt = newSBT;
        emit Events.ModuleGlobalsSBTSet(prevSBT, newSBT, block.timestamp);
    }

    function _setPublishRoyalty(uint256 publishRoyalty) internal {
        uint256 prevPublishRoyalty = _publishCurrencyTaxes[_sbt];
        _publishCurrencyTaxes[_sbt] = publishRoyalty;
        emit Events.ModuleGlobalsPublishRoyaltySet(prevPublishRoyalty, publishRoyalty, block.timestamp);
    }

    function _setTreasuryFee(uint16 newTreasuryFee) internal {
        if (newTreasuryFee >= BPS_MAX / 2) revert Errors.InitParamsInvalid();
        uint16 prevTreasuryFee = _treasuryFee;
        _treasuryFee = newTreasuryFee;
        emit Events.ModuleGlobalsTreasuryFeeSet(prevTreasuryFee, newTreasuryFee, block.timestamp);
    }

    function setPublishRoyalty(uint256 publishRoyalty) external override onlyGov {
        _setPublishRoyalty(publishRoyalty);
    }

    function getPublishCurrencyTax() external view override returns (uint256) {
        return _publishCurrencyTaxes[_sbt];
    }

    function whitelistProfileCreator(address profileCreator, bool whitelist) external override onlyGov {
        _profileCreatorWhitelisted[profileCreator] = whitelist;
        emit Events.ProfileCreatorWhitelisted(profileCreator, whitelist, msg.sender, block.timestamp);
    }

    function isWhitelistProfileCreator(address profileCreator) external view override returns (bool) {
        return _profileCreatorWhitelisted[profileCreator];
    }

    function whitelistHubCreator(uint256 soulBoundTokenId, bool whitelist) external override onlyGov {
        _hubCreatorWhitelisted[soulBoundTokenId] = whitelist;
        emit Events.HubCreatorWhitelisted(soulBoundTokenId, whitelist, msg.sender, block.timestamp);
    }

    function isWhitelistHubCreator(uint256 soulBoundTokenId) external view override returns (bool) {
        return _hubCreatorWhitelisted[soulBoundTokenId];
    }

    function whitelistCollectModule(address collectModule, bool whitelist) external override onlyGov {
        _collectModuleWhitelisted[collectModule] = whitelist;
        emit Events.CollectModuleWhitelisted(collectModule, whitelist, block.timestamp);
    }

    function isWhitelistCollectModule(address collectModule) external view returns (bool) {
        return _collectModuleWhitelisted[collectModule];
    }

    function whitelistPublishModule(address publishModule, bool whitelist) external override onlyGov {
        _publishModuleWhitelisted[publishModule] = whitelist;
        emit Events.PublishModuleWhitelisted(publishModule, whitelist, block.timestamp);
    }

    function isWhitelistPublishModule(address publishModule) external view returns (bool) {
        return _publishModuleWhitelisted[publishModule];
    }

    function whitelistTemplate(address template, bool whitelist) external override onlyGov {
        _templateWhitelisted[template] = whitelist;
        emit Events.TemplateWhitelisted(template, whitelist, block.timestamp);
    }

    function isWhitelistTemplate(address template) external view returns (bool) {
        return _templateWhitelisted[template];
    }
    
    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }

}
