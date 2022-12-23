//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {DataTypes} from '../libraries/DataTypes.sol';

interface IDerivativeNFTV1 { 
  
    /**
     * @notice Initializes the DerivativeNFT, setting the initial governance address as well as the name and symbol in
     * the NoABase contract.
     *
     * @param ndpt The NDPT contract.
     * @param bankTreasury The BankTreasury contract.
     * @param name_ The name to set for the derivative NFT.
     * @param symbol_ The symbol to set for the derivative NFT.
     * @param  hubId_ The id of the Hub.
     * @param  projectId_ The projectid.
     * @param  soulBoundTokenId_ The token id of the SoulBoundToken.
     * @param metadataDescriptor_ The Descriptor address to set.
     */
    function initialize( 
        address ndpt, 
        address bankTreasury,        
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
  function getProjectInfo(uint256 projectId_) external view returns (DataTypes.ProjectData memory);

  /**
   * @notice get slot detail.
   * @param slot_ The slot id
   * @return Event.
   */
  function getSlotDetail(uint256 slot_) external view returns (DataTypes.SlotDetail memory);

  function setMetadataDescriptor(address metadataDescriptor_) external;

  function setState(DataTypes.ProtocolState newState) external;

  /**
   * @notice Publish some value to organizer's incubator, only call by manager and owner of token is incubator
   *        
   * @param publication The publication infomation
   * @return uint256 The new tokenId.
   */
  function publish(
      DataTypes.Publication memory publication
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

     /**
     * @notice Implementation of an EIP-712 permit function for an ERC-721 NFT. We don't need to check
     * if the tokenId exists, since the function calls ownerOf(tokenId), which reverts if the tokenId does
     * not exist.
     *
     * @param spender The NFT spender.
     * @param tokenId The NFT token ID to approve.
     * @param sig The EIP712 signature struct.
     */
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external;
    
    /**
     * @notice Implementation of an EIP-712 permit function for an ERC-721 NFT. We don't need to check
     * if the tokenId exists, since the function calls ownerOf(tokenId), which reverts if the tokenId does
     * not exist.
     *
     * @param spender The NFT spender.
     * @param tokenId The NFT token ID to approve.
     * @param sig The EIP712 signature struct.
     */
    function permitValue(
        address spender,
        uint256 tokenId,
        uint256 value,
        DataTypes.EIP712Signature calldata sig
    ) external;
    /**
     * @notice Implementation of an EIP-712 permit-style function for ERC-721 operator approvals. Allows
     * an operator address to control all NFTs a given owner owns.
     *
     * @param owner The owner to set operator approvals for.
     * @param operator The operator to approve.
     * @param approved Whether to approve or revoke approval from the operator.
     * @param sig The EIP712 signature struct.
     */
    function permitForAll(
        address owner,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Burns an NFT, removing it from circulation and essentially destroying it. This function can only
     * be called by the NFT to burn's owner.
     *
     * @param tokenId The token ID of the token to burn.
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Implementation of an EIP-712 permit-style function for token burning. Allows anyone to burn
     * a token on behalf of the owner with a signature.
     *
     * @param tokenId The token ID of the token to burn.
     * @param sig The EIP712 signature struct.
     */
    function burnWithSig(uint256 tokenId, DataTypes.EIP712Signature calldata sig) external;

    /**
     * @notice Returns the domain separator for this NFT contract.
     *
     * @return bytes32 The domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

}
