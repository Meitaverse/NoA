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
    // uint256 ownershipSoulBoundTokenId;     //owner soulBoundTokenId 
    uint256 projectId;                      
    uint256 publishId;                       
    uint256 tokenId;                       
    uint256 amount;                       
    address currency;                      
    uint256 salePrice;                     
    uint16[] royaltyPoints;
}

/**
 * @notice A struct containing the necessary data to initialize this Base Collect Module.
 *
 * @param projectId The project Id
 * @param publishId The publish Id
 * @param amount The total amount.
 * @param salePrice The collecting cost associated with this publication. 0 for free collect.
 * @param royaltyPoints Royalty array of collect points.
 */
//  * @param ownershipSoulBoundTokenId The ownershipSoulBoundToken Id
struct BaseFeeCollectModuleInitData {
    // uint256 ownershipSoulBoundTokenId; 
    uint256 projectId;                    
    uint256 publishId;      
    address currency;          
    uint256 amount;                       
    uint256 salePrice;                    
    uint16[] royaltyPoints;                
}

interface IBaseFeeCollectModule is ICollectModule {
    function getBasePublicationData(uint256 projectId)
        external
        view
        returns (BaseProfilePublicationData memory);

}
