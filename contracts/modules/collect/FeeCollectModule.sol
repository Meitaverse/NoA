// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ICollectModule} from "../../interfaces/ICollectModule.sol";
import {IBankTreasury} from "../../interfaces/IBankTreasury.sol";
import {Errors} from "../../libraries/Errors.sol";
import '../../libraries/Constants.sol';
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
    uint256 genesisSoulBoundTokenId;      
    uint256 previousSoulBoundTokenId;     
    uint256 tokenId;                       
    uint256 amount;                        
    uint256 salePrice;                     
    uint256 royaltyBasisPoints;           
    uint256 ownershipSoulBoundTokenId; 
    uint16 genesisFee;                     
    uint16 previousFee;              
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

    /// @notice The fee collected by the buy referrer for sales facilitated by this market contract.
    ///         This fee is calculated from the total protocol fee.
    uint256 private constant BUY_REFERRER_FEE_DENOMINATOR = BASIS_POINTS / 100; // 1%

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
            genesisFee > BASIS_POINTS - 1000 || 

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
        uint256 collectUnits,
        bytes calldata data
    ) external virtual override onlyManager {
        _processCollect(
            ownershipSoulBoundTokenId, 
            collectorSoulBoundTokenId, 
            publishId, 
            collectUnits,
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
        uint32 collectUnits
    ) external view returns (
        uint16 treasuryFee, 
        uint256 genesisSoulBoundTokenId, 
        DataTypes.RoyaltyAmounts memory royaltyAmounts
    ) {
        (,  treasuryFee) = _treasuryData();
        genesisSoulBoundTokenId = _dataByPublicationByProfile[publishId].genesisSoulBoundTokenId;
        
        unchecked{
            uint96 payValue = uint96(collectUnits * _dataByPublicationByProfile[publishId].salePrice);
            royaltyAmounts.treasuryAmount = uint96(payValue * treasuryFee / BASIS_POINTS);
            royaltyAmounts.genesisAmount = uint96(payValue * _dataByPublicationByProfile[publishId].genesisFee / BASIS_POINTS);
            royaltyAmounts.previousAmount = uint96(payValue * _dataByPublicationByProfile[publishId].previousFee / BASIS_POINTS);
            royaltyAmounts.adjustedAmount = payValue - royaltyAmounts.treasuryAmount - royaltyAmounts.genesisAmount - royaltyAmounts.previousAmount;

        }

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
        uint256 collectUnits,
        bytes calldata data
    ) internal {
        uint256 referrerSoulBoundTokenId;
         uint16 referrerFee;
        if (data.length != 0) {
            (referrerSoulBoundTokenId, referrerFee) = abi.decode(
                data,
                (uint256, uint16)
            );
        }

        // referrerFee max limit 1000
        if (referrerFee >  BUY_REFERRER_FEE_DENOMINATOR ) {
            revert Errors.ReferrerFeeExceeded();
        }

        unchecked {

            DataTypes.RoyaltyAmounts memory royaltyAmounts;
            uint96 payValue = uint96(collectUnits.mul(_dataByPublicationByProfile[publishId].salePrice));
            if (payValue >0) {
                //Transfer Value of total pay to treasury 
                INFTDerivativeProtocolTokenV1(_sbt()).transferValue(collectorSoulBoundTokenId, BANK_TREASURY_SOUL_BOUND_TOKENID, payValue);

                uint256 genesisSoulBoundTokenId = _dataByPublicationByProfile[publishId].genesisSoulBoundTokenId;
                (address treasury, uint16 treasuryFee) = _treasuryData();
                
                if (treasuryFee >0 && treasuryFee < referrerFee) {
                    revert Errors.NFTMarketFees_Invalid_Referrer_Fee();   
                }

                royaltyAmounts.treasuryAmount = uint96(payValue * treasuryFee / BASIS_POINTS);
                royaltyAmounts.previousAmount = uint96(payValue * _dataByPublicationByProfile[publishId].previousFee / BASIS_POINTS);
                royaltyAmounts.genesisAmount = uint96(payValue * _dataByPublicationByProfile[publishId].genesisFee / BASIS_POINTS);
                royaltyAmounts.adjustedAmount = payValue - royaltyAmounts.treasuryAmount - royaltyAmounts.genesisAmount - royaltyAmounts.previousAmount;
                if (referrerSoulBoundTokenId != 0 && referrerFee > 0) {
                    royaltyAmounts.referrerAmount = uint96(payValue * referrerFee / BASIS_POINTS);
                    royaltyAmounts.treasuryAmount = royaltyAmounts.treasuryAmount - royaltyAmounts.referrerAmount;
                }
                
                DataTypes.CollectFeeUsers memory collectFeeUsers =  DataTypes.CollectFeeUsers({
                    ownershipSoulBoundTokenId: ownershipSoulBoundTokenId,
                    collectorSoulBoundTokenId: collectorSoulBoundTokenId,
                    genesisSoulBoundTokenId: genesisSoulBoundTokenId,
                    previousSoulBoundTokenId: _dataByPublicationByProfile[publishId].previousSoulBoundTokenId,
                    referrerSoulBoundTokenId: referrerSoulBoundTokenId
                });
                
                // save funds
                IBankTreasury(treasury).saveFundsToUserRevenue(
                    collectorSoulBoundTokenId,
                    payValue,
                    collectFeeUsers,
                    royaltyAmounts
                );

                emit Events.FeesForCollect(
                    publishId,
                    _dataByPublicationByProfile[publishId].tokenId,
                    collectUnits,
                    collectFeeUsers,
                    royaltyAmounts
                );
            }
        }
    }

}
