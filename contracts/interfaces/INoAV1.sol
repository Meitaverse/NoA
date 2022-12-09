//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
import {DataTypes} from '../libraries/DataTypes.sol';

interface INoAV1 is IERC3525Metadata { 
  
    /**
     * @notice Initializes the DerivativeNFT, setting the initial governance address as well as the name and symbol in
     * the NoABase contract.
     *
     * @param name_ The name to set for the derivative NFT.
     * @param symbol_ The symbol to set for the derivative NFT.
     * @param metadataDescriptor_ The Descriptor address to set.
     * @param receiver_ The DerivativeNFT receiver address to set.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address metadataDescriptor_,
        address receiver_
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
   * @param  slotDetail_ The slot detail.
   * @param to_ is the address that can receive a new token.
   * @return bool whether the call correctly returned true.
   */
  function mint(
    DataTypes.SlotDetail memory slotDetail_,
    address to_
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
  function getEventInfo(uint256 eventId_) external view returns (DataTypes.Event memory);

  /**
   * @notice get slot detail.
   * @param slot_ The slot id
   * @return Event.
   */
  function getSlotDetail(uint256 slot_) external view returns (DataTypes.SlotDetail memory);



    /**
     * @notice Sets the privileged governance role. This function can only be called by the current governance
     * address.
     *
     * @param newGovernance The new governance address to set.
     */
    // function setGovernance(address newGovernance) external;

    /**
     * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state. This function
     * can only be called by the governance address.
     *
     * @param newEmergencyAdmin The new emergency admin address to set.
     */
    // function setEmergencyAdmin(address newEmergencyAdmin) external;

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
    // function setState(DataTypes.ProtocolState newState) external;

}
