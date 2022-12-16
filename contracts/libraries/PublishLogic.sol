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
import {IFollowModule} from '../interfaces/IFollowModule.sol';

/**
 * @title PublishLogic
 * @author bitsoul.xyz
 *
 * @notice This is the library that contains the logic for public & send to market place. 
 
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood.
 */
library PublishLogic {

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
     * @notice Collects the given publication, executing the necessary logic and module call before minting the
     * collect NFT to the collector.
     *收集给定的发布(非NFT), 在铸造collectNFT之前执行必要的逻辑及call模块
     * @param derivatveNFT The address derivatveNFT contract 
     * @param collector The address executing the collect.
     * @param fromSoulBoundTokenId The SBT ID of the publication.
     * @param toSoulBoundTokenId The SBT ID of the collector.
     * @param tokenId The token id 
     * @param value  value to collect
     * @param collectModuleData The data to pass to the publication's collect module.
     * @param _pubByIdByProfile A pointer to the storage mapping of publications by pubId by profile ID.
     *
     */
    function collectDerivativeNFT(
        uint256 projectId,
        address derivatveNFT,
        address collector,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata collectModuleData,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile
    ) external {
        uint256 newTokenId = IDerivativeNFTV1(derivatveNFT).split(tokenId, toSoulBoundTokenId, value);

        //后续调用processCollect进行处理，此机制能扩展出联动合约调用
        address collectModule = _pubByIdByProfile[fromSoulBoundTokenId][tokenId].collectModule;

        ICollectModule(collectModule).processCollect(
            fromSoulBoundTokenId,
            collector,
            toSoulBoundTokenId,
            tokenId,
            value,
            collectModuleData
        );

        emit Events.CollectDerivativeNFT(
            projectId,
            derivatveNFT,
            fromSoulBoundTokenId,
            collector,
            toSoulBoundTokenId,
            tokenId,
            value,
            newTokenId,
            block.timestamp
        );
    }

    function publish(
        uint256 projectId,
        DataTypes.Publication memory publication,
        address derivatveNFT,
        uint256 soulBoundTokenId, 
        uint256 amount,
        bytes calldata publishModuleData
    ) external returns(uint256) {
       uint256 newTokenId =  IDerivativeNFTV1(derivatveNFT).publish(
            soulBoundTokenId, 
            publication, 
            amount
        );
       
        emit Events.PublishDerivativeNFT(
            soulBoundTokenId,
            projectId,
            newTokenId,
            amount,
            block.timestamp
        ); 

        //TODO publishModule
        publishModuleData;

       return newTokenId;
    }

    function split(
        address derivatveNFT,
        uint256 fromSoulBoundTokenId, 
        uint256 toSoulBoundTokenId, 
        uint256 tokenId, 
        uint256 amount, 
        bytes calldata splitModuleData
    ) external returns(uint256){
         uint256 originalValue = IERC3525(derivatveNFT).balanceOf(tokenId);
         if (originalValue <= amount) revert Errors.InsufficientFund();

         uint256 newTokenId = IDerivativeNFTV1(derivatveNFT).split(
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
}    