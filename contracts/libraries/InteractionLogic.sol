// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IncubatorProxy} from '../upgradeability/IncubatorProxy.sol';
import {DerivativeNFTProxy} from '../upgradeability/DerivativeNFTProxy.sol';
// import {Helpers} from './Helpers.sol';
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {Constants} from './Constants.sol';
import {IIncubator} from '../interfaces/IIncubator.sol';
import {IDerivativeNFTV1} from "../interfaces/IDerivativeNFTV1.sol";
import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {ICollectModule} from '../interfaces/ICollectModule.sol';
// import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
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
     * @param follower The address executing the follow.
     * @param soulBoundTokenIds The array of profile token IDs to follow.
     * @param followModuleDatas The array of follow module data parameters to pass to each profile's follow module.
     * @param _profileById A pointer to the storage mapping of profile structs by profile ID.
     * @param _profileIdByHandleHash A pointer to the storage mapping of profile IDs by handle hash.
     *
     */
    function follow(
        address follower,
        uint256[] calldata soulBoundTokenIds,
        bytes[] calldata followModuleDatas,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
        mapping(bytes32 => uint256) storage _profileIdByHandleHash
    ) external {
        if (soulBoundTokenIds.length != followModuleDatas.length) revert Errors.ArrayMismatch();

        for (uint256 i = 0; i < soulBoundTokenIds.length; ) {
            string memory handle = _profileById[soulBoundTokenIds[i]].handle;
            if (_profileIdByHandleHash[keccak256(bytes(handle))] != soulBoundTokenIds[i])
                revert Errors.TokenDoesNotExist();

            address followModule = _profileById[soulBoundTokenIds[i]].followModule;
            //调用followModule的processFollow函数进行后续处理
            if (followModule != address(0)) {
                IFollowModule(followModule).processFollow(
                    follower,
                    soulBoundTokenIds[i],
                    followModuleDatas[i]
                );
            }
            unchecked {
                ++i;
            }
        }
        emit Events.Followed(follower, soulBoundTokenIds, followModuleDatas, block.timestamp);

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
     * @param collector The address executing the collect.
     * @param fromSoulBoundTokenId The SBT ID of the publication.
     * @param toSoulBoundTokenId The SBT ID of the collector.
     * @param tokenId The publication ID of the publication being collected. 要收集的发布的发布ID
     * @param value The data to pass to the publication's collect module.
     * @param collectModuleData The data to pass to the publication's collect module.
     * @param _pubByIdByProfile A pointer to the storage mapping of publications by pubId by profile ID.
     * @param _incubatorBySoulBoundTokenId storage of incubator mapping
     *
     */
    function collectDerivativeNFT(
        address collector,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata collectModuleData,
        mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct))
            storage _pubByIdByProfile,
        mapping(uint256 => address) storage _incubatorBySoulBoundTokenId

    ) external {
        //TODO
        address toIncubator = _incubatorBySoulBoundTokenId[toSoulBoundTokenId];
        if (toIncubator == address(0)) {
            toIncubator = _deployIncubatorContract(toSoulBoundTokenId);
            _incubatorBySoulBoundTokenId[toSoulBoundTokenId] = toIncubator;
        }
        address fromIncubator =  _incubatorBySoulBoundTokenId[fromSoulBoundTokenId];
        IERC3525(fromIncubator).transferFrom(tokenId, toIncubator, value);

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
            fromSoulBoundTokenId,
            collector,
            toSoulBoundTokenId,
            tokenId,
            value,
            block.timestamp
        );
    }

    function _deployIncubatorContract(
       uint256  soulBoundTokenId
    ) private returns (address) {
        bytes memory functionData = abi.encodeWithSelector(
            IIncubator.initialize.selector,
            soulBoundTokenId
        );
        address incubatorContract = address(new IncubatorProxy(functionData));
        emit Events.IncubatorContractDeployed(soulBoundTokenId, incubatorContract, block.timestamp);
        return incubatorContract;
    }

    function createEvent(
        uint256 soulBoundTokenId,
        DataTypes.Event memory event_,
        address metadataDescriptor_,
        bytes calldata collectModuleData,
        mapping(bytes32 => uint256) storage _eventNameHashByEventId,
        mapping(uint256 => address) storage _derivativeNFTByEventId
    ) external returns(uint256) {
         
        uint256 eventId = _eventNameHashByEventId[keccak256(bytes(event_.eventName))];
        if (eventId == 0) {
               address derivatveNFT = _deployDerivativeNFT(
                    soulBoundTokenId,
                    event_.eventName,event_.eventDescription,
                    metadataDescriptor_
                );
                eventId = IDerivativeNFTV1(derivatveNFT).createEvent(event_);
                _derivativeNFTByEventId[eventId] = derivatveNFT;

                //TODO 
        }

        return eventId;
        
    }


    function transfer(
        uint256 fromSoulBoundTokenId, 
        uint256 toSoulBoundTokenId, 
        uint256 tokenId, 
        uint256 amount, 
        bytes[] calldata datas
    ) external{
        //TODO
    }

    function _deployDerivativeNFT(
       uint256  soulBoundTokenId,
       string memory name_,
       string memory symbol_,
       address metadataDescriptor_
    ) private returns (address) {
        bytes memory functionData = abi.encodeWithSelector(
            IDerivativeNFTV1.initialize.selector,
            name_,
            symbol_,
            soulBoundTokenId,
            metadataDescriptor_
        );
        address derivativeNFT = address(new DerivativeNFTProxy(functionData));
        emit Events.DerivativeNFTDeployed(soulBoundTokenId, derivativeNFT, block.timestamp);
        return derivativeNFT;
    }
    
}
