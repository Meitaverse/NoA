// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ICollectModule} from '../../interfaces/ICollectModule.sol';

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 *
 * @param salePrice The collecting cost associated with this publication. 0 for free collect.
 * @param currency The currency associated with this publication.
 * @param endTimestamp The end timestamp after which collecting is impossible. 0 for no expiry.
 * @param recipientSoulBoundTokenId Recipient of collect fees.
 */
struct BaseProfilePublicationData {
    uint256 tokenId;                       //发行对应的tokenId
    uint256 amount;                        //发行总量
    uint256 salePrice;                     //发行单价    
    address currency;
    uint256 recipientSoulBoundTokenId;
    uint72 endTimestamp;
}

/**
 * @notice A struct containing the necessary data to initialize this Base Collect Module.
 *
 * @param tokenId The tokenId for collect.
 * @param amount The total amount.
 * @param salePrice The collecting cost associated with this publication. 0 for free collect.
 * @param currency The currency associated with this publication.
 * @param endTimestamp The end timestamp after which collecting is impossible. 0 for no expiry.
 * @param recipientSoulBoundTokenId Recipient of collect fees.
 */
struct BaseFeeCollectModuleInitData {
    uint256 tokenId;                       //发行对应的tokenId
    uint256 amount;                        //发行总量
    uint256 salePrice;                     //发行单价    
    address currency;
    uint72 endTimestamp;
    uint256 recipientSoulBoundTokenId;
}

interface IBaseFeeCollectModule is ICollectModule {
    function getBasePublicationData(uint256 soulBoundTokenId, uint256 publishId)
        external
        view
        returns (BaseProfilePublicationData memory);

    function calculateFee(
        uint256 soulBoundTokenId,
        uint256 publishId,
        bytes calldata data
    ) external view returns (uint256);
}
