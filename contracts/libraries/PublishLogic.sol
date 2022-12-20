// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {Constants} from './Constants.sol';
import {IIncubator} from '../interfaces/IIncubator.sol';
import {IDerivativeNFTV1} from "../interfaces/IDerivativeNFTV1.sol";
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {IPublishModule} from '../interfaces/IPublishModule.sol';
import {IFollowModule} from '../interfaces/IFollowModule.sol';

/**
 * @title PublishLogic
 * @author bitsoul.xyz
 *
 * @notice This is the library that contains the logic for public & send to market place. 
 
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood.
 */
library PublishLogic {

    function createPublish(
        DataTypes.Publication memory publication,
        uint256 publishId,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile,
        mapping(address => bool) storage _collectModuleWhitelisted,
        mapping(address => bool) storage _publishModuleWhitelisted,
        mapping(uint256 => DataTypes.PublishData) storage _publishIdByProjectData
    ) external returns(uint256) {
        uint256 newTokenId;
        uint256 genesisSoulBoundTokenId;
        if (publication.fromTokenIds.length == 0)  {
            newTokenId =  IDerivativeNFTV1(publication.derivativeNFT).publish(
                publication
            );
            genesisSoulBoundTokenId = publication.soulBoundTokenId;
            //保存 
            _pubByIdByProfile[publication.projectId][newTokenId].projectId = publication.projectId;
            _pubByIdByProfile[publication.projectId][newTokenId].name = publication.name;
            _pubByIdByProfile[publication.projectId][newTokenId].description = publication.description;
            _pubByIdByProfile[publication.projectId][newTokenId].materialURIs = publication.materialURIs;
            _pubByIdByProfile[publication.projectId][newTokenId].fromTokenIds = publication.fromTokenIds;
            _pubByIdByProfile[publication.projectId][newTokenId].derivativeNFT = publication.derivativeNFT;

            emit Events.PublishDerivativeNFT(
                publication.soulBoundTokenId,
                publication.projectId,
                newTokenId,
                publication.amount,
                block.timestamp
            ); 

        }  else {
            //TODO
            genesisSoulBoundTokenId = 1; 

            //combo, mint when first collect
            emit Events.ComboDerivativeNFT(
                publication.soulBoundTokenId,
                publication.projectId,
                publishId,
                publication.amount,
                block.timestamp
            ); 
        }

        // bytes memory collectModuleReturnData = _initCollectModule(
        //         genesisSoulBoundTokenId,
        //         publication.soulBoundTokenId,
        //         publication.projectId,
        //         newTokenId,
        //         publication.amount,
        //         publication.collectModule,
        //         publication.collectModuleInitData,
        //         _pubByIdByProfile,
        //         _collectModuleWhitelisted
        // );

        // _initPublishModule(
        //     publishId,
        //     publication,
        //     _publishIdByProjectData,
        //     _publishModuleWhitelisted
        // );

        // _emitPublishCreated(
        //     publication,
        //     collectModuleReturnData
        // );
        
        return newTokenId;
    }

    function _emitPublishCreated(
        DataTypes.Publication memory publication,
        bytes memory collectModuleReturnData
    ) internal {
        emit Events.PublishCreated(
            publication,
            collectModuleReturnData,
            block.timestamp
        );
    }

    function _initCollectModule(
        uint256 genesisSoulBoundTokenId,
        uint256 ownerSoulBoundTokenId,
        uint256 projectId,
        uint256 newTokenId,
        uint256 amount,
        address collectModule,
        bytes memory collectModuleInitData,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile,
        mapping(address => bool) storage _collectModuleWhitelisted
    ) private returns (bytes memory) {
        if (!_collectModuleWhitelisted[collectModule]) revert Errors.CollectModuleNotWhitelisted();
        _pubByIdByProfile[projectId][newTokenId].collectModule = collectModule;
        return
            ICollectModule(collectModule).initializePublicationCollectModule(
                genesisSoulBoundTokenId,
                ownerSoulBoundTokenId,
                projectId,
                newTokenId,
                amount,
                collectModuleInitData
            );
    }
    
    //publish之前的初始化，扣费
    function _initPublishModule(
        uint256 publishId,
        DataTypes.Publication memory publication,
        mapping(uint256 => DataTypes.PublishData) storage _publishIdByProjectData,
        mapping(address => bool) storage _publishModuleWhitelisted
    ) private  {
        if (publication.publishModule == address(0)) return;
        if (!_publishModuleWhitelisted[publication.publishModule])
            revert Errors.PublishModuleNotWhitelisted();

        _publishIdByProjectData[publishId].publishModule = publication.publishModule;
        
        IPublishModule(publication.publishModule).initializePublishModule(
            publishId,
            publication
        );
    }

    /**
     * @notice Follows the given SoulBoundTokens, executing the necessary logic and module calls before add.
     * @param projectId The projectId to follow.
     * @param follower The address executing the follow.
     * @param soulBoundTokenId The profile token ID to follow.
     * @param followModuleData The follow module data parameters to pass to each profile's follow module.
     * @param _profileById A pointer to the storage mapping of profile structs by profile ID.
     * @param _profileIdByHandleHash A pointer to the storage mapping of profile IDs by handle hash.
     *
     */
    function follow(
        uint256 projectId,
        address follower,
        uint256 soulBoundTokenId,
        bytes calldata followModuleData,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
        mapping(bytes32 => uint256) storage _profileIdByHandleHash
    ) external {

        string memory handle = _profileById[soulBoundTokenId].handle;
        if (_profileIdByHandleHash[keccak256(bytes(handle))] != soulBoundTokenId)
            revert Errors.TokenDoesNotExist();

        address followModule = _profileById[soulBoundTokenId].followModule;
        //调用followModule的processFollow函数进行后续处理
        if (followModule != address(0)) {
            IFollowModule(followModule).processFollow(
                follower,
                soulBoundTokenId,
                followModuleData
            );
        }
        emit Events.Followed(projectId, follower, soulBoundTokenId, followModuleData, block.timestamp);
    }
   

    /**
     * @notice Collects the given dNFT, executing the necessary logic and module call before minting the
     * collect NFT to the toSoulBoundTokenId.
     * 
     * @param collectData The collect Data struct
     * @param tokenId The collect tokenId
     * @param derivativeNFT The dNFT contract
     * @param _pubByIdByProfile The collect Data struct
     * @return The new tokenId
     */
    function collectDerivativeNFT(
        DataTypes.CollectData calldata collectData,
        uint256 tokenId,
        address derivativeNFT,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile
    ) external returns(uint256) {

        address collectModule = _pubByIdByProfile[collectData.projectId][tokenId].collectModule;
        uint256 newTokenId = IDerivativeNFTV1(derivativeNFT).split(tokenId, collectData.toSoulBoundTokenId, collectData.value);

        //新生成的tokenId也需要用collectModule来处理
        _pubByIdByProfile[collectData.projectId][newTokenId].collectModule = collectModule;

        //后续调用processCollect进行处理，此机制能扩展出联动合约调用
        ICollectModule(collectModule).processCollect(
            collectData.fromSoulBoundTokenId,
            collectData.toSoulBoundTokenId,
            collectData.projectId,
            tokenId, //dNFTc tokenId
            collectData.value,
            collectData.collectModuleData
        );



        emit Events.CollectDerivativeNFT(
            collectData.projectId,
            derivativeNFT,
            collectData.fromSoulBoundTokenId,
            // collectData.collector,
            collectData.toSoulBoundTokenId,
            tokenId,
            collectData.value,
            newTokenId,
            block.timestamp
        );

        return newTokenId;
    }
    
/*
    function split(
        address derivativeNFT,
        uint256 fromSoulBoundTokenId, 
        uint256 toSoulBoundTokenId, 
        uint256 tokenId, 
        uint256 amount, 
        bytes calldata splitModuleData
    ) external returns(uint256){
         uint256 originalValue = IERC3525(derivativeNFT).balanceOf(tokenId);
         if (originalValue <= amount) revert Errors.InsufficientFund();

         uint256 newTokenId = IDerivativeNFTV1(derivativeNFT).split(
            toSoulBoundTokenId,
            tokenId,
            amount
         );
         
         //TODO
         splitModuleData;

         emit Events.SplitDerivativeNFT(
            fromSoulBoundTokenId,
            toSoulBoundTokenId,
            tokenId,
            originalValue,
            newTokenId,
            amount,
            block.timestamp
         );

         return newTokenId;

    }
    */
}    