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

    constructor(address manager, address market, address moduleGlobals) FeeModuleBase(moduleGlobals) ModuleBase(manager, market) {}

    function initializePublicationCollectModule(
        uint256 publishId,
        uint256 ownershipSoulBoundTokenId,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data 
    ) external override onlyManager {
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
     */
    function processCollect(
        uint256 ownershipSoulBoundTokenId,
        uint256 collectorSoulBoundTokenId,
        uint256 publishId,
        uint96 payValue,
        bytes calldata data
    ) external virtual override onlyManagerOrMarket returns (DataTypes.RoyaltyAmounts memory){
        //TODO only manager or market 
       return _processCollect(
            ownershipSoulBoundTokenId, 
            collectorSoulBoundTokenId, 
            publishId, 
            payValue,
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
        uint96 payValue
    ) external view returns (
        uint96 totalFees, 
        uint96 creatorRev, 
        uint96 previousCreatorRev, 
        uint96 sellerRev 
    ) {
        (,  uint16 treasuryFee) = _treasuryData();
        
        unchecked{
            totalFees = uint96(payValue * treasuryFee / BASIS_POINTS);
            creatorRev = uint96(payValue * _dataByPublicationByProfile[publishId].genesisFee / BASIS_POINTS);
            previousCreatorRev = uint96(payValue * _dataByPublicationByProfile[publishId].previousFee / BASIS_POINTS);
            sellerRev = uint96(payValue) - totalFees - creatorRev - previousCreatorRev;
        }

    }

    function _processCollect(
        uint256 ownershipSoulBoundTokenId,
        uint256 collectorSoulBoundTokenId,
        uint256 publishId, 
        uint96 payValue,
        bytes calldata data
    ) internal returns (DataTypes.RoyaltyAmounts memory royaltyAmounts){
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
                    payValue,
                    collectFeeUsers,
                    royaltyAmounts
                );
            }
        }
    }
/*
    // solhint-disable-next-line code-complexity
    function getFees(
        address dnftContract,
        uint256 tokenId,
        uint256 price
    )
        external
        view
        returns (
            FeeWithRecipient memory protocol,
            Fee memory creator,
            FeeWithRecipient memory owner,
            RevSplit[] memory creatorRevSplit
        )
    {
        // Note that the protocol fee returned does not account for the referrals (which are not known until sale).
        protocol.recipient = market.getFoundationTreasury();
        address payable[] memory creatorRecipients;
        uint256[] memory creatorShares;
        uint256 creatorRev;
        {
            address payable ownerAddress;
            uint256 totalFees;
            uint256 sellerRev;
            (totalFees, creatorRev, creatorRecipients, creatorShares, sellerRev, ownerAddress) = market.getFeesAndRecipients(
                dnftContract,
                tokenId,
                price
            );
            protocol.amountInWei = totalFees;
            creator.amountInWei = creatorRev;
            owner.amountInWei = sellerRev;
            owner.recipient = ownerAddress;
            if (creatorShares.length == 0) {
                creatorShares = new uint256[](creatorRecipients.length);
                if (creatorShares.length == 1) {
                    creatorShares[0] = BASIS_POINTS;
                }
            }
        }
        uint256 creatorRevBP;
        {
            uint256 totalFeesBP;
            uint256 sellerRevBP;
            (totalFeesBP, creatorRevBP, , , sellerRevBP, ) = market.getFeesAndRecipients(dnftContract, tokenId, BASIS_POINTS);
            protocol.percentInBasisPoints = totalFeesBP;
            creator.percentInBasisPoints = creatorRevBP;
            owner.percentInBasisPoints = sellerRevBP;
        }

        // Normalize shares to 10%
        {
        uint256 totalShares = 0;
        for (uint256 i = 0; i < creatorShares.length; ++i) {
            // TODO handle ignore if > 100% (like the market would)
            totalShares += creatorShares[i];
        }

        if (totalShares != 0) {
            for (uint256 i = 0; i < creatorShares.length; ++i) {
            creatorShares[i] = (BASIS_POINTS * creatorShares[i]) / totalShares;
            }
        }
        }
        // Count creators and split recipients
        {
        uint256 creatorCount = creatorRecipients.length;
        for (uint256 i = 0; i < creatorRecipients.length; ++i) {
            // Check if the address is a percent split
            if (address(creatorRecipients[i]).isContract()) {
                try this.getSplitShareLength(creatorRecipients[i]) returns (uint256 recipientCount) {
                    creatorCount += recipientCount - 1;
                } catch // solhint-disable-next-line no-empty-blocks
                {
                    // Not a Foundation percent split
                }
            }
        }
        creatorRevSplit = new RevSplit[](creatorCount);
        }

        // Populate rev splits, including any percent splits
        uint256 revSplitIndex = 0;
        for (uint256 i = 0; i < creatorRecipients.length; ++i) {
        if (address(creatorRecipients[i]).isContract()) {
            try this.getSplitShareLength(creatorRecipients[i]) returns (uint256 recipientCount) {
                uint256 totalSplitShares;
                for (uint256 splitIndex = 0; splitIndex < recipientCount; ++splitIndex) {
                    uint256 share = PercentSplitETH(creatorRecipients[i]).getPercentInBasisPointsByIndex(splitIndex);
                    totalSplitShares += share;
                }
                for (uint256 splitIndex = 0; splitIndex < recipientCount; ++splitIndex) {
                    uint256 splitShare = (PercentSplitETH(creatorRecipients[i]).getPercentInBasisPointsByIndex(splitIndex) *
                    BASIS_POINTS) / totalSplitShares;
                    splitShare = (splitShare * creatorShares[i]) / BASIS_POINTS;
                    creatorRevSplit[revSplitIndex++] = _calcRevSplit(
                    price,
                    splitShare,
                    creatorRevBP,
                    PercentSplitETH(creatorRecipients[i]).getShareRecipientByIndex(splitIndex)
                    );
                }
                continue;
            } catch // solhint-disable-next-line no-empty-blocks
            {
            // Not a Foundation percent split
            }
        }
        {
            creatorRevSplit[revSplitIndex++] = _calcRevSplit(price, creatorShares[i], creatorRevBP, creatorRecipients[i]);
        }
        }

        // Bubble the creator to the first position in `creatorRevSplit`
        {
        address creatorAddress;
        try this.getTokenCreator(dnftContract, tokenId) returns (address _creatorAddress) {
            creatorAddress = _creatorAddress;
        } catch // solhint-disable-next-line no-empty-blocks
        {

        }
        if (creatorAddress != address(0)) {
            for (uint256 i = 1; i < creatorRevSplit.length; ++i) {
            if (creatorRevSplit[i].recipient == creatorAddress) {
                (creatorRevSplit[i], creatorRevSplit[0]) = (creatorRevSplit[0], creatorRevSplit[i]);
                break;
            }
            }
        }
        }
    }
*/
}
