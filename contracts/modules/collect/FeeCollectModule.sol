// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ICollectModule} from "../../interfaces/ICollectModule.sol";
import {IBankTreasury} from "../../interfaces/IBankTreasury.sol";
import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";
import {DataTypes} from '../../libraries/DataTypes.sol';
import {FeeModuleBase} from "../FeeModuleBase.sol";
import {ModuleBase} from "../ModuleBase.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {INFTDerivativeProtocolTokenV1} from "../../interfaces/INFTDerivativeProtocolTokenV1.sol";
import {IManager} from "../../interfaces/IManager.sol";

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 *
 * @param genesisSoulBoundTokenId The genesi sSoulBoundTokenId with this publication.
 * @param tokenId The tokenId with this publication.
 * @param amount The total supply with this publication.
 * @param salePrice The collecting cost associated with this publication.
 * @param royaltyBasisPoints The royalty basis points for derivative or OpenSea
 * @param ownershipSoulBoundTokenId The toSoulBoundTokenId associated with this publication.
 * @param genesisFee The percentage of the fee that will be transferred to the genesis soulBoundTokenId of this publication.
 */
struct ProfilePublicationData {
    uint256 genesisSoulBoundTokenId;       //创世的soulBoundTokenId
    uint256 previousSoulBoundTokenId;       //上级soulBoundTokenId
    uint256 tokenId;                       //发行对应的tokenId
    uint256 amount;                        //发行总量
    uint256 salePrice;                     //发行单价
    uint256 royaltyBasisPoints;            //二创及OpenSea税点
    uint256 ownershipSoulBoundTokenId;     //发行人的灵魂币ID
    uint16 genesisFee;                     //创世NFT版税点数，最多90%，以后每个衍生NFT都需要支付
    uint16 previousFee;                    //上级版税点数
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
contract FeeCollectModule is FeeModuleBase, ModuleBase, ICollectModule {
    // using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // publishId => ProfilePublicationData
    mapping(uint256 =>  ProfilePublicationData) internal _dataByPublicationByProfile;

    constructor(address manager, address moduleGlobals) FeeModuleBase(moduleGlobals) ModuleBase(manager) {}

    function initializePublicationCollectModule(
        uint256 publishId,
        uint256 ownershipSoulBoundTokenId,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data 
    ) external override onlyManager{
        (uint256 genesisSoulBoundTokenId, uint16 genesisFee, uint256 salePrice, uint256 royaltyBasisPoints) = abi.decode(
            data,
            (uint256, uint16,  uint256, uint256)
        );

        if (
            publishId == 0 || 
            ownershipSoulBoundTokenId == 0 || 
            genesisFee > BPS_MAX - 1000 || 
            amount == 0
        )
            revert Errors.InitParamsInvalid();

        //previous 
        DataTypes.PublishData memory publishData  = IManager(MANAGER).getPublishInfo(publishId);
        DataTypes.PublishData memory previousPublishData = IManager(MANAGER).getPublishInfo(publishData.previousPublishId);
        uint previousSoulBoundTokenId = previousPublishData.publication.soulBoundTokenId;
        
        //Save 
        _dataByPublicationByProfile[publishId].tokenId = tokenId;
        _dataByPublicationByProfile[publishId].amount = amount;
        _dataByPublicationByProfile[publishId].salePrice = salePrice;
        _dataByPublicationByProfile[publishId].royaltyBasisPoints = royaltyBasisPoints;
        _dataByPublicationByProfile[publishId].ownershipSoulBoundTokenId = ownershipSoulBoundTokenId;
        _dataByPublicationByProfile[publishId].genesisSoulBoundTokenId = genesisSoulBoundTokenId;
        _dataByPublicationByProfile[publishId].previousSoulBoundTokenId = previousSoulBoundTokenId;
        _dataByPublicationByProfile[publishId].genesisFee = genesisFee;
        _dataByPublicationByProfile[publishId].previousFee = uint16(previousPublishData.publication.royaltyBasisPoints);
    }

    /**
     * @dev Processes a collect by:
     *  1.  will pay royalty to ownershipSoulBoundTokenId
     *  2. Charging a fee
     *  3. Pay to genesis publisher
     */
    function processCollect(
        uint256 ownershipSoulBoundTokenId,
        uint256 collectorSoulBoundTokenId,
        uint256 publishId,
        uint256 collectValue,
        bytes calldata data
    ) external virtual override onlyManager {
        _processCollect(
            ownershipSoulBoundTokenId, 
            collectorSoulBoundTokenId, 
            publishId, 
            collectValue,
            data
        );
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param publishId The publish ID of the profile mapped to the publication to query.
     *
     * @return ProfilePublicationData The ProfilePublicationData struct mapped to that publication.
     */
    function getPublicationData(
        uint256 publishId
    ) external view returns (ProfilePublicationData memory) {
        return _dataByPublicationByProfile[publishId];
    }

    function getFees(
        uint256 publishId, 
        uint256 collectValue
    ) external view returns (
        uint16 treasuryFee, 
        uint256 genesisSoulBoundTokenId, 
        DataTypes.RoyaltyAmounts memory royaltyAmounts
    ) {

        uint256 payValue = collectValue.mul(_dataByPublicationByProfile[publishId].salePrice);
        (,  treasuryFee) = _treasuryData();
        genesisSoulBoundTokenId = _dataByPublicationByProfile[publishId].genesisSoulBoundTokenId;
        royaltyAmounts.treasuryAmount = payValue.mul(treasuryFee).div(BPS_MAX);
        royaltyAmounts.genesisAmount = payValue.mul(_dataByPublicationByProfile[publishId].genesisFee).div(BPS_MAX);
        royaltyAmounts.previousAmount = payValue.mul(_dataByPublicationByProfile[publishId].previousFee).div(BPS_MAX);
        royaltyAmounts.adjustedAmount = payValue.sub(royaltyAmounts.treasuryAmount).sub(royaltyAmounts.genesisAmount).sub(royaltyAmounts.previousAmount);

        return (
           treasuryFee,
           genesisSoulBoundTokenId,
           royaltyAmounts
        );
    }

    function _processCollect(
        uint256 ownershipSoulBoundTokenId,
        uint256 collectorSoulBoundTokenId,
        uint256 publishId, 
        uint256 collectValue,
        bytes calldata data
    ) internal {
        DataTypes.RoyaltyAmounts memory royaltyAmounts;
        uint256 payValue = collectValue.mul(_dataByPublicationByProfile[publishId].salePrice);
        uint256 genesisSoulBoundTokenId = _dataByPublicationByProfile[publishId].genesisSoulBoundTokenId;
        
        //获取交易税点
        (address treasury, uint16 treasuryFee) = _treasuryData();
        royaltyAmounts.treasuryAmount = payValue.mul(treasuryFee).div(BPS_MAX);
        royaltyAmounts.previousAmount = payValue.mul(_dataByPublicationByProfile[publishId].previousFee).div(BPS_MAX);
        royaltyAmounts.genesisAmount = payValue.mul(_dataByPublicationByProfile[publishId].genesisFee).div(BPS_MAX);
        {
            // royaltyAmounts.adjustedAmount = payValue.sub(royaltyAmounts.treasuryAmount).sub(royaltyAmounts.genesisAmount);
            royaltyAmounts.adjustedAmount = payValue.sub(royaltyAmounts.treasuryAmount).sub(royaltyAmounts.genesisAmount).sub(royaltyAmounts.previousAmount);
            if ( royaltyAmounts.adjustedAmount > 0) 
                INFTDerivativeProtocolTokenV1(_sbt()).transferValue(collectorSoulBoundTokenId, ownershipSoulBoundTokenId, royaltyAmounts.adjustedAmount);
            
            uint256 treasuryOfSoulBoundTokenId = IBankTreasury(treasury).getSoulBoundTokenId();
            
            if (royaltyAmounts.treasuryAmount > 0) INFTDerivativeProtocolTokenV1(_sbt()).transferValue(collectorSoulBoundTokenId, treasuryOfSoulBoundTokenId, royaltyAmounts.treasuryAmount);
            if (genesisSoulBoundTokenId >0 && royaltyAmounts.genesisAmount > 0) INFTDerivativeProtocolTokenV1(_sbt()).transferValue(collectorSoulBoundTokenId, genesisSoulBoundTokenId, royaltyAmounts.genesisAmount);
            if (royaltyAmounts.previousAmount > 0) INFTDerivativeProtocolTokenV1(_sbt()).transferValue(collectorSoulBoundTokenId, _dataByPublicationByProfile[publishId].previousSoulBoundTokenId, royaltyAmounts.previousAmount);

            DataTypes.CollectFeeUsers memory collectFeeUsers =  DataTypes.CollectFeeUsers({
                ownershipSoulBoundTokenId: ownershipSoulBoundTokenId,
                collectorSoulBoundTokenId: collectorSoulBoundTokenId,
                genesisSoulBoundTokenId: genesisSoulBoundTokenId,
                previousSoulBoundTokenId: _dataByPublicationByProfile[publishId].previousSoulBoundTokenId
            });

//TODO
            emit Events.FeesForCollect(
                publishId,
                collectFeeUsers,
                royaltyAmounts
            );
        }
    }

}
