// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';

/**
 * @title IManager
 * @author Derivative NFT Protocol
 *
 * @notice This is the interface for the Manager contract
 */
interface IManager {
  
    /**
     * @notice Creates a profile with the specified parameters, minting a profile NFT to the given recipient. This
     * function must be called by a whitelisted profile creator.
     *
     * @param vars A CreateProfileData struct containing the following params:
     *      to: The address receiving the profile.
     *      handle: The handle to set for the profile, must be unique and non-empty.
     *      imageURI: The URI to set for the profile image.
     *      followModule: The follow module to use, can be the zero address.
     *      followModuleInitData: The follow module initialization data, if any.
     */
    function createSoulBoundToken(DataTypes.CreateProfileData calldata vars, string memory nickName) external returns (uint256);

    /**
     * @notice Returns the follow module associated with a given soulBoundTokenId, if any.
     *
     * @param soulBoundTokenId The token ID of the SoulBoundToken to query the follow module for.
     *
     * @return address The address of the follow module associated with the given profile.
     */
    function getFollowModule(uint256 soulBoundTokenId) external view returns (address);

    /**
     * @notice Returns the address of the SoulBundToken contract
     *
     * @return address The address of the SoulBundToken contract.
     */
    function getSoulBoundToken() external view returns (address);

    /**
     * @notice Returns the address of the Incubator contract
     *
     * @param soulBoundTokenId The token ID of the SoulBoundToken to query the incubator for.
     * 
     * @return address The address of the SoulBundToken contract.
     */
    function getIncubatorOfSoulBoundTokenId(uint256 soulBoundTokenId) external view returns (address);
    
    /**
     * @notice Returns the address of the Incubator contract implementation
     *
     * 
     * @return address The address of the implementation.
     */
    
    /**
     * @notice Returns the address of the Incubator NFT contract implementation
     *
     * 
     * @return address The address of the implementation.
     */
    function getIncubatorImpl() external view returns (address);
    
    /**
     * @notice Returns the address of the Derivative NFT contract implementation
     *
     * 
     * @return address The address of the implementation.
     */
    function getDNFTImpl() external view returns (address);

    /**
     * @notice Follows the given profiles, executing each profile's follow module logic (if any) and minting followNFTs to the caller.
     *
     * NOTE: Both the `profileIds` and `datas` arrays must be of the same length, regardless if the profiles do not have a follow module set.
     *
     * @param soulBoundTokenIds The token ID array of the SoulBoundTokenId to follow.
     * @param datas The arbitrary data array to pass to the follow module for each profile if needed.
     *
     */
    function follow(uint256[] calldata soulBoundTokenIds, bytes[] calldata datas)
        external;
}