//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";

interface INoAV1 is IERC3525Metadata {

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

  function mint(
    SlotDetail memory slotDetail_,
    address to_
  ) external;

  function mintEventToManyUsers(
       SlotDetail memory slotDetail_,
       address[] memory to_
  ) external returns (bool);

  function mintUserToManyEvents(
        SlotDetail[] memory slotDetails_,
        address to_
  ) external returns (bool);

  function getEventInfo(uint256 eventId) external view returns (Event memory);
  function getSlotDetail(uint256 slot_) external view returns (SlotDetail memory);

}
