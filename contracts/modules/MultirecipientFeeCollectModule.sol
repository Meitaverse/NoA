// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Errors} from '../libraries/Errors.sol';
import {BaseFeeCollectModule} from './base/BaseFeeCollectModule.sol';
import {BaseProfilePublicationData, BaseFeeCollectModuleInitData} from './base/IBaseFeeCollectModule.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {INFTDerivativeProtocolTokenV1} from "../interfaces/INFTDerivativeProtocolTokenV1.sol";

struct RecipientData {
    uint256 recipientSoulBoundTokenId;
    uint16 split; // fraction of BPS_MAX (10 000)
}

/**
 * @notice A struct containing the necessary data to initialize MultirecipientFeeCollectModule.
 *
 * @param salePrice The collecting cost associated with this publication. Cannot be 0.
 * @param currency The currency associated with this publication.
 * @param endTimestamp The end timestamp after which collecting is impossible. 0 for no expiry.
 * @param recipients Array of RecipientData items to split collect fees across multiple recipients.
 */
struct MultirecipientFeeCollectModuleInitData {
    uint256 salePrice;
    address currency;
    uint72 endTimestamp;
    RecipientData[] recipients;
}

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 *
 * @param salePrice The collecting cost associated with this publication. Cannot be 0.
 * @param currency The currency associated with this publication.
 * @param endTimestamp The end timestamp after which collecting is impossible. 0 for no expiry.
 * @param recipients Array of RecipientData items to split collect fees across multiple recipients.
 */
struct MultirecipientFeeCollectProfilePublicationData {
    uint256 tokenId;
    uint256 amount;
    uint256 salePrice;
    address currency;
    uint72 endTimestamp;
    RecipientData[] recipients;
}

error TooManyRecipients();
error InvalidRecipientSplits();
error RecipientSplitCannotBeZero();

/**
 * @title MultirecipientCollectModule
 * @author Lens Protocol
 *
 * @notice This is a simple Lens CollectModule implementation, allowing customization of time to collect, number of collects,
 * splitting collect fee across multiple recipients, and whether only followers can collect.
 * It is charging a fee for collect and distributing it among (one or up to five) Receivers, Referral, Treasury.
 */
contract MultirecipientFeeCollectModule is BaseFeeCollectModule {
    using SafeERC20 for IERC20;

    uint256 internal constant MAX_RECIPIENTS = 5;

    mapping(uint256 => mapping(uint256 => RecipientData[]))
        internal _recipientsByPublicationByProfile;

    constructor(address hub, address moduleGlobals) BaseFeeCollectModule(hub, moduleGlobals) {}

    /**
     * @inheritdoc ICollectModule
     */
    function initializePublicationCollectModule(
        uint256 publishId,
        uint256 ownershipSoulBoundTokenId,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data        
    ) external override onlyManager returns (bytes memory) {
        MultirecipientFeeCollectModuleInitData memory initData = abi.decode(
            data,
            (MultirecipientFeeCollectModuleInitData)
        );

        if (initData.currency == address(0)) {
            initData.currency= _ndpt();
        } 


        BaseFeeCollectModuleInitData memory baseInitData = BaseFeeCollectModuleInitData({
            tokenId: tokenId,
            salePrice: initData.salePrice, 
            amount: amount, 
            currency: initData.currency,
            endTimestamp: initData.endTimestamp,
            recipientSoulBoundTokenId: 0
        });


        // Zero amount for collect doesn't make sense here (in a module with 5 recipients)
        // For this better use FreeCollect module instead
        if (baseInitData.amount == 0) revert Errors.InitParamsInvalid();
        if (ownershipSoulBoundTokenId == 0) revert Errors.InitParamsInvalid();
        _validateBaseInitData(baseInitData);
        _validateAndStoreRecipients(initData.recipients, ownershipSoulBoundTokenId, publishId);
        _storeBasePublicationCollectParameters(tokenId, amount, ownershipSoulBoundTokenId, publishId, baseInitData);
        return data;
    }

    /**
     * @dev Validates the recipients array and stores them to (a separate from Base) storage.
     *
     * @param recipients An array of recipients
     * @param ownershipSoulBoundTokenId The profile ID who is publishing the publication.
     * @param publishId The associated publication's LensHub publication ID.
     */
    function _validateAndStoreRecipients(
        RecipientData[] memory recipients,
        uint256 ownershipSoulBoundTokenId,
        uint256 publishId
    ) internal {
        uint256 len = recipients.length;

        // Check number of recipients is supported
        if (len > MAX_RECIPIENTS) revert TooManyRecipients();
        if (len == 0) revert Errors.InitParamsInvalid();

        // Check recipient splits sum to 10 000 BPS (100%)
        uint256 totalSplits;
        for (uint256 i = 0; i < len; ) {
            totalSplits += recipients[i].split;

            // Store each recipientSoulBoundTokenId while looping - avoids extra gas costs in successful cases
            _recipientsByPublicationByProfile[ownershipSoulBoundTokenId][publishId].push(recipients[i]);

            unchecked {
                ++i;
            }
        }

        if (totalSplits != BPS_MAX/2) revert InvalidRecipientSplits();
    
    }

    /**
     * @dev Transfers the fee to multiple recipients.
     *
     * @inheritdoc BaseFeeCollectModule
     */
    function _transferToRecipients(
        address currency,
        uint256 collectorSoulBoundTokenId,
        uint256 ownershipSoulBoundTokenId,
        uint256 publishId,
        uint256 saleprice
    ) internal override {
        RecipientData[] memory recipients = _recipientsByPublicationByProfile[ownershipSoulBoundTokenId][publishId];
        uint256 len = recipients.length;

       
        uint256 splitAmount;
        for (uint256 i = 0; i < len; ) {
            splitAmount = (saleprice * recipients[i].split) / BPS_MAX;
            if (splitAmount != 0 && recipients[i].recipientSoulBoundTokenId !=0 )
                INFTDerivativeProtocolTokenV1(_ndpt()).transferValue(
                    collectorSoulBoundTokenId, 
                    recipients[i].recipientSoulBoundTokenId,
                    splitAmount);

            unchecked {
                ++i;
            }
        }
        
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param ownershipSoulBoundTokenId The token ID of the profile mapped to the publication to query.
     * @param publishId The publication ID of the publication to query.
     *
     * @return The BaseProfilePublicationData struct mapped to that publication.
     */
    function getPublicationData(uint256 ownershipSoulBoundTokenId, uint256 publishId)
        external
        view
        returns (MultirecipientFeeCollectProfilePublicationData memory)
    {
        BaseProfilePublicationData memory baseData = getBasePublicationData(ownershipSoulBoundTokenId, publishId);
        RecipientData[] memory recipients = _recipientsByPublicationByProfile[ownershipSoulBoundTokenId][publishId];

        return
            MultirecipientFeeCollectProfilePublicationData({
                tokenId: baseData.tokenId,
                amount: baseData.amount,
                salePrice: baseData.salePrice,
                currency: baseData.currency,
                endTimestamp: baseData.endTimestamp,
                recipients: recipients
            });
    }


    function getSaleInfo(
        uint256 publishId
    ) external view returns (uint256, uint256, uint256){}

    function getFees(
        uint256 publishId, 
        uint256 collectValue
    ) external view returns (uint16, uint256, uint256, uint256, uint256){

    }

}
