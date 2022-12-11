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
     * @param  soulBoundTokenId_ The token id of the SoulBoundToken.
     * @param metadataDescriptor_ The Descriptor address to set.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
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
   * @notice Mint to a address with event info.
   * @dev Emits the EventToken event. 
   *  Only admin can execute.
   *
   * @param slotDetail_ The slot detail.
   * @param to_ is the address that can receive a new token.
   * @param value_ is the value of token.
   * @return bool whether the call correctly returned true.
   */
  // function mint(
  //   DataTypes.SlotDetail memory slotDetail_,
  //   address to_,
  //   uint256 value_
  // ) external payable returns (bool);

  /**
   * @notice Combo a list of tokens with same slot to a new token.
   *  After new token minted, source tokens are burned.
   * @dev Emits the EventToken event. 
   *  Only authorised owner or operator can execute.
   *
   * @param slotDetail_ slot detail.
   * @param fromTokenIds_ The tokens to be merged from.
   * @param to_ new token who received
   * 
   * @return bool whether the call correctly returned true.
   */
  function combo(        
    DataTypes.SlotDetail memory slotDetail_,
    uint256[] memory fromTokenIds_, 
    address to_
  ) external payable returns (uint256);

  /**
   * @notice get event infomation.
   * @param eventId_ The event id
   * @return Event.
   */
  function getEventInfo(uint256 eventId_) external view returns (DataTypes.Event memory);

  /**
   * @notice get slot detail.
   * @param slot_ The slot id
   * @return Event.
   */
  function getSlotDetail(uint256 slot_) external view returns (DataTypes.SlotDetail memory);

  function setMetadataDescriptor(address metadataDescriptor_) external;

  function createEvent(DataTypes.Event memory event_) external returns (uint256);

  /**
   * @notice Publish some value to organizer's incubator, only call by manager and owner of token is incubator
   *        
   * @param slotDetail_ The LlotDetail of token
   * @param to_ Owner of new token, incubator 
   * @param value_ amount to split
   * @return uint256 The new tokenId.
   */
  function publish(
    DataTypes.SlotDetail memory slotDetail_,
    address to_, 
    uint256 value_
  ) external returns(uint256);

   /**
     * @notice Split some value to a incubator, only call by manager
     *
     * @param fromTokenId_ The tokenId to be split
     * @param to_ Address to be received, incubator or wallet address
     * @param value_ amount to split
     * @return uint256 The new tokenId.
     */
    function split(
        uint256 fromTokenId_, 
        address to_, 
        uint256 value_
    ) external returns(uint256);
}
