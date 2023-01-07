// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {Constants} from './Constants.sol';
import {IDerivativeNFTV1} from "../interfaces/IDerivativeNFTV1.sol";
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {IPublishModule} from '../interfaces/IPublishModule.sol';
/**
 * @title PublishLogic
 * @author bitsoul.xyz
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
        mapping(uint256 => DataTypes.PublishData) storage _publishIdByProjectData
    ) external {
        
        uint256 publishTaxAmount = _initPublishModule(
            publishId,
            previousPublishId,
            treasuryOfSoulBoundTokenId,
            publication,
            _publishIdByProjectData
        );
 
        emit Events.PublishPrepared(
            publication,
            publishId,
            previousPublishId,
            publishTaxAmount,
            block.timestamp
        );
    }

    function updatePublish(
        uint256 publishId,
        uint256 salePrice,
        uint256 royaltyBasisPoints,
        uint256 amount,
        string memory name,
        string memory description,
        string[] memory materialURIs,
        uint256[] memory fromTokenIds,
        mapping(uint256 => DataTypes.PublishData) storage _publishIdByProjectData
    )external {

        _publishIdByProjectData[publishId].publication.salePrice = salePrice;
        _publishIdByProjectData[publishId].publication.royaltyBasisPoints = royaltyBasisPoints;
        _publishIdByProjectData[publishId].publication.amount = amount;
        _publishIdByProjectData[publishId].publication.name = name;
        _publishIdByProjectData[publishId].publication.description = description;
        _publishIdByProjectData[publishId].publication.materialURIs = materialURIs;
        _publishIdByProjectData[publishId].publication.fromTokenIds = fromTokenIds;

        uint256  addedPublishTaxes = IPublishModule(_publishIdByProjectData[publishId].publication.publishModule).updatePublish(
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
            _publishIdByProjectData[publishId].publication.soulBoundTokenId,
            salePrice,
            royaltyBasisPoints,
            amount,
            name,
            description,
            materialURIs,
            fromTokenIds,
            addedPublishTaxes,
            block.timestamp
        );
    }

    function createPublish(
        DataTypes.Publication memory publication,
        uint256 publishId,
        address publisher,
        address derivativeNFT,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile
    ) external returns(uint256) {
        
        if (derivativeNFT == address(0)) revert Errors.DerivativeNFTIsZero();
        if (publisher == address(0)) revert Errors.PublisherIsZero();

        uint256 newTokenId =  IDerivativeNFTV1(derivativeNFT).publish(
            publishId,
            publication,
            publisher
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
                    publication.soulBoundTokenId,
                    newTokenId,
                    publication.amount,
                    publication.collectModule,
                    publication.collectModuleInitData,
                    _pubByIdByProfile
            );

            emit Events.PublishCreated(
                publishId,
                publication.soulBoundTokenId,
                publication.hubId,
                publication.projectId,
                newTokenId,
                publication.amount,
                publication.collectModuleInitData,
                block.timestamp
            );
        }
       
        return newTokenId;
    }

    function _initCollectModule(
        uint256 projectId,
        uint256 publishId,
        uint256 ownershipSoulBoundTokenId,
        uint256 newTokenId,
        uint256 amount,
        address collectModule,
        bytes memory collectModuleInitData,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile         
    ) private {
         _pubByIdByProfile[projectId][newTokenId].collectModule = collectModule;
        
        ICollectModule(collectModule).initializePublicationCollectModule(
                publishId,
                ownershipSoulBoundTokenId,
                newTokenId,
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
        mapping(uint256 => DataTypes.PublishData) storage _publishIdByProjectData
    ) private  returns(uint256) {
        
        if (_publishIdByProjectData[publishId].previousPublishId == 0) _publishIdByProjectData[publishId].previousPublishId = publishId;
      
        _publishIdByProjectData[publishId].publication = publication;
        _publishIdByProjectData[publishId].previousPublishId = previousPublishId;
        _publishIdByProjectData[publishId].isMinted = false;
        _publishIdByProjectData[publishId].tokenId = 0;
        
        return IPublishModule(publication.publishModule).initializePublishModule(
            publishId,
            previousPublishId,
            treasuryOfSoulBoundTokenId,
            publication 
        );
    }

    /**
     * @notice Collects the given dNFT, executing the necessary logic and module call before minting the
     * collect NFT to the toSoulBoundTokenId.
     * 
     * @param collectData The collect Data struct
     * @param tokenId The collect tokenId
     * @param newTokenId The new tokenId after collected
     * @param derivativeNFT The dNFT contract
     * @param _pubByIdByProfile The collect Data struct
     * @param _publishIdByProjectData The collect Data struct
     */
    function collectDerivativeNFT(
        DataTypes.CollectData calldata collectData,
        uint256 tokenId,
        uint256 newTokenId,
        address derivativeNFT,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile,
        mapping(uint256 => DataTypes.PublishData) storage _publishIdByProjectData
    ) external {
        if (collectData.publishId == 0) revert Errors.InitParamsInvalid();
        if (collectData.collectorSoulBoundTokenId == 0) revert Errors.InitParamsInvalid();
        if (collectData.collectValue == 0) revert Errors.InitParamsInvalid();

        if ( derivativeNFT== address(0)) 
            revert Errors.DerivativeNFTIsZero();

        uint256 projectId = _publishIdByProjectData[collectData.publishId].publication.projectId;

        //新生成的tokenId也需要用collectModule来处理
        _pubByIdByProfile[projectId][newTokenId].collectModule = _pubByIdByProfile[projectId][tokenId].collectModule;

        uint256 ownershipSoulBoundTokenId = _publishIdByProjectData[collectData.publishId].publication.soulBoundTokenId;

        //后续调用processCollect进行处理，此机制能扩展出联动合约调用
        ICollectModule(_pubByIdByProfile[projectId][tokenId].collectModule).processCollect(
            ownershipSoulBoundTokenId,
            collectData.collectorSoulBoundTokenId,
            collectData.publishId,
            collectData.collectValue,
            collectData.data 
        );

        emit Events.DerivativeNFTCollected(
            projectId,
            derivativeNFT,
            ownershipSoulBoundTokenId,
            collectData.collectorSoulBoundTokenId,
            tokenId,
            collectData.collectValue,
            newTokenId,
            block.timestamp
        );
    }
    
    function airdrop(
        address derivativeNFT, 
        DataTypes.AirdropData memory airdropData,
        mapping(uint256 => address) storage _soulBoundTokenIdToWallet,
        mapping(uint256 => uint256) storage _tokenIdByPublishId,
        mapping(uint256 => DataTypes.PublishData) storage _publishIdByProjectData
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
            uint256 newTokenId = IDerivativeNFTV1(derivativeNFT).split(
                _tokenIdByPublishId[airdropData.tokenId],
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
            _publishIdByProjectData[airdropData.publishId].publication.projectId,
            derivativeNFT,
            airdropData.ownershipSoulBoundTokenId,
            airdropData.tokenId,
            airdropData.toSoulBoundTokenIds,
            airdropData.values,
            newTokenIds,
            block.timestamp
        );
    }
}    