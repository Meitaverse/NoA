// SPDX-License-Identifier: MIT
/*

这是一个基于以太坊的智能合约，用于实现多收款人费用收集模块。它允许自定义收集时间、收集次数上限、将收集费用分配给多个收款人，并可设置仅关注者才能收集。该合约使用OpenZeppelin的IERC20和SafeERC20库以及Aave的Errors库。

合约中的主要结构：

RecipientData 结构：包含收款人地址和分配给收款人的分数（占总分数的百分比）。
MultirecipientFeeCollectModuleInitData 结构：包含初始化多收款人费用收集模块所需的数据。
MultirecipientFeeCollectProfilePublicationData 结构：包含在执行收集操作时需要用到的关于多收款人费用收集的相关数据。
该合约的主要功能：

initializePublicationCollectModule 函数：初始化多收款人费用收集模块。验证并存储收款人数据，存储基础出版物收集参数。
_validateAndStoreRecipients 函数：验证收款人数组并将它们存储到与基础模块分开的存储中。
_transferToRecipients 函数：将费用按照设置的分数分配给多个收款人。
getPublicationData 函数：返回给定出版物的出版物数据，如果该出版物未使用此模块初始化，则返回空结构。
此智能合约可以用于实现收费的内容收集功能，允许多个收款人在收集过程中共享费用。
*/
pragma solidity ^0.8.10;

import {Errors} from '../libraries/Errors.sol';
import {Events} from "../libraries/Events.sol";
import {IBankTreasury} from "../interfaces/IBankTreasury.sol";
import {IManager} from "../interfaces/IManager.sol";
import {DataTypes} from '../libraries/DataTypes.sol';
import "../libraries/Constants.sol";
import {IDerivativeNFT} from "../interfaces/IDerivativeNFT.sol";
import {BaseFeeCollectModule} from './base/BaseFeeCollectModule.sol';
import {BaseProfilePublicationData, BaseFeeCollectModuleInitData} from './base/IBaseFeeCollectModule.sol';
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {INFTDerivativeProtocolTokenV1} from "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

struct RecipientData {
    uint256 recipientSoulBoundTokenId;
    uint16 royaltyPoint; // fraction of BASIS_POINTS (10 000)
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
    uint16[] royaltyPoints;
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

/**
 * @title MultirecipientCollectModule
 * @author Bitsoul Protocol
 *
 * @notice This is a simple Bitsoul CollectModule implementation, allowing customization of time to collect, number of collects,
 * splitting collect fee across multiple recipients, and whether only followers can collect.
 * It is charging a fee for collect and distributing it among (one or up to five) Receivers, Referral, Treasury.
 */
contract MultirecipientFeeCollectModule is BaseFeeCollectModule {
    using SafeMathUpgradeable for uint256;

    uint256 internal constant MAX_RECIPIENTS = 5;

    //store royalty points by projectId
    mapping(uint256 => uint16[]) internal _royaltyPointsByPublicationByProfile;

    constructor(address manager, address market, address moduleGlobals) BaseFeeCollectModule(manager, market, moduleGlobals) {}

    /**
     * @inheritdoc ICollectModule
     */
    function initializePublicationCollectModule(
        uint256 publishId,
        // uint256 tokenId,
        address currency,
        uint256 amount,
        bytes calldata data        
    ) external override onlyManager {
        MultirecipientFeeCollectModuleInitData memory initData = abi.decode(
            data,
            (MultirecipientFeeCollectModuleInitData)
        );

        // tokenId;

        BaseFeeCollectModuleInitData memory baseInitData = BaseFeeCollectModuleInitData({
            // ownershipSoulBoundTokenId: ownershipSoulBoundTokenId,
            projectId: initData.projectId,
            publishId: publishId,
            salePrice: initData.salePrice, 
            currency: currency,
            amount: amount, 
            royaltyPoints: initData.royaltyPoints
        });

        // Zero amount for collect doesn't make sense here (in a module with 5 royaltyPoints)
        // For this better use FreeCollect module instead
        if (baseInitData.amount == 0) revert Errors.InitParamsInvalid();
        // if (ownershipSoulBoundTokenId == 0) revert Errors.InitParamsInvalid();
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
        if (len > MAX_RECIPIENTS) revert Errors.TooManyRecipients();
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
        // address derivativeNFT = IManager(MANAGER).getDerivativeNFT(projectId);
        // uint96 fraction = IDerivativeNFT(derivativeNFT).getDefaultRoyalty();
        // if (totalSplits != fraction) revert Errors.InvalidRecipientSplits();
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

        //(address treasury, ) = _treasuryData();

        uint256 royaltyAmount;
        for (uint256 i = 0; i < len; ) {
            royaltyAmount = (saleprice * royaltyPoints[i]) / BASIS_POINTS;
            // if (royaltyAmount != 0 && royaltyPoints[i] !=0 )
                //TODO approved
                /*
                INFTDerivativeProtocolTokenV1(_sbt()).transferValue(
                    collectorSoulBoundTokenId, 
                    recipients[i],
                    royaltyAmount
                );
                */
               
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
     * @param collectUnits The value to calculate.
     * @param recipients The array of the publication to query.
     *
     * @return RoyaltyInfoData 
     */
    function getFees(
        uint256 projectId, 
        uint256 collectUnits,
        uint256[] memory recipients
    ) external view returns (
        RoyaltyInfoData memory
    ) {
        /*
        uint96 fraction = IDerivativeNFT(IManager(MANAGER).getDerivativeNFT(projectId)).getDefaultRoyalty();
         

        (address treasury, uint16 treasuryFee) = _treasuryData();
        uint256 treasuryAmount = (payFees * treasuryFee) / BASIS_POINTS;
        uint256[] memory royalties = new uint256[](recipients.length);

        for (uint256 i = 0; i < recipients.length; ) {
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
        */
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
        // if (IERC3525(_sbt()).ownerOf(baseData.ownershipSoulBoundTokenId) == msg.sender ) {
        //     revert Errors.Unauthorized();
        // }

        uint16[] storage royaltyPoints = _royaltyPointsByPublicationByProfile[projectId];

        uint256 totalSplits;
        for (uint256 i = 0; i < MAX_RECIPIENTS; ) {
            totalSplits += newRoyaltyPoints[i];
            royaltyPoints[i] = newRoyaltyPoints[i];
            unchecked {
                ++i;
            }
        }
/*
        address derivativeNFT = IManager(MANAGER).getDerivativeNFT(projectId);
        uint96 fraction = IDerivativeNFT(derivativeNFT).getDefaultRoyalty();
        if (totalSplits != fraction) revert Errors.InvalidRecipientSplits();

        emit Events.UpdateRoyaltyPoints(
            projectId,
            newRoyaltyPoints,
            block.timestamp
        );
*/
    }   

     function updateCollectLimitPerAddress(
        uint256 publishId, 
        uint16 collectLimitPerAddress
    ) external onlyManager {

    }
    
}
