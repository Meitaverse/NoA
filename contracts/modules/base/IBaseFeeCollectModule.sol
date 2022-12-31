// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ICollectModule} from '../../interfaces/ICollectModule.sol';

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 *
 * @param salePrice The collecting cost associated with this publication. 0 for free collect.
 * @param royaltyPoints Royalty point of collect fees.
 */
struct BaseProfilePublicationData {
    uint256 ownershipSoulBoundTokenId;     //owner soulBoundTokenId 
    uint256 projectId;                     //项目id
    uint256 publishId;                     //发行id    
    uint256 tokenId;                       //发行对应的tokenId
    uint256 amount;                        //发行总量
    uint256 salePrice;                     //发行单价    
    uint16[] royaltyPoints;
}

/**
 * @notice A struct containing the necessary data to initialize this Base Collect Module.
 *
 * @param ownershipSoulBoundTokenId The ownershipSoulBoundToken Id
 * @param projectId The project Id
 * @param publishId The publish Id
 * @param amount The total amount.
 * @param salePrice The collecting cost associated with this publication. 0 for free collect.
 * @param royaltyPoints Royalty array of collect points.
 */
struct BaseFeeCollectModuleInitData {
    uint256 ownershipSoulBoundTokenId;     //owner soulBoundTokenId 
    uint256 projectId;                     //项目id
    uint256 publishId;                     //发行id
    uint256 amount;                        //发行总量
    uint256 salePrice;                     //发行单价    
    uint16[] royaltyPoints;                 //税点数组, [0] - genesis, [1-4] collector的前4个用户的版税点
}

interface IBaseFeeCollectModule is ICollectModule {
    function getBasePublicationData(uint256 projectId)
        external
        view
        returns (BaseProfilePublicationData memory);

}
