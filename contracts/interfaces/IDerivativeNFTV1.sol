//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {DataTypes} from '../libraries/DataTypes.sol';

interface IDerivativeNFTV1 { 
  
    /**
     * @notice Initializes the DerivativeNFT, setting the initial governance address as well as the name and symbol in
     * the NoABase contract.
     *
     * @param name_ The name to set for the derivative NFT.
     * @param symbol_ The symbol to set for the derivative NFT.
     * @param  hubId_ The id of the Hub.
     * @param  projectId_ The projectid.
     * @param  soulBoundTokenId_ The token id of the SoulBoundToken.
     * @param metadataDescriptor_ The Descriptor address to set.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 hubId_,
        uint256 projectId_,
        uint256 soulBoundTokenId_,
        address metadataDescriptor_
    ) external;


    /**
     * @notice Approve or disapprove an operator to manage all of `_owner`'s tokens with the
     *  specified slot.
     * @dev Caller SHOULD be `_owner` or an operator who has been authorized through
     *  `setApprovalForAll`.
     *  MUST emit ApprovalSlot event.
     * @param _owner The address that owns the ERC3525 tokens
     * @param _slot The slot of tokens being queried approval of
     * @param _operator The address for whom to query approval
     * @param _approved Identify if `_operator` would be approved or disapproved
     */
    function setApprovalForSlot(
        address _owner,
        uint256 _slot,
        address _operator,
        bool _approved
    ) external payable;

    /**
     * @notice Query if `_operator` is authorized to manage all of `_owner`'s tokens with the
     *  specified slot.
     * @param _owner The address that owns the ERC3525 tokens
     * @param _slot The slot of tokens being queried approval of
     * @param _operator The address for whom to query approval
     * @return True if `_operator` is authorized to manage all of `_owner`'s tokens with `_slot`,
     *  false otherwise.
     */
    function isApprovedForSlot(
        address _owner,
        uint256 _slot,
        address _operator
    ) external view returns (bool);


  /**
   * @notice get project infomation.
   * @param projectId_ The project Id
   * @return Project struct data.
   */
  function getProjectInfo(uint256 projectId_) external view returns (DataTypes.Project memory);

  /**
   * @notice get slot detail.
   * @param slot_ The slot id
   * @return Event.
   */
  function getSlotDetail(uint256 slot_) external view returns (DataTypes.SlotDetail memory);

  function setMetadataDescriptor(address metadataDescriptor_) external;

  function setState(DataTypes.ProtocolState newState) external;

  // function createProject(DataTypes.Project memory project_) external returns (uint256);

  /**
   * @notice Publish some value to organizer's incubator, only call by manager and owner of token is incubator
   *        
   * @param soulBoundTokenId NDPT id
   * @param publication The publication infomation
   * @param value_ amount to split
   * @return uint256 The new tokenId.
   */
  function publish(
      uint256 soulBoundTokenId,
      DataTypes.Publication memory publication,
      uint256 value_
  ) external returns(uint256);

   /**
     * @notice Split some value to a incubator, only call by manager
     *
     * @param toSoulBoundTokenId_ soulBoundTokenId send to
     * @param fromTokenId_ The tokenId to be split
     * @param value_ amount to split
     * @return uint256 The new tokenId.
     */
    function split(
        uint256 toSoulBoundTokenId_,
        uint256 fromTokenId_, 
        uint256 value_
    ) external returns(uint256);
}
