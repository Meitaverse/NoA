//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";

interface INoAV1 is IERC3525, IERC3525Metadata { 

  struct Event {
    address organizer;
    string eventName;
    string eventDescription;
    string eventImage;
    uint256 mintMax;
  }
  
   /**
   * @notice Properties of the slot, which determine the value of slot.
   */
  struct SlotDetail {
    string name;
    string description;
    string image;
    uint256 eventId;
    string eventMetadataURI;
  }

  /**
   * @notice Mint to a address with event info.
   * @dev Emits the EventToken event. 
   *  Only admin can execute.
   *
   * @param  slotDetail_ The slot detail.
   * @param to_ is the address that can receive a new token.
   * @param proof_ is the array of whitelist merkle proof
   * @return bool whether the call correctly returned true.
   */
  function mint(
    SlotDetail memory slotDetail_,
    address to_,
    bytes32[] calldata proof_
  ) external payable returns (bool);


  /**
   * @notice Mint to many addresses with same event.
   * @dev Emits the EventToken event. 
   *  Only admin can execute.
   *
   * @param slotDetail_ The slot detail.
   * @param to_ is the list of addresses that can receive a new token.
   * @return bool whether the call correctly returned true.
   */
  function mintEventToManyUsers(
       SlotDetail memory slotDetail_,
       address[] memory to_
  ) external payable returns (bool);

  /**
   * @notice Merges tokens with same slot to a new token.
   *  After new token minted, source tokens are burned.
   * @dev Emits the EventToken event. 
   *  Only authorised owner or operator can execute.
   *
   * @param eventId_ The event id
   * @param fromTokenIds_ The tokens to be merged from.
   * @param image_ new image 
   * @param eventMetadataURI_ new event metadata
   * @param to_ new token who received
   * @return bool whether the call correctly returned true.
   */
  function merge(        
    uint256 eventId_ , 
    uint256[] memory fromTokenIds_, 
    string memory image_,
    string memory eventMetadataURI_,
    address to_
  ) external payable returns (bool);

  /**
   * @notice Organizer publish new tokens.
   *  After new tokens minted, source tokens are burned 
   * and send a new one to owner of source.
   * @dev Emits the Publish event. 
   *  Only authorised owner or operator can execute.
   *
   * @param eventId_ The event id
   * @param fromTokenIds_ The tokens to be merged from.
   * @param image_ new image 
   * @param eventMetadataURI_ new event metadata
   * @param value_ how many tokens mint
   * @return bool whether the call correctly returned true.
   */
  function publish(
    uint256 eventId_ , 
    uint256[] memory fromTokenIds_, 
    string memory image_,
    string memory eventMetadataURI_,
    uint256 value_
  ) external payable returns (bool);

  function getEventInfo(uint256 eventId) external view returns (Event memory);
  function getSlotDetail(uint256 slot_) external view returns (SlotDetail memory);

}
