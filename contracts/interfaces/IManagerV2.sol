// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';

/**
 * @title IManagerV2
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the Manager contract
 */
interface IManagerV2 {
    
  function getGovernance() external returns(address);


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

    function mintSBTValue(
        uint256 soulBoundTokenId, 
        uint256 value
    ) external;

   function burnSBT(
        uint256 soulBoundTokenId
   )external;

    function burnSBTValue(
        uint256 soulBoundTokenId,
        uint256 value
    ) external;


    /**
     * @notice Creates a profile with the specified parameters, minting a profile NFT to the given recipient. This
     * function must be called by a whitelisted profile creator.
     *
     * @param vars A CreateProfileData struct containing the following params:
     *      to: The address receiving the profile.
     *      nickName: The nickName to set for the profile, must be unique and non-empty.
     *      imageURI: The URI to set for the profile image.
     */
    function createProfile(
        DataTypes.CreateProfileData calldata vars
    ) external returns (uint256);

    function getReceiver() external view returns (address);

    function createHub(
        DataTypes.HubData memory hub
    ) external;

    function createProject(
        DataTypes.ProjectData memory project
    ) external returns (uint256);

    /**
     * @notice get project infomation.
     * @param projectId_ The project Id
     * @return Project struct data.
     */
    function getProjectInfo(uint256 projectId_) external view returns (DataTypes.ProjectData memory);

    /**
     * @notice Publish some amount of dNFTs
     *
     * @param publishId publishId
     * @param publication publication infomation
     * @return uint256 The new tokenId.
     */
    function publish(
        uint256 publishId,
        DataTypes.Publication memory publication
    ) external returns(uint256);
  

    function collect(
        uint256 projectId, 
        address collector,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata collectModuledata
    ) external;

    function airdrop(
        uint256 hubId,
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256[] memory toSoulBoundTokenIds,
        uint256 tokenId,
        uint256[] memory values
    ) external;

    /**
     * @notice Transfer a dNFT to a address from the fromSoulBoundTokenId to toSoulBoundTokenId
     *
     * @param projectId Event Id  
     * @param fromSoulBoundTokenId From SBT Id  
     * @param toSoulBoundTokenId  to
     * @param tokenId The tokenId of dNFT.
     * @param transferModuledata The arbitrary data  to pass.
     *
     */
    function transferDerivativeNFT(
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        bytes calldata transferModuledata
    ) external;

    function transferValueDerivativeNFT(
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata transferValueModuledata
    ) external;

     function publishFixedPrice(
        DataTypes.Sale memory sale
    ) external;

    function removeSale(
        uint24 saleId_
    ) external;

    function addMarket(
        address derivativeNFT_,
        uint64 precision_,
        uint8 feePayType_,
        uint8 feeType_,
        uint128 feeAmount_,
        uint16 feeRate_
    ) external;

    function removeMarket(
        address derivativeNFT_
    ) external;

    function buyUnits(
        uint256 soulBoundTokenId,
        address buyer,
        uint24 saleId, 
        uint128 units
    )  external payable returns (uint256 amount, uint128 fee);

}