// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
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
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
// import "hardhat/console.sol";

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
    address currency;                        
    uint256 amount;                        
    uint256 salePrice;                     
    uint256 royaltyBasisPoints;           
    // uint256 ownershipSoulBoundTokenId; 
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
contract FeeCollectModule is ReentrancyGuard, FeeModuleBase, ModuleBase, ICollectModule {
    using SafeERC20 for IERC20;
    using SafeMathUpgradeable for uint256;

    /// @notice The fee collected by the buy referrer for sales facilitated by this market contract.
    ///         This fee is calculated from the total protocol fee.
    uint256 private constant BUY_REFERRER_FEE_DENOMINATOR = 100; // 1%

    // publishId => ProfilePublicationData
    mapping(uint256 =>  ProfilePublicationData) internal _dataByPublicationByProfile;

    constructor(address manager, address market, address moduleGlobals) FeeModuleBase(moduleGlobals) ModuleBase(manager, market) {}

    function initializePublicationCollectModule(
        uint256 publishId,
        // uint256 ownershipSoulBoundTokenId,
        uint256 tokenId,
        address currency,
        uint256 amount,
        bytes calldata data 
    ) external override nonReentrant onlyManager {
        (uint256 genesisSoulBoundTokenId, uint16 genesisFee, uint256 salePrice, uint256 royaltyBasisPoints) = abi.decode(
            data,
            (uint256, uint16,  uint256, uint256)
        );

        if ( !_currencyWhitelisted(currency))
            revert Errors.CurrencyNotInWhitelisted(currency);

        if ( publishId == 0 || 
            // ownershipSoulBoundTokenId == 0 || 
            genesisFee > BASIS_POINTS - 1000 || 
            amount == 0
        )
            revert Errors.InitParamsInvalid();

        //previous 
        {
            DataTypes.PublishData memory publishData  = IManager(MANAGER).getPublishInfo(publishId);
            DataTypes.PublishData memory previousPublishData = IManager(MANAGER).getPublishInfo(publishData.previousPublishId);

             //Save 
            _dataByPublicationByProfile[publishId].tokenId = tokenId;
            _dataByPublicationByProfile[publishId].currency = currency;
            _dataByPublicationByProfile[publishId].amount = amount;
            _dataByPublicationByProfile[publishId].salePrice = salePrice;
            _dataByPublicationByProfile[publishId].royaltyBasisPoints = royaltyBasisPoints;
            // _dataByPublicationByProfile[publishId].ownershipSoulBoundTokenId = ownershipSoulBoundTokenId;
            _dataByPublicationByProfile[publishId].genesisSoulBoundTokenId = genesisSoulBoundTokenId;
            _dataByPublicationByProfile[publishId].previousSoulBoundTokenId = previousPublishData.publication.soulBoundTokenId;
            _dataByPublicationByProfile[publishId].genesisFee = genesisFee;
            _dataByPublicationByProfile[publishId].previousFee = uint16(previousPublishData.publication.royaltyBasisPoints);
        }
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
    ) 
        external 
        virtual 
        override 
        nonReentrant  
        onlyManagerOrMarket
        returns (DataTypes.RoyaltyAmounts memory)
    {
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
            // referrerFee max limit 1000
            if (referrerFee >  BUY_REFERRER_FEE_DENOMINATOR ) {
                revert Errors.ReferrerFeeExceeded();
            }
        }
        

        unchecked {

            if (payValue > 0) {
                uint256 genesisSoulBoundTokenId = _dataByPublicationByProfile[publishId].genesisSoulBoundTokenId;
                (address treasury, uint16 treasuryFee) = _treasuryData();
                
                royaltyAmounts.treasuryAmount = uint96(payValue * treasuryFee / BASIS_POINTS);
                royaltyAmounts.previousAmount = uint96(payValue * _dataByPublicationByProfile[publishId].previousFee / BASIS_POINTS);
                royaltyAmounts.genesisAmount = uint96(payValue * _dataByPublicationByProfile[publishId].genesisFee / BASIS_POINTS);
                royaltyAmounts.adjustedAmount = payValue - royaltyAmounts.treasuryAmount - royaltyAmounts.genesisAmount - royaltyAmounts.previousAmount;
                 if (treasuryFee >0 && treasuryFee > referrerFee ) {

                    if (referrerSoulBoundTokenId != 0 && referrerFee > 0) {
                        royaltyAmounts.referrerAmount = uint96(payValue * referrerFee / BASIS_POINTS);
                        royaltyAmounts.treasuryAmount = royaltyAmounts.treasuryAmount - royaltyAmounts.referrerAmount;
                    }

                 }

                // console.log("royaltyAmounts.treasuryAmount:", royaltyAmounts.treasuryAmount);
                // console.log("royaltyAmounts.genesisAmount:", royaltyAmounts.genesisAmount);
                // console.log("royaltyAmounts.previousAmount:", royaltyAmounts.previousAmount);
                // console.log("royaltyAmounts.referrerAmount:", royaltyAmounts.referrerAmount);
                // console.log("royaltyAmounts.adjustedAmount:", royaltyAmounts.adjustedAmount);
                
                DataTypes.CollectFeeUsers memory collectFeeUsers =  DataTypes.CollectFeeUsers({
                    ownershipSoulBoundTokenId: ownershipSoulBoundTokenId,
                    collectorSoulBoundTokenId: collectorSoulBoundTokenId,
                    genesisSoulBoundTokenId: genesisSoulBoundTokenId,
                    previousSoulBoundTokenId: _dataByPublicationByProfile[publishId].previousSoulBoundTokenId,
                    referrerSoulBoundTokenId: referrerSoulBoundTokenId
                });

                {
                    // distribute funds to assoassociated user revenue
                    IBankTreasury(treasury).distributeFundsToUserRevenue(
                        publishId,
                        _dataByPublicationByProfile[publishId].currency,
                        payValue,
                        collectFeeUsers,
                        royaltyAmounts
                    ); 
                }
               
            }
        }
    }
    
}
