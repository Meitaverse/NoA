// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title ICollectModule
 * @author Bitsoul Protocol
 *
 * @notice This is the standard interface for all Bitsoul-compatible CollectModules.
 */
interface ICollectModule {
    /**
     * @notice Initializes data for a given publication being published. This can only be called by the manager.
     *
     * @param publishId The owner of token ID of the SoulBoundToken publishing the publication.
     * @param tokenId The associated publication's dNFT publication token ID.
     * @param amount amount of the associated publication's dNFT publication .
     * @param data Arbitrary data __passed from the user!__ to be decoded.
     *
     */
    //  * @param ownershipSoulBoundTokenId The owner of token ID of the SoulBoundToken publishing the publication.
    function initializePublicationCollectModule(
        uint256 publishId,
        // uint256 ownershipSoulBoundTokenId,
        uint256 tokenId,
        address currency,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice Processes a collect action for a given publication, this can only be called by the manager.
     *
     * @param ownershipSoulBoundTokenId The owner of  the profile associated with the publication being collected.
     * @param collectorSoulBoundTokenId The collector token ID of the profile associated with the publication being collected.
     * @param publishId The publish Id.
     * @param payValue The total amount of SBT value will pay for
     * @param data Arbitrary data __passed from the collector!__ to be decoded.
     */
    function processCollect(
        uint256 ownershipSoulBoundTokenId,
        uint256 collectorSoulBoundTokenId,
        uint256 publishId,
        uint96 payValue,
        bytes calldata data
    ) external returns (DataTypes.RoyaltyAmounts memory);
}

