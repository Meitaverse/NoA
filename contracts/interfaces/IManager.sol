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
   * @notice Sets the privileged governance role. This function can only be called by the current governance
   * address.
   *
   * @param newGovernance The new governance address to set.
   */
  function setGovernance(address newGovernance) external;


  /**
   * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state. This function
   * can only be called by the governance address.
   *
   * @param newEmergencyAdmin The new emergency admin address to set.
   */
  function setEmergencyAdmin(address newEmergencyAdmin) external;

  /**
   * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state. This function
   * can only be called by the governance address or the emergency admin address.
   *
   * Note that this reverts if the emergency admin calls it if:
   *      1. The emergency admin is attempting to unpause.
   *      2. The emergency admin is calling while the protocol is already paused.
   *
   * @param newState The state to set, as a member of the ProtocolState enum.
   */
  function setState(DataTypes.ProtocolState newState) external;

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

    function getReceiver() external view returns (address);

    /**
     * @notice Follows the given SBT Id, executing each SBT Id's follow module logic (if any).
     *
     * NOTE: Both the `soulBoundTokenIds` and `datas` arrays must be of the same length, regardless if the soulBoundTokenIds do not have a follow module set.
     *
     * @param soulBoundTokenIds The token ID array of the SoulBoundTokenId to follow.
     * @param datas The arbitrary data array to pass to the follow module for each profile if needed.
     *
     */
    function follow(uint256[] calldata soulBoundTokenIds, bytes[] calldata datas) external;

    function createEvent(
        uint256 soulBoundTokenId,
        DataTypes.Event memory event_,
        address metadataDescriptor_,
        bytes calldata collectModuleData
    ) external returns (uint256);

    function createEventBySig(
        uint256 soulBoundTokenId,
        DataTypes.Event memory event_,
        address metadataDescriptor_,
        bytes calldata collectModuleData,
        uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external  returns (uint256);
    
    /**
     * @notice Publish some amount of dNFTs
     *
     * @param slotDetail_ The slot D\detail event
     * @param soulBoundTokenId The SBT ID  of the organizer to publish.
     * @param amount The amount of dNFT that publish.
     * @param datas The arbitrary data array to collect
     *
     */
    function publish(
        DataTypes.SlotDetail memory slotDetail_,
        uint256 soulBoundTokenId, 
        uint256 amount, 
        bytes[] calldata datas) external returns(uint256);


    /**
     * @notice Combo into a new token.
     *
     * @param slotDetail_ detail of event
     * @param soulBoundTokenId From SBT Id  
     * @param fromTokenIds The array of dNFT.
     * @param datas The arbitrary data array to pass to the collect module for each profile if needed.
     *
     * @return new tokenId
     */
    function combo(
        DataTypes.SlotDetail memory slotDetail_,
        uint256 soulBoundTokenId, 
        uint256[] memory fromTokenIds,
        bytes[] calldata datas
    ) external returns(uint256);

    /**
     * @notice Split a dNFTs to two parts in same incubator.
     *
     * @param eventId Event Id  
     * @param soulBoundTokenId From SBT Id  
     * @param tokenId The tokenId of dNFT.
     * @param amount The amount to split.
     * @param datas The arbitrary data array to pass to the collect module for each profile if needed.
     *
     * @return new tokenId
     */
    function split(
        uint256 eventId, 
        uint256 soulBoundTokenId, 
        uint256 tokenId, 
        uint256 amount, 
        bytes[] calldata datas
    ) external returns(uint256) ;

}