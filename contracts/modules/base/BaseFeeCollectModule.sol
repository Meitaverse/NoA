// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Errors} from '../../libraries/Errors.sol';
import {FeeModuleBase} from '../FeeModuleBase.sol';
import {ModuleBase} from "../ModuleBase.sol";
import {ICollectModule} from '../../interfaces/ICollectModule.sol';
import {ModuleBase} from '../ModuleBase.sol';
import {IBankTreasury} from "../../interfaces/IBankTreasury.sol";

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
// import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {INFTDerivativeProtocolTokenV1} from "../../interfaces/INFTDerivativeProtocolTokenV1.sol";

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {BaseFeeCollectModuleInitData, BaseProfilePublicationData, IBaseFeeCollectModule} from './IBaseFeeCollectModule.sol';

/**
 * @title BaseFeeCollectModule
 * @author Lens Protocol
 *
 * @notice This is an base Lens CollectModule implementation, allowing customization of time to collect, number of collects
 * and whether only followers can collect, charging a fee for collect and distributing it among Receiver/Referral/Treasury.
 * @dev Here we use "Base" terminology to anything that represents this base functionality (base structs, base functions, base storage).
 * @dev You can build your own collect modules on top of the "Base" by inheriting this contract and overriding functions.
 * @dev This contract is marked "abstract" as it requires you to implement initializePublicationCollectModule and getPublicationData functions when you inherit from it.
 * @dev See BaseFeeCollectModule as an example implementation.
 */
abstract contract BaseFeeCollectModule is
    FeeModuleBase,
    ModuleBase,
    IBaseFeeCollectModule
{
    using SafeERC20 for IERC20;

    mapping(uint256 => mapping(uint256 => BaseProfilePublicationData))
        internal _dataByPublicationByProfile;

    constructor(address hub, address moduleGlobals) ModuleBase(hub) FeeModuleBase(moduleGlobals) {}
 
    /**
     * @dev Processes a collect by:
     *  1. Validating that collect action meets all needded criteria
     *  2. Processing the collect action either with or withour referral
     *
     */
    function processCollect(
        uint256 ownershipSoulBoundTokenId,
        uint256 collectorSoulBoundTokenId,
        uint256 publishId,
        uint256 collectValue,     
        bytes calldata data
    ) external virtual onlyManager {
        _validateAndStoreCollect(collectorSoulBoundTokenId, ownershipSoulBoundTokenId, publishId, collectValue, data);

        _processCollect(collectorSoulBoundTokenId, ownershipSoulBoundTokenId, publishId, collectValue, data);
    }

    // This function is not implemented because each Collect module has its own return data type
    // function getPublicationData(uint256 ownershipSoulBoundTokenId, uint256 publishId) external view returns (.....) {}

    /**
     * @notice Returns the Base publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param ownershipSoulBoundTokenId The token ID of the profile mapped to the publication to query.
     * @param publishId The publication ID of the publication to query.
     *
     * @return The BaseProfilePublicationData struct mapped to that publication.
     */
    function getBasePublicationData(uint256 ownershipSoulBoundTokenId, uint256 publishId)
        public
        view
        virtual
        returns (BaseProfilePublicationData memory)
    {
        return _dataByPublicationByProfile[ownershipSoulBoundTokenId][publishId];
    }

    /**
     * @notice Calculates and returns the collect fee of a publication.
     * @dev Override this function to use a different formula for the fee.
     *
     * @param ownershipSoulBoundTokenId The token ID of the profile mapped to the publication to query.
     * @param publishId The publication ID of the publication to query.
     * @param data Any additional params needed to calculate the fee.
     *
     * @return The collect fee of the specified publication.
     */
    function calculateFee(
        uint256 ownershipSoulBoundTokenId,
        uint256 publishId,
        bytes calldata data
    ) public view virtual returns (uint256) {
        //TODO
        return _dataByPublicationByProfile[ownershipSoulBoundTokenId][publishId].salePrice;
    }

    /**
     * @dev Validates the Base parameters like:
     * 1) Is the currency whitelisted
     * 2) Is the referralFee in valid range
     * 3) Is the end of collects timestamp in valid range
     *
     * This should be called during initializePublicationCollectModule()
     *
     * @param baseInitData Module initialization data (see BaseFeeCollectModuleInitData struct)
     */
    function _validateBaseInitData(BaseFeeCollectModuleInitData memory baseInitData)
        internal
        virtual
    {
        if (
            !_currencyWhitelisted(baseInitData.currency) ||
            (baseInitData.endTimestamp != 0 && baseInitData.endTimestamp < block.timestamp)
        ) revert Errors.InitParamsInvalid();

    }

    /**
     * @dev Stores the initial module parameters
     *
     * This should be called during initializePublicationCollectModule()
     *
     * @param ownershipSoulBoundTokenId The token ID of the profile publishing the publication.
     * @param publishId The publication ID.
     * @param baseInitData Module initialization data (see BaseFeeCollectModuleInitData struct)
     */
    function _storeBasePublicationCollectParameters(
        uint256 tokenId,
        uint256 amount,
        uint256 ownershipSoulBoundTokenId,
        uint256 publishId,
        BaseFeeCollectModuleInitData memory baseInitData
    ) internal virtual {
        _dataByPublicationByProfile[ownershipSoulBoundTokenId][publishId].tokenId = tokenId;
        _dataByPublicationByProfile[ownershipSoulBoundTokenId][publishId].amount = amount;
        _dataByPublicationByProfile[ownershipSoulBoundTokenId][publishId].salePrice = baseInitData.salePrice;
        _dataByPublicationByProfile[ownershipSoulBoundTokenId][publishId].currency = baseInitData.currency;
        _dataByPublicationByProfile[ownershipSoulBoundTokenId][publishId].recipientSoulBoundTokenId = baseInitData.recipientSoulBoundTokenId;
        _dataByPublicationByProfile[ownershipSoulBoundTokenId][publishId].endTimestamp =     baseInitData.endTimestamp;
    }

    /**
     * @dev Validates the collect action by checking that:
     * 1) the collector is a follower (if enabled)
     * 2) the number of collects after the action doesn't surpass the collect limit (if enabled)
     * 3) the current block timestamp doesn't surpass the end timestamp (if enabled)
     *
     * This should be called during processCollect()
     *
     * @param ownershipSoulBoundTokenId The collector soulBoundTokenId.
     * @param ownershipSoulBoundTokenId The token ID of the profile associated with the publication being collected.
     * @param publishId The LensHub publication ID associated with the publication being collected.
     * @param data Arbitrary data __passed from the collector!__ to be decoded.
     */
    function _validateAndStoreCollect(
        uint256 collectorSoulBoundTokenId,
        uint256 ownershipSoulBoundTokenId,
        uint256 publishId,
        uint256 collectValue,
        bytes calldata data
    ) internal virtual {

        uint256 endTimestamp = _dataByPublicationByProfile[ownershipSoulBoundTokenId][publishId].endTimestamp;

         if (collectorSoulBoundTokenId == 0 || 
            ownershipSoulBoundTokenId == 0 || 
            collectValue == 0 || 
            publishId ==0 ) revert Errors.InitParamsInvalid();


        if (endTimestamp != 0 && block.timestamp > endTimestamp) {
            revert Errors.CollectExpired(); 
        }
    }

    /**
     * @dev Internal processing of a collect:
     *  1. Calculation of fees
     *  2. Validation that fees are what collector expected
     *  3. Transfer of fees to recipientSoulBoundTokenId(-s) and treasury
     *
     * @param collectorSoulBoundTokenId The token ID  that will collect the post.
     * @param ownershipSoulBoundTokenId The token ID of the profile associated with the publication being collected.
     * @param publishId The LensHub publication ID associated with the publication being collected.
     * @param data Arbitrary data __passed from the collector!__ to be decoded.
     */
    function _processCollect(
        uint256 collectorSoulBoundTokenId,
        uint256 ownershipSoulBoundTokenId,
        uint256 publishId,
        uint256 collectValue,
        bytes calldata data
    ) internal virtual {
        uint256 payFees = collectValue * calculateFee(ownershipSoulBoundTokenId, publishId, data);
        address currency = _dataByPublicationByProfile[ownershipSoulBoundTokenId][publishId].currency;

        //社区金库地址及税点
        (address treasury, uint16 treasuryFee) = _treasuryData();
        uint256 treasuryAmount = (payFees * treasuryFee) / BPS_MAX;
        uint256 treasuryOfSoulBoundTokenId = IBankTreasury(treasury).getSoulBoundTokenId();
        if (treasuryAmount > 0) 
            INFTDerivativeProtocolTokenV1(_ndpt()).transferValue(
                collectorSoulBoundTokenId, 
                treasuryOfSoulBoundTokenId, 
                treasuryAmount);
            

        // Send amount after treasury cut, to all recipients
        _transferToRecipients(currency, collectorSoulBoundTokenId, ownershipSoulBoundTokenId, publishId, payFees - treasuryAmount);

    }

    /**
     * @dev Tranfers the fee to recipientSoulBoundTokenId(-s)
     *
     * Override this to add additional functionality (e.g. multiple recipientSoulBoundTokenIds)
     *
     * @param currency Currency of the transaction
     * @param collectorSoulBoundTokenId The token ID that collects the post (and pays the fee).
     * @param ownershipSoulBoundTokenId The token ID of the profile associated with the publication being collected.
     * @param publishId The LensHub publication ID associated with the publication being collected.
     * @param salePrice salePrice
     */
    function _transferToRecipients(
        address currency,
        uint256 collectorSoulBoundTokenId,
        uint256 ownershipSoulBoundTokenId,
        uint256 publishId,
        uint256 salePrice
    ) internal virtual {
        uint256 recipientSoulBoundTokenId = _dataByPublicationByProfile[ownershipSoulBoundTokenId][publishId].recipientSoulBoundTokenId;

        if (salePrice > 0)
            INFTDerivativeProtocolTokenV1(_ndpt()).transferValue(collectorSoulBoundTokenId, recipientSoulBoundTokenId, salePrice);
    }
}

