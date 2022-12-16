// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title ICollectModule
 * @author Derivative NFT Protocol
 *
 * @notice This is the standard interface for all Bitsoul-compatible CollectModules.
 */
interface ICollectModule {
    /**
     * @notice Initializes data for a given publication being published. This can only be called by the manager.
     *
     * @param soulBoundTokenId The token ID of the SoulBoundToken publishing the publication.
     * @param tokenId The associated publication's Noa publication token ID.
     * @param value Value of the associated publication's Noa publication .
     * @param data Arbitrary data __passed from the user!__ to be decoded.
     *
     * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
     * manager alongside the collect module's address and should be consumed by front ends.
     */
    function initializePublicationCollectModule(
        uint256 soulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Processes a collect action for a given publication, this can only be called by the manager.
     *
     * @param referrerSoulBoundTokenId The NoA profile token ID of the referrer's profile.
     * @param collector The collector address.
     * @param soulBoundTokenId The token ID of the profile associated with the publication being collected.
     * @param tokenId The NoA publication token ID associated with the publication being collected.
     * @param value The value
     * @param data Arbitrary data __passed from the collector!__ to be decoded.
     */
    function processCollect(
        uint256 referrerSoulBoundTokenId,
        address collector,
        uint256 soulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external;
}
