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
 * @param projectId The project Id with this publication.
 * @param currency The currency contract address
 * @param amount The total supply with this publication.
 * @param salePrice The collecting cost associated with this publication.
 * @param collectLimitPerAddress The collect per address limit.
 * @param utcTimestampStartAt The start time of this publication.
 */
struct ProfilePublicationData {
    uint256 projectId;     
    address currency;                        
    uint256 amount;                        
    uint256 salePrice;                     
    uint16 collectLimitPerAddress;
    uint32 utcTimestampStartAt;              
}

/**
 * @title ProjectFounderCollectModule
 * @author Bitsoul Protocol
 *
 * This module works by allowing unlimited collects for a publication at a given price.
 */
contract ProjectFounderCollectModule is ReentrancyGuard, FeeModuleBase, ModuleBase, ICollectModule {
    using SafeERC20 for IERC20;
    using SafeMathUpgradeable for uint256;

    /// @notice The fee collected by the buy referrer for sales facilitated by this market contract.
    ///         This fee is calculated from the total protocol fee.
    uint256 private constant BUY_REFERRER_FEE_DENOMINATOR = 100; // 1%

    // publishId => ProfilePublicationData
    mapping(uint256 =>  ProfilePublicationData) internal _dataByPublicationByProfile;

    //publishId => collector SBT Id => collect total count
    mapping(uint256 => mapping(uint256 => uint256)) internal _collectCountPerAddress;

    constructor(
        address manager, 
        address market, 
        address moduleGlobals
    ) FeeModuleBase(moduleGlobals) ModuleBase(manager, market) {}

    function initializePublicationCollectModule(
        uint256 publishId,
        address currency,
        uint256 amount,
        bytes calldata data 
    ) external override nonReentrant onlyManager {
        (uint256 salePrice, , uint16 collectLimitPerAddress, uint32 utcTimestampStartAt) = abi.decode
        (
            data,
            (uint256, uint16, uint16, uint32)
        );

        if ( !_currencyWhitelisted(currency))
            revert Errors.CurrencyNotInWhitelisted(currency);

        if ( publishId == 0 || 
            salePrice == 0 || 
            amount == 0
        )
            revert Errors.InitParamsInvalid();
        {
 
            DataTypes.Publication memory publication =  IManager(MANAGER).getPublication(publishId);

             //Save 
            _dataByPublicationByProfile[publishId].projectId = publication.projectId;
            _dataByPublicationByProfile[publishId].currency = currency;
            _dataByPublicationByProfile[publishId].amount = amount;
            _dataByPublicationByProfile[publishId].salePrice = salePrice;
            _dataByPublicationByProfile[publishId].collectLimitPerAddress = collectLimitPerAddress;
            _dataByPublicationByProfile[publishId].utcTimestampStartAt = utcTimestampStartAt;
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
        // umImplemented();

    }

    function _processCollect(
        uint256 collectorSoulBoundTokenId,
        uint256 publishId, 
        uint96 payValue,
        bytes calldata data
    ) internal returns (DataTypes.RoyaltyAmounts memory royaltyAmounts){
        uint256 referrerSoulBoundTokenId;
        uint256 uints;
        
        if (data.length != 0) {
            (referrerSoulBoundTokenId, , uints) = abi.decode(
                data,
                (uint256, uint16,uint256)
            );
        }

        {
            // check utcTimestampStartAt
            if (_dataByPublicationByProfile[publishId].utcTimestampStartAt > block.timestamp) {
                revert Errors.CollectNotStartYet();
            }

            //check collect limit
            if (_dataByPublicationByProfile[publishId].collectLimitPerAddress > 0 && 
                uints > _dataByPublicationByProfile[publishId].collectLimitPerAddress) {
                revert Errors.CollectPerAddrLimitExceeded();
            }

            _collectCountPerAddress[publishId][collectorSoulBoundTokenId] += uints;

            if (_dataByPublicationByProfile[publishId].collectLimitPerAddress > 0 && 
                _collectCountPerAddress[publishId][collectorSoulBoundTokenId] > _dataByPublicationByProfile[publishId].collectLimitPerAddress)
              revert Errors.CollectPerAddrLimitExceeded();

        }
        
        unchecked {
            if (payValue > 0) {
               
               uint256 projectId = _dataByPublicationByProfile[publishId].projectId;

               (address treasury, ) = _treasuryData();
               IBankTreasury(treasury).distributeFundsToProjectFounderRevenue(
                    projectId,
                    _dataByPublicationByProfile[publishId].currency,
                    payValue
               );
            }
        }
    }

    function updateCollectLimitPerAddress(
        uint256 publishId, 
        uint16 collectLimitPerAddress
    ) external onlyManager {
        _dataByPublicationByProfile[publishId].collectLimitPerAddress = collectLimitPerAddress;
    }
    
}
