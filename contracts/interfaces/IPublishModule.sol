// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';
/**
 * @title IPublishModule
 * @author Bitsoul Protocol
 *
 * @notice This is the standard interface for all Bitsoul-compatible CommunityModules.
 */
interface IPublishModule {
    /**
     * @notice Initializes data for a given publication being published. This can only be called by the manager.
     *
     * @param publishId The token ID.
     * @param publication The publication
     *
     */
    function initializePublishModule(
        uint256 publishId,
        DataTypes.Publication calldata publication
    ) external;

    /**
     * @notice Processes a publish action for a given publication, this can only be called by the manager.
     *
     * @param publishId The order ID.
     */
    function processPublish(
        uint256 publishId
    ) external;
}


