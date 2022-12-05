// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library Events {

  event EventAdded(
      address organizer, 
      uint256 eventId,
      string eventName,
      string eventDescription,
      string eventImage,
      uint256 mintMax
  );
    
  event EventToken(
      uint256 eventId, 
      uint256 tokenId, 
      address organizer, 
      address owner
  );
    
  event BurnToken(
      uint256 eventId, 
      uint256 tokenId, 
      address owner
  );

  /**
     * @dev MUST emits when an operator is approved or disapproved to manage all of `_owner`'s
     *  tokens with the same slot.
     * @param _owner The address whose tokens are approved
     * @param _slot The slot to approve, all of `_owner`'s tokens with this slot are approved
     * @param _operator The operator being approved or disapproved
     * @param _approved Identify if `_operator` is approved or disapproved
     */
    event ApprovalForSlot(address indexed _owner, uint256 indexed _slot, address indexed _operator, bool _approved);

}

