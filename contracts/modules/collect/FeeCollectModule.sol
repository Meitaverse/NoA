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
 * @param recipient The recipient address associated with this publication.
 * @param referralFee The referral fee associated with this publication.
 * @param followerOnly Whether only followers should be able to collect.
 */
struct ProfilePublicationData {
    uint256 amount;
    address currency;
    address recipient;
    uint16 referralFee;
    bool followerOnly;
    //TODO value 
    //TODO SoulBoundToken reputation 
}

/**
 * @title FeeCollectModule
 * @author Derivative NFT Protocol
 *
 * @notice This is a simple dNFT CollectModule implementation, inheriting from the ICollectModule interface and
 * the FeeCollectModuleBase abstract contract.
 *
 * This module works by allowing unlimited collects for a publication at a given price.
 */
contract FeeCollectModule is FeeModuleBase, FollowValidationModuleBase, ICollectModule {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(uint256 => mapping(uint256 => ProfilePublicationData)) internal _dataByPublicationByProfile;

    constructor(address manager, address moduleGlobals) FeeModuleBase(moduleGlobals) ModuleBase(manager) {}

    // constructor(address moduleGlobals) override(FeeModuleBase, ModuleBase) {}

    /**
     * @notice Initializes data for a given publication being published. This can only be called by the manager.
     *
     * @param soulBoundTokenId The token ID of the SoulBoundToken publishing the publication.
     * @param tokenId The associated publication's Noa publication token ID.
     * @param value Value of the associated publications.
     * @param data Arbitrary data __passed from the user!__ to be decoded.
     *
     * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
     * manager alongside the collect module's address and should be consumed by front ends.
     */
    function initializePublicationCollectModule(
        uint256 soulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external override onlyManager returns (bytes memory) {
        //解码出费率的相关传参
        (uint256 amount, address currency, address recipient, uint16 referralFee, bool followerOnly) = abi.decode(
            data,
            (uint256, address, address, uint16, bool)
        );
        if (!_currencyWhitelisted(currency) || recipient == address(0) || referralFee > BPS_MAX || amount == 0)
            revert Errors.InitParamsInvalid();

        //TODO
        _dataByPublicationByProfile[soulBoundTokenId][tokenId].amount = amount;
        _dataByPublicationByProfile[soulBoundTokenId][tokenId].currency = currency;
        _dataByPublicationByProfile[soulBoundTokenId][tokenId].recipient = recipient;
        _dataByPublicationByProfile[soulBoundTokenId][tokenId].referralFee = referralFee;
        _dataByPublicationByProfile[soulBoundTokenId][tokenId].followerOnly = followerOnly;

        return data;
    }

    /**
     * @dev Processes a collect by:
     *  1. Ensuring the collector is a follower
     *  2. Charging a fee
     */
    function processCollect(
        uint256 referrerSoulBoundTokenId,
        address collector,
        uint256 soulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external virtual override onlyManager {
        // TODO
        if (_dataByPublicationByProfile[soulBoundTokenId][tokenId].followerOnly) _checkFollowValidity(soulBoundTokenId, collector);
        if (referrerSoulBoundTokenId == soulBoundTokenId) {
            _processCollect(collector, soulBoundTokenId, tokenId, data);
        } else {
            // _processCollectWithReferral(referrerSoulBoundTokenId, collector, soulBoundTokenId, tokenId, data);
        }
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param profileId The token ID of the profile mapped to the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return ProfilePublicationData The ProfilePublicationData struct mapped to that publication.
     */
    function getPublicationData(
        uint256 profileId,
        uint256 pubId
    ) external view returns (ProfilePublicationData memory) {
        return _dataByPublicationByProfile[profileId][pubId];
    }

    function _processCollect(address collector, uint256 profileId, uint256 pubId, bytes calldata data) internal {
        uint256 amount = _dataByPublicationByProfile[profileId][pubId].amount;
        address currency = _dataByPublicationByProfile[profileId][pubId].currency;
        _validateDataIsExpected(data, currency, amount);

        (address treasury, uint16 treasuryFee) = _treasuryData();
        address recipient = _dataByPublicationByProfile[profileId][pubId].recipient;
        uint256 treasuryAmount = (amount * treasuryFee) / BPS_MAX;
        uint256 adjustedAmount = amount - treasuryAmount;

        //向recipient支付剩余的currency
        IERC20Upgradeable(currency).safeTransferFrom(collector, recipient, adjustedAmount);

        //如果支付给金库的数量大于0
        if (treasuryAmount > 0) IERC20Upgradeable(currency).safeTransferFrom(collector, treasury, treasuryAmount);
    }

    function _processCollectWithReferral(
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) internal {
        uint256 amount = _dataByPublicationByProfile[profileId][pubId].amount;
        address currency = _dataByPublicationByProfile[profileId][pubId].currency;
        _validateDataIsExpected(data, currency, amount);

        uint256 referralFee = _dataByPublicationByProfile[profileId][pubId].referralFee;
        address treasury;
        uint256 treasuryAmount;

        // Avoids stack too deep
        {
            uint16 treasuryFee;
            (treasury, treasuryFee) = _treasuryData();
            treasuryAmount = (amount * treasuryFee) / BPS_MAX;
        }

        uint256 adjustedAmount = amount - treasuryAmount;

        if (referralFee != 0) {
            // The reason we levy the referral fee on the adjusted amount is so that referral fees
            // don"t bypass the treasury fee, in essence referrals pay their fair share to the treasury.
            uint256 referralAmount = (adjustedAmount * referralFee) / BPS_MAX;
            adjustedAmount = adjustedAmount - referralAmount;

            //TODO

            // address referralRecipient = IERC721(HUB).ownerOf(referrerProfileId);

            // IERC20Upgradeable(currency).safeTransferFrom(collector, referralRecipient, referralAmount);
        }
        address recipient = _dataByPublicationByProfile[profileId][pubId].recipient;

        IERC20Upgradeable(currency).safeTransferFrom(collector, recipient, adjustedAmount);
        if (treasuryAmount > 0) IERC20Upgradeable(currency).safeTransferFrom(collector, treasury, treasuryAmount);
    }
}
