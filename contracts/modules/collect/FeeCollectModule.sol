// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ICollectModule} from "../../interfaces/ICollectModule.sol";
import {Errors} from "../../libraries/Errors.sol";
import {FeeModuleBase} from "../FeeModuleBase.sol";
import {ModuleBase} from "../ModuleBase.sol";
import {FollowValidationModuleBase} from "../FollowValidationModuleBase.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 *
 * @param amount The collecting cost associated with this publication.
 * @param currency The currency associated with this publication.
 * @param toSoulBoundTokenId The toSoulBoundTokenId associated with this publication.
 * @param referralFee The referral fee associated with this publication.
 * @param followerOnly Whether only followers should be able to collect.
 */
struct ProfilePublicationData {
    uint256 amount;
    address currency;
    uint256 genesisSoulBoundTokenId;
    uint256 ownerSoulBoundTokenId;
    uint256 collectorSoulBoundTokenId;
    uint16 referralFee; //介绍费
    // bool followerOnly;
    //TODO value 
    //TODO SoulBoundToken reputation 
}

/**
 * @title FeeCollectModule
 * @author Bitsoul Protocol
 *
 * @notice This is a simple dNFT CollectModule implementation, inheriting from the ICollectModule interface and
 * the FeeCollectModuleBase abstract contract.
 *
 * This module works by allowing unlimited collects for a publication at a given price.
 */
contract FeeCollectModule is FeeModuleBase, FollowValidationModuleBase, ICollectModule {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // projectId => tokenId => ProfilePublicationData
    mapping(uint256 => mapping(uint256 => ProfilePublicationData)) internal _dataByPublicationByProfile;

    constructor(address manager, address moduleGlobals) FeeModuleBase(moduleGlobals) ModuleBase(manager) {}

    // constructor(address moduleGlobals) override(FeeModuleBase, ModuleBase) {}

    function initializePublicationCollectModule(
        uint256 genesisSoulBoundTokenId,
        uint256 ownerSoulBoundTokenId,
        uint256 projectId,
        uint256 tokenId,
        uint256 value,
        bytes calldata data 
    ) external override onlyManager returns (bytes memory) {
        //解码出费率的相关传参
        // (uint256 amount, address currency, address recipient, uint16 referralFee, bool followerOnly) = abi.decode(
        //     data,
        //     (uint256, address, address, uint16, bool)
        // );
        // if (!_currencyWhitelisted(currency) || recipient == address(0) || referralFee > BPS_MAX || amount == 0)
        //     revert Errors.InitParamsInvalid();

  
        //TODO
        // _dataByPublicationByProfile[projectId][tokenId].amount = amount;
        // _dataByPublicationByProfile[projectId][tokenId].currency = currency;
        _dataByPublicationByProfile[projectId][tokenId].genesisSoulBoundTokenId = genesisSoulBoundTokenId;
        _dataByPublicationByProfile[projectId][tokenId].ownerSoulBoundTokenId = ownerSoulBoundTokenId;
        // _dataByPublicationByProfile[projectId][tokenId].referralFee = referralFee;
        // // _dataByPublicationByProfile[projectId][tokenId].followerOnly = followerOnly;

        return data;
    }

    /**
     * @dev Processes a collect by:
     *  1. genesisSoulBoundTokenId is the genesis SBT id, will pay royalty to
     *  2. Charging a fee
     */
    function processCollect(
        uint256 ownerSoulBoundTokenId,
        uint256 collectorSoulBoundTokenId,
        uint256 projectId,
        uint256 tokenId,
        uint256 value,
        bytes calldata data 
    ) external virtual override onlyManager {
        _processCollect(collectorSoulBoundTokenId, projectId, tokenId, data);
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param projectId The token ID of the profile mapped to the publication to query.
     * @param tokenId The token id to query.
     *
     * @return ProfilePublicationData The ProfilePublicationData struct mapped to that publication.
     */
    function getPublicationData(
        uint256 projectId,
        uint256 tokenId
    ) external view returns (ProfilePublicationData memory) {
        return _dataByPublicationByProfile[projectId][tokenId];
    }

    function _processCollect(
        uint256 collectorSoulBoundTokenId,
        uint256 projectId, 
        uint256 tokenId, 
        bytes calldata data
    ) internal {
        uint256 amount = _dataByPublicationByProfile[projectId][tokenId].amount;
        address currency = _dataByPublicationByProfile[projectId][tokenId].currency;
        _validateDataIsExpected(data, currency, amount);

        //获取交易税点
        (address treasury, uint16 treasuryFee) = _treasuryData();
        // uint256 toSoulBoundTokenId = _dataByPublicationByProfile[projectId][tokenId].toSoulBoundTokenId;
        uint256 ownerSoulBoundTokenId = _dataByPublicationByProfile[projectId][tokenId].ownerSoulBoundTokenId;
        uint256 treasuryAmount = (amount * treasuryFee) / BPS_MAX;
        uint256 adjustedAmount = amount - treasuryAmount;
        
        address incubatorofCollector = _incubator(collectorSoulBoundTokenId);
        
        address incubatorofOwner = _incubator(ownerSoulBoundTokenId);


        //向recipient支付剩余的currency
        IERC20Upgradeable(currency).safeTransferFrom(incubatorofCollector, incubatorofOwner, adjustedAmount);

        //支付给金库
        if (treasuryAmount > 0) IERC20Upgradeable(currency).safeTransferFrom(incubatorofCollector, treasury, treasuryAmount);
    }
}
