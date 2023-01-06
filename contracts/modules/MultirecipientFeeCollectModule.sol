// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Errors} from '../libraries/Errors.sol';
import {Events} from "../libraries/Events.sol";
import {IBankTreasury} from "../interfaces/IBankTreasury.sol";
import {IManager} from "../interfaces/IManager.sol";
import {DataTypes} from '../libraries/DataTypes.sol';
import {IDerivativeNFTV1} from "../interfaces/IDerivativeNFTV1.sol";
import {BaseFeeCollectModule} from './base/BaseFeeCollectModule.sol';
import {BaseProfilePublicationData, BaseFeeCollectModuleInitData} from './base/IBaseFeeCollectModule.sol';
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {INFTDerivativeProtocolTokenV1} from "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

struct RecipientData {
    uint256 recipientSoulBoundTokenId;
    uint16 royaltyPoint; // fraction of BPS_MAX (10 000)
}

/**
 * @notice A struct containing the necessary data to initialize MultirecipientFeeCollectModule.
 *
 * @param projectId The project Id.
 * @param salePrice The collecting cost associated with this publication. Cannot be 0.
 * @param recipients Array of RecipientData items to split collect fees across multiple recipients.
 */
struct MultirecipientFeeCollectModuleInitData {
    uint256 projectId;
    uint256 salePrice;
    uint16[] royaltyPoints; //税点数组
}

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 *
 * @param salePrice The collecting cost associated with this publication. Cannot be 0.
 * @param royaltyPoints Array of royalty points.
 */
struct MultirecipientFeeCollectProfilePublicationData {
    uint256 salePrice;
    uint16[] royaltyPoints;
}

struct RoyaltyInfoData {
    address treasury;
    uint16 treasuryFee;
    uint256 treasuryAmount;
    uint96  fraction;
    uint256[] royalties;
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
    using SafeMathUpgradeable for uint256;

    uint256 internal constant MAX_RECIPIENTS = 5;

    //store royalty points by projectId
    mapping(uint256 => uint16[]) internal _royaltyPointsByPublicationByProfile;

    constructor(address manager, address moduleGlobals) BaseFeeCollectModule(manager, moduleGlobals) {}

    //projectId => level(0-4) => BPS 
    // mapping(uint256 => mapping(uint8 => uint16)) internal _splitPoints;  

    /**
     * @inheritdoc ICollectModule
     */
    function initializePublicationCollectModule(
        uint256 publishId,
        uint256 ownershipSoulBoundTokenId,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data        
    ) external override onlyManager {
        MultirecipientFeeCollectModuleInitData memory initData = abi.decode(
            data,
            (MultirecipientFeeCollectModuleInitData)
        );

        tokenId;

        BaseFeeCollectModuleInitData memory baseInitData = BaseFeeCollectModuleInitData({
            ownershipSoulBoundTokenId: ownershipSoulBoundTokenId,
            projectId: initData.projectId,
            publishId: publishId,
            salePrice: initData.salePrice, 
            amount: amount, 
            royaltyPoints: initData.royaltyPoints
        });

        // Zero amount for collect doesn't make sense here (in a module with 5 royaltyPoints)
        // For this better use FreeCollect module instead
        if (baseInitData.amount == 0) revert Errors.InitParamsInvalid();
        if (ownershipSoulBoundTokenId == 0) revert Errors.InitParamsInvalid();
        _validateAndStoreRoyaltyPoints(initData.royaltyPoints, baseInitData.projectId);
        _storeBasePublicationCollectParameters(baseInitData.projectId, baseInitData);
    }

    /**
     * @dev Validates the recipients array and stores them to (a separate from Base) storage.
     *
     * @param royaltyPoints An array of RecipientData
     * @param projectId The associated publication's publication ID.
     */
    function _validateAndStoreRoyaltyPoints(
        uint16[] memory royaltyPoints,
        uint256 projectId
    ) internal {
        uint256 len = royaltyPoints.length;

        // Check number of recipients is supported
        if (len > MAX_RECIPIENTS) revert TooManyRecipients();
        if (len == 0) revert Errors.InitParamsInvalid();

        // Check recipient splits sum to 10 000 BPS (100%)
        uint256 totalSplits;
        for (uint256 i = 0; i < len; ) {
            totalSplits += royaltyPoints[i];

            // Store each royaltyPoints while looping - avoids extra gas costs in successful cases
            _royaltyPointsByPublicationByProfile[projectId].push(royaltyPoints[i]);

            unchecked {
                ++i;
            }
        }
        address derivativeNFT = IManager(MANAGER).getDerivativeNFT(projectId);
        uint96 fraction = IDerivativeNFTV1(derivativeNFT).getDefaultRoyalty();
        if (totalSplits != fraction) revert Errors.InvalidRecipientSplits();

    }
 
    /**
     * @dev Transfers the fee to multiple recipients.
     *
     * @inheritdoc BaseFeeCollectModule
     */
    function _transferToRecipients(
        uint256 collectorSoulBoundTokenId,
        uint256 projectId,
        uint256 saleprice,
        uint256[] memory recipients
    ) internal override {
        uint16[] memory royaltyPoints = _royaltyPointsByPublicationByProfile[projectId];
        uint256 len = royaltyPoints.length;

        uint256 royaltyAmount;
        for (uint256 i = 0; i < len; ) {
            royaltyAmount = (saleprice * royaltyPoints[i]) / BPS_MAX;
            if (royaltyAmount != 0 && royaltyPoints[i] !=0 )
                INFTDerivativeProtocolTokenV1(_ndpt()).transferValue(
                    collectorSoulBoundTokenId, 
                    recipients[i],
                    royaltyAmount);


            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param projectId The publication ID of the publication to query.
     *
     * @return The BaseProfilePublicationData struct mapped to that publication.
     */
    function getPublicationData(uint256 projectId)
        external
        view
        returns (MultirecipientFeeCollectProfilePublicationData memory)
    {
        BaseProfilePublicationData memory baseData = getBasePublicationData(projectId);
        uint16[] memory royaltyPoints = _royaltyPointsByPublicationByProfile[projectId];
        return
            MultirecipientFeeCollectProfilePublicationData({
                salePrice: baseData.salePrice,
                royaltyPoints: royaltyPoints
            });
    }
    /**
     * @notice Returns the fees 
     * initialized with this module.
     *
     * @param projectId The project ID 
     * @param collectValue The value to calculate.
     * @param recipients The array of the publication to query.
     *
     * @return RoyaltyInfoData 
     */
    function getFees(
        uint256 projectId, 
        uint256 collectValue,
        uint256[] memory recipients
    ) external view returns (
        RoyaltyInfoData memory
    ) {
        uint96 fraction = IDerivativeNFTV1(IManager(MANAGER).getDerivativeNFT(projectId)).getDefaultRoyalty();
         
        uint256 payFees = collectValue.mul(_dataByPublicationByProfile[projectId].salePrice) * fraction;

        //社区金库地址及税点
        (address treasury, uint16 treasuryFee) = _treasuryData();
        uint256 treasuryAmount = (payFees * treasuryFee) / BPS_MAX;
        uint256[] memory royalties = new uint256[](recipients.length);

        for (uint256 i = 0; i < recipients.length; ) {
            uint256 royaltyAmount = (_dataByPublicationByProfile[projectId].salePrice * _dataByPublicationByProfile[projectId].royaltyPoints[i]) / BPS_MAX;
            royalties[i] = royaltyAmount;

            unchecked {
                ++i;
            }
        }
     
        return RoyaltyInfoData({
            treasury: treasury,
            treasuryFee: treasuryFee,
            treasuryAmount: treasuryAmount,
            fraction: fraction,
            royalties: royalties
        });
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param projectId The project ID 
     * @param newRoyaltyPoints The array of the publication to query.
     *
     */
    function updateRoyaltyPoints(
        uint256 projectId,
        uint16[MAX_RECIPIENTS] calldata newRoyaltyPoints
    ) external {
        BaseProfilePublicationData memory baseData = getBasePublicationData(projectId);
        if (IERC3525(_ndpt()).ownerOf(baseData.ownershipSoulBoundTokenId) == msg.sender ) {
            revert Errors.Unauthorized();
        }

        uint16[] storage royaltyPoints = _royaltyPointsByPublicationByProfile[projectId];

        uint256 totalSplits;
        for (uint256 i = 0; i < MAX_RECIPIENTS; ) {
            totalSplits += newRoyaltyPoints[i];
            royaltyPoints[i] = newRoyaltyPoints[i];
            unchecked {
                ++i;
            }
        }

        address derivativeNFT = IManager(MANAGER).getDerivativeNFT(projectId);
        uint96 fraction = IDerivativeNFTV1(derivativeNFT).getDefaultRoyalty();
        if (totalSplits != fraction) revert Errors.InvalidRecipientSplits();

        emit Events.UpdateRoyaltyPoints(
            projectId,
            newRoyaltyPoints,
            block.timestamp
        );
    
    }   
}
