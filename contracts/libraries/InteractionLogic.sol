// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import './Constants.sol';
import {IDerivativeNFT} from "../interfaces/IDerivativeNFT.sol";
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";

import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';

/**
 * @title InteractionLogic
 * @author bitsoul
 *
 * @notice This is the library that contains the logic for follows & collects. 
 
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood.
 */

library InteractionLogic {
    using Strings for uint256;
    
    function createHub(
        address hubOwner,
        uint256 hubId,
        DataTypes.HubData memory hub,
        mapping(uint256 => DataTypes.HubData) storage _hubInfos
    ) external {
        
        if (hubId == 0) revert Errors.HubIdIsZero();
        
         _hubInfos[hubId] = DataTypes.HubData({
            //  hubOwner: creator,
             soulBoundTokenId : hub.soulBoundTokenId,
             name: hub.name,
             description: hub.description,
             imageURI: hub.imageURI
        });

        emit Events.HubCreated(
            hub.soulBoundTokenId, 
            hubOwner, 
            hubId,
            hub.name,
            hub.description,
            hub.imageURI,
            uint32(block.timestamp)
        );

    }
    
    function updateHub(
        address hubOwner,
        uint256 hubId,
        string memory name,
        string memory description,
        string memory imageURI,
        mapping(uint256 => DataTypes.HubData) storage _hubInfos
    ) external {
        
        if (hubId == 0) revert Errors.HubIdIsZero();
        DataTypes.HubData storage hubData = _hubInfos[hubId];
        hubData.name = name;
        hubData.description = description;
        hubData.imageURI = imageURI;
 
        emit Events.HubUpdated(
            hubId,
            hubOwner, 
            name,
            description,
            imageURI,
            uint32(block.timestamp)
        );
    }

    function createProject(
        address creator,
        address derivativeImpl,
        address sbt,
        address treasury,
        address marketPlace,
        uint256 projectId,
        DataTypes.ProjectData memory project,
        address receiver,
        mapping(uint256 => address) storage _derivativeNFTByProjectId,
        mapping(uint256 => DataTypes.ProjectData) storage _projectInfoByProjectId
    ) external returns(address) {
        address derivativeNFT;
        if(_derivativeNFTByProjectId[projectId] == address(0)) {
                derivativeNFT = _deployDerivativeNFT(
                    creator,
                    derivativeImpl,
                    sbt,
                    treasury,
                    marketPlace,
                    projectId,
                    project,
                    receiver
                );
                _derivativeNFTByProjectId[projectId] = derivativeNFT;
        }

        _projectInfoByProjectId[projectId] = DataTypes.ProjectData({
            hubId: project.hubId,
            soulBoundTokenId: project.soulBoundTokenId,
            name: project.name,
            description: project.description,
            image: project.image,
            metadataURI: project.metadataURI,
            descriptor: project.descriptor,
            defaultRoyaltyPoints: project.defaultRoyaltyPoints,
            feeShareType: project.feeShareType,
            permitByHubOwner: project.permitByHubOwner
        });

        return derivativeNFT;
    }
    
    function _deployDerivativeNFT(
        address creator,
        address derivativeImpl,
        address sbt,
        address treasury,        
        address marketPlace,        
        uint256 projectId,
        DataTypes.ProjectData memory project,
        address receiver_
    ) private returns (address) {
        address derivativeNFT = Clones.clone(derivativeImpl);
        IDerivativeNFT(derivativeNFT).initialize(
            sbt,
            treasury,  
            marketPlace,  
            project.name, 
            project.description,
            projectId,
            project.soulBoundTokenId,
            project.descriptor,
            receiver_,
            project.defaultRoyaltyPoints,
            project.feeShareType
        );

        emit Events.DerivativeNFTDeployed(
            creator,
            projectId, 
            project.soulBoundTokenId,
            derivativeNFT, 
            block.timestamp
        );
        
        return derivativeNFT;
    } 

}
