// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IncubatorProxy} from '../upgradeability/IncubatorProxy.sol';
import {DerivativeNFTProxy} from '../upgradeability/DerivativeNFTProxy.sol';
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {Constants} from './Constants.sol';
import {IIncubator} from '../interfaces/IIncubator.sol';
import {IDerivativeNFTV1} from "../interfaces/IDerivativeNFTV1.sol";
import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";

/**
 * @title InteractionLogic
 * @author bitsoul.xyz
 *
 * @notice This is the library that contains the logic for follows & collects. 
 
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood.
 */
library InteractionLogic {
    using Strings for uint256;

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
     * @notice Emits the `Collected` event that signals that a successful collect action has occurred.
     *
     * @dev This is done through this function to prevent stack too deep compilation error.
     *
     * @param collector The address collecting the publication.
     * @param profileId The token ID of the profile that the collect was initiated towards, useful to differentiate mirrors.
     * @param pubId The publication ID that the collect was initiated towards, useful to differentiate mirrors.
     * @param rootProfileId The profile token ID of the profile whose publication is being collected.
     * @param rootPubId The publication ID of the publication being collected.
     * @param data The data passed to the collect module.
     */
    function _emitCollectedEvent(
        address collector,
        uint256 profileId,
        uint256 pubId,
        uint256 rootProfileId,
        uint256 rootPubId,
        bytes calldata data
    ) private {
        emit Events.Collected(
            collector,
            profileId,
            pubId,
            rootProfileId,
            rootPubId,
            data,
            block.timestamp
        );
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

   function airdropDerivativeNFT(
        uint256 projectId,
        address derivatveNFT,
        address operator,
        uint256 fromSoulBoundTokenId,
        uint256[] memory toSoulBoundTokenIds,
        uint256 tokenId,
        uint256[] memory values,
        bytes[] calldata airdropModuledatas,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile
    ) external {
        if (toSoulBoundTokenIds.length != values.length) revert Errors.LengthNotSame();
        for (uint256 i = 0; i < toSoulBoundTokenIds.length; ) {
           uint256 newTokenId = IDerivativeNFTV1(derivatveNFT).split(tokenId, toSoulBoundTokenIds[i], values[i]);

            //后续处理，此机制能扩展出联动合约调用
            // airdropModuleDatas;

            // address collectModule = _pubByIdByProfile[fromSoulBoundTokenId][tokenId].collectModule;

            // ICollectModule(collectModule).processCollect(
            //     fromSoulBoundTokenId,
            //     operator,
            //     toSoulBoundTokenIds[i],
            //     tokenId,
            //     values[i],
            //     airdropModuleData
            // );

            emit Events.AirdropDerivativeNFT(
                projectId,
                derivatveNFT,
                fromSoulBoundTokenId,
                operator,
                toSoulBoundTokenIds[i],
                tokenId,
                values[i],
                newTokenId,
                block.timestamp
            );

            unchecked {
                ++i;
            }
        }
    }

    function deployIncubatorContract(
       uint256  soulBoundTokenId
    ) external returns (address) {
        bytes memory functionData = abi.encodeWithSelector(
            IIncubator.initialize.selector,
            soulBoundTokenId
        );
        address incubatorContract = address(new IncubatorProxy(functionData));
        emit Events.IncubatorContractDeployed(soulBoundTokenId, incubatorContract, block.timestamp);
        return incubatorContract;
    }

    function createHub(
        address creater, 
        uint256 soulBoundTokenId,
        uint256 hubId,
        DataTypes.Hub memory hub,
        bytes calldata createHubModuleData,
        mapping(uint256 => DataTypes.Hub) storage _hubInfos
    ) external {
         _hubInfos[hubId] = DataTypes.Hub({
             soulBoundTokenId : soulBoundTokenId,
             name: hub.name,
             description: hub.description,
             image: hub.image,
             metadataURI: hub.metadataURI
        });

        //TODO
        createHubModuleData;

        emit Events.CreateHub(creater, soulBoundTokenId, hubId, uint32(block.timestamp));

    }

    function createProject(
        uint256 hubId,
        uint256 projectId,
        uint256 soulBoundTokenId,
        DataTypes.Project memory project,
        address metadataDescriptor,
        bytes calldata projectModuleData,
        mapping(uint256 => address) storage _derivativeNFTByProjectId
    ) external returns(uint256) {
         
        if(_derivativeNFTByProjectId[projectId] == address(0)) {
               address derivatveNFT = _deployDerivativeNFT(
                    hubId,
                    projectId,
                    soulBoundTokenId,
                    project.name, 
                    project.description,
                    metadataDescriptor
                );
                _derivativeNFTByProjectId[projectId] = derivatveNFT;
        }
        //TODO, pre and toggle
        projectModuleData;

        return projectId;
        
    }

    function _deployDerivativeNFT(
        uint256 hubId,
        uint256 projectId,
        uint256  soulBoundTokenId,
        string memory name_,
        string memory symbol_,
        address metadataDescriptor_
    ) private returns (address) {
        bytes memory functionData = abi.encodeWithSelector(
            IDerivativeNFTV1.initialize.selector,
            name_,
            symbol_,
            hubId,
            projectId,
            soulBoundTokenId,
            metadataDescriptor_
        );
        address derivativeNFT = address(new DerivativeNFTProxy(functionData));
        emit Events.DerivativeNFTDeployed(hubId, soulBoundTokenId, derivativeNFT, block.timestamp);
        return derivativeNFT;
    } 
    
     function transferDerivativeNFT(
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 projectId,
        address derivatveNFT,
        address fromIncubator,
        address toIncubator,
        uint256 tokenId,
        bytes calldata transferModuledata
    ) external {
    
         IERC3525(derivatveNFT).transferFrom(fromIncubator, toIncubator, tokenId);

         //TODO process data
         transferModuledata;

         emit Events.TransferDerivativeNFT(
            fromSoulBoundTokenId,
            toSoulBoundTokenId,
            projectId,
            tokenId,
            block.timestamp
         );

    }

    function transferValueDerivativeNFT(
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 projectId,
        address derivatveNFT,
        address toIncubator,
        uint256 tokenId,
        uint256 value,
        bytes calldata transferValueModuledata
    ) external {
    
        uint256 newTokenId = IERC3525(derivatveNFT).transferFrom(tokenId, toIncubator, value);

         //TODO process data
         transferValueModuledata;

         emit Events.TransferValueDerivativeNFT(
            fromSoulBoundTokenId,
            toSoulBoundTokenId,
            projectId,
            tokenId,
            value,
            newTokenId,
            block.timestamp
         );

    }
}
