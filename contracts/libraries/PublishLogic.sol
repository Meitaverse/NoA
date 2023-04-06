// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {INFTDerivativeProtocolTokenV1} from "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import './Constants.sol';
import {IDerivativeNFT} from "../interfaces/IDerivativeNFT.sol";
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {IPublishModule} from '../interfaces/IPublishModule.sol';
import {IBankTreasury} from '../interfaces/IBankTreasury.sol';

/**
 * @title PublishLogic
 * @author bitsoul Protocol
 *
 * @notice This is the library that contains the logic for public & send to market place. 
 
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood.
 */
library PublishLogic {
    function prePublish(
        DataTypes.Publication memory publication,
        uint256 publishId,
        uint256 previousPublishId,
        uint256 treasuryOfSoulBoundTokenId,
        mapping(uint256 => DataTypes.PublishData) storage _projectDataByPublishId
    ) external {
        
        uint256 publishTaxAmount = _initPublishModule(
            publishId,
            previousPublishId,
            treasuryOfSoulBoundTokenId,
            publication,
            _projectDataByPublishId
        );
 
        emit Events.PublishPrepared(
            publishId,
            previousPublishId,
            publishTaxAmount
        );
    }

    function updatePublish(
        uint256 publishId,
        uint256 salePrice,
        uint16 royaltyBasisPoints,
        uint256 amount,
        string memory name,
        string memory description,
        string[] memory materialURIs,
        uint256[] memory fromTokenIds,
        mapping(uint256 => DataTypes.PublishData) storage _projectDataByPublishId
    ) external {

        _projectDataByPublishId[publishId].publication.salePrice = salePrice;
        _projectDataByPublishId[publishId].publication.royaltyBasisPoints = royaltyBasisPoints;
        _projectDataByPublishId[publishId].publication.amount = amount;
        _projectDataByPublishId[publishId].publication.name = name;
        _projectDataByPublishId[publishId].publication.description = description;
        _projectDataByPublishId[publishId].publication.materialURIs = materialURIs;
        _projectDataByPublishId[publishId].publication.fromTokenIds = fromTokenIds;

        uint256  addedPublishTaxes = IPublishModule(_projectDataByPublishId[publishId].publication.publishModule).updatePublish(
            publishId,
            salePrice,
            royaltyBasisPoints,
            amount,
            name,
            description,
            materialURIs,
            fromTokenIds
        );

        emit Events.PublishUpdated(
            publishId,
            addedPublishTaxes 
        );
    }

    function createPublish(
        DataTypes.Publication memory publication,
        uint256 publishId,
        address publisher,
        address derivativeNFT,
        uint16 bps,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile
    ) external returns(uint256) {
        
        if (derivativeNFT == address(0)) revert Errors.DerivativeNFTIsZero();
        if (publisher == address(0)) revert Errors.PublisherIsZero();
        
        emit Events.PublishCreated(
            publishId,
            publication.soulBoundTokenId,
            publication.hubId,
            publication.projectId,
            publication.amount,
            publication.collectModuleInitData
        );

        uint256 newTokenId =  IDerivativeNFT(derivativeNFT).publish(
            publishId,
            publication,
            publisher,
            bps
        );
        
        //Avoids stack too deep
        {
            //save
            _pubByIdByProfile[publication.projectId][newTokenId].publishId = publishId;
            _pubByIdByProfile[publication.projectId][newTokenId].hubId = publication.hubId;
            _pubByIdByProfile[publication.projectId][newTokenId].projectId = publication.projectId;
            _pubByIdByProfile[publication.projectId][newTokenId].name = publication.name;
            _pubByIdByProfile[publication.projectId][newTokenId].description = publication.description;
            _pubByIdByProfile[publication.projectId][newTokenId].materialURIs = publication.materialURIs;
            _pubByIdByProfile[publication.projectId][newTokenId].fromTokenIds = publication.fromTokenIds;
            _pubByIdByProfile[publication.projectId][newTokenId].derivativeNFT = derivativeNFT;
            _pubByIdByProfile[publication.projectId][newTokenId].publishModule = publication.publishModule;

            _initCollectModule(
                    publication.projectId,
                    publishId,
                    newTokenId,
                    publication.currency,
                    publication.amount,
                    publication.collectModule,
                    publication.collectModuleInitData,
                    _pubByIdByProfile
            );
        }
        
        emit Events.PublishMinted(publishId, newTokenId);
        
        return newTokenId;
    }

    function _initCollectModule(
        uint256 projectId,
        uint256 publishId,
        uint256 newTokenId,
        address currency,
        uint256 amount,
        address collectModule,
        bytes memory collectModuleInitData,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile         
    ) private {
         _pubByIdByProfile[projectId][newTokenId].collectModule = collectModule;
        
        ICollectModule(collectModule).initializePublicationCollectModule(
            publishId,
            currency,
            amount,
            collectModuleInitData 
        );
    }

    //initial publishModule and chargeing a fee
    function _initPublishModule(
        uint256 publishId,
        uint256 previousPublishId,
        uint256 treasuryOfSoulBoundTokenId,
        DataTypes.Publication memory publication,
        mapping(uint256 => DataTypes.PublishData) storage _projectDataByPublishId
    ) private returns(uint256) {
        
        if (_projectDataByPublishId[publishId].previousPublishId == 0) _projectDataByPublishId[publishId].previousPublishId = publishId;
      
        _projectDataByPublishId[publishId].publication = publication;
        _projectDataByPublishId[publishId].previousPublishId = previousPublishId;
        _projectDataByPublishId[publishId].isMinted = false;
        _projectDataByPublishId[publishId].tokenId = 0;
        
        return IPublishModule(publication.publishModule).initializePublishModule(
            publishId,
            previousPublishId,
            treasuryOfSoulBoundTokenId,
            publication 
        );
    }

    /**
     * @notice Collects the given dNFT, executing the necessary logic and module call before minting the
     * collect dNFT to the toSoulBoundTokenId.
     * 
     * @param collectDataParam The collect Data parameters
     * @param _pubByIdByProfile The collect Data struct
     * @param _projectDataByPublishId The collect Data struct
     */
    function collectDerivativeNFT(
        DataTypes.CollectDataParam calldata collectDataParam,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile,
        mapping(uint256 => DataTypes.PublishData) storage _projectDataByPublishId
    ) external {
        if (collectDataParam.publishId == 0) revert Errors.InitParamsInvalid();
        if (collectDataParam.collectorSoulBoundTokenId == 0) revert Errors.InitParamsInvalid();
        if (collectDataParam.collectUnits == 0) revert Errors.InitParamsInvalid();

        uint256 projectId = _projectDataByPublishId[collectDataParam.publishId].publication.projectId;

        //new tokenId use the same collectModule
        _pubByIdByProfile[projectId][collectDataParam.newTokenId].collectModule = _pubByIdByProfile[projectId][collectDataParam.tokenId].collectModule;

        uint96 payValue = uint96(collectDataParam.collectUnits * _projectDataByPublishId[collectDataParam.publishId].publication.salePrice);

        if (collectDataParam.sbt == _projectDataByPublishId[collectDataParam.publishId].publication.currency) {
            //Transfer Value of total pay to treasury, then in the collectModule processCollect, the treasury will transfer the value to the earnest funds of collector 
            INFTDerivativeProtocolTokenV1(collectDataParam.sbt).transferValue(
                collectDataParam.collectorSoulBoundTokenId, 
                BANK_TREASURY_SOUL_BOUND_TOKENID, 
                payValue
            );
        } else {
            //Use free earnest funs balance for pay, then in the collectModule processCollect, the treasury will transfer the value to the earnest funds of collector 
            IBankTreasury(collectDataParam.treasury).useEarnestFundsForPay(
                collectDataParam.collectorSoulBoundTokenId, 
                _projectDataByPublishId[collectDataParam.publishId].publication.currency,
                payValue
            );
        }

        //processCollect: fees and royalties process
        ICollectModule(_pubByIdByProfile[projectId][collectDataParam.tokenId].collectModule).processCollect(
            _projectDataByPublishId[collectDataParam.publishId].publication.soulBoundTokenId,
            collectDataParam.collectorSoulBoundTokenId,
            collectDataParam.publishId,
            payValue, 
            collectDataParam.data 
        );

        emit Events.DerivativeNFTCollected(
            projectId,
            collectDataParam.derivativeNFT,
            _projectDataByPublishId[collectDataParam.publishId].publication.soulBoundTokenId,
            collectDataParam.collectorSoulBoundTokenId,
            collectDataParam.tokenId,
            collectDataParam.collectUnits,
            collectDataParam.newTokenId
        );
    }
    
    function airdrop(
        address derivativeNFT, 
        DataTypes.AirdropData memory airdropData,
        mapping(uint256 => address) storage _soulBoundTokenIdToWallet,
        mapping(uint256 => DataTypes.PublishData) storage _projectDataByPublishId
    ) external {
        if (derivativeNFT == address(0)) revert Errors.InvalidParameter();
        
        uint256 total;
        for (uint256 i = 0; i < airdropData.values.length; ) {
            total = total + airdropData.values[i];
            unchecked {
                ++i;
            }
        }
        if (total > IERC3525(derivativeNFT).balanceOf( airdropData.tokenId )) 
          revert Errors.ERC3525INSUFFICIENTBALANCE();
          
        uint256[] memory newTokenIds = new uint256[](airdropData.toSoulBoundTokenIds.length);
        for (uint256 i = 0; i < airdropData.toSoulBoundTokenIds.length; ) {
            address toWallet = _soulBoundTokenIdToWallet[airdropData.toSoulBoundTokenIds[i]];
            if (toWallet == address(0)) revert Errors.ToWalletIsZero();
            uint256 newTokenId = IDerivativeNFT(derivativeNFT).split(
                airdropData.publishId,
                airdropData.tokenId, 
                toWallet,
                airdropData.values[i]
            );

            newTokenIds[i] = newTokenId;

            unchecked {
                ++i;
            }
        }

        emit Events.DerivativeNFTAirdroped(
            _projectDataByPublishId[airdropData.publishId].publication.projectId,
            airdropData.publishId,
            derivativeNFT,
            airdropData.ownershipSoulBoundTokenId,
            airdropData.tokenId,
            airdropData.toSoulBoundTokenIds,
            airdropData.values,
            newTokenIds,
            block.timestamp
        );
    }

    function updateCollectLimitPerAddress(
        address collectModule,
        uint256 publishId, 
        uint16 collectLimitPerAddress
    ) 
        external 
    {
       ICollectModule(collectModule).updateCollectLimitPerAddress(
            publishId,
            collectLimitPerAddress
        );

    }
}    