// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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
     * @param ownershipSoulBoundTokenId The owner of token ID of the SoulBoundToken publishing the publication.
     * @param tokenId The associated publication's dNFT publication token ID.
     * @param amount amount of the associated publication's dNFT publication .
     * @param data Arbitrary data __passed from the user!__ to be decoded.
     *
     * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
     * manager alongside the collect module's address and should be consumed by front ends.
     */
    function initializePublicationCollectModule(
        uint256 publishId,
        uint256 ownershipSoulBoundTokenId,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Processes a collect action for a given publication, this can only be called by the manager.
     *
     * @param ownershipSoulBoundTokenId The owner of  the profile associated with the publication being collected.
     * @param collectorSoulBoundTokenId The collector token ID of the profile associated with the publication being collected.
     * @param publishId The publish Id.
     * @param collectValue The value
     * @param data Arbitrary data __passed from the collector!__ to be decoded.
     */
    function processCollect(
        uint256 ownershipSoulBoundTokenId,
        uint256 collectorSoulBoundTokenId,
        uint256 publishId,
        uint256 collectValue,
         bytes calldata data
    ) external;
}

