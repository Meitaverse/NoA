//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INoAV1 {
  /**
     * @dev  Store orginazer create event 
     * @param organizer Event of orginazer
     * @param eventName Event name 
     * @param eventDescription Description of event
     * @param eventImage Image of event, ipfs or arweave url
     * @param mintMax Max count can mint
     */
  struct Event {
    address organizer;
    string eventName;
    string eventDescription;
    string eventImage;
    string eventMetadataURI;
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
   * @notice Combo a list of tokens with same slot to a new token.
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
  function combo(        
    uint256 eventId_ , 
    uint256[] memory fromTokenIds_, 
    string memory image_,
    string memory eventMetadataURI_,
    address to_,
    uint256 value_
  ) external payable returns (bool);

  /**
   * @notice get event infomation.
   * @param eventId_ The event id
   * @return Event.
   */
  function getEventInfo(uint256 eventId_) external view returns (Event memory);

  /**
   * @notice get slot detail.
   * @param slot_ The slot id
   * @return Event.
   */
  function getSlotDetail(uint256 slot_) external view returns (SlotDetail memory);

}
