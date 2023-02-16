//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {DataTypes} from '../libraries/DataTypes.sol';

interface IDerivativeNFT { 
  
    /**
     * @notice Initializes the DerivativeNFT, setting the initial governance address as well as the name and symbol in
     * the NoABase contract.
     *
     * @param sbt The SBT contract.
     * @param bankTreasury The BankTreasury contract.
     * @param name_ The name to set for the derivative NFT.
     * @param symbol_ The symbol to set for the derivative NFT.
     * @param  projectId_ The projectid.
     * @param  soulBoundTokenId_ The token id of the SoulBoundToken.
     * @param metadataDescriptor_ The Descriptor address to set.
     * @param receiver_ The receiver address to set.
     * @param defaultRoyaltyBPS_ The default royalty BPS
     */
    function initialize( 
        address sbt, 
        address bankTreasury,        
        address marketPlace,        
        string memory name_,
        string memory symbol_,
        uint256 projectId_,
        uint256 soulBoundTokenId_,
        address metadataDescriptor_,
        address receiver_,
         uint256 defaultRoyaltyBPS_
    ) external;


    /**
     * @notice get slot detail.
     * 
     * @param slot_ The slot id
     * @return Event.
     */
   function getSlotDetail(uint256 slot_) external view returns (DataTypes.SlotDetail memory);

    /**
     * @notice get slot by publish id.
     * 
     * @param publishId The publish Id
     * @return slot 
     */
   function getSlot(uint256 publishId) external view returns (uint256) ;
  
    /**
     * @notice set token image URI.
     * 
     * @param tokenId The token Id
     * @param imageURI The image URI
     */
   function setTokenImageURI(uint256 tokenId, string calldata imageURI) external;

    /**
     * @notice set the meta data descriptor of derivativeNFT contract
     * 
     * @param metadataDescriptor_ The descriptor contract address
     */
    function setMetadataDescriptor(address metadataDescriptor_) external;
 
    /**
     * @notice Sets the DerivativeNFT state to either a global pause or an unpaused state. This function
     * can only be called by the manager address.
     *
     * @param newState The state to set, as a member of the DerivativeNFTState enum.
     */
    function setState(DataTypes.DerivativeNFTState newState) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    
    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

    /**
     * @notice get the publishId by tokenId 
     */
    function getPublishIdByTokenId(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Publish some dNFT to a publisher wallet
     *        
     * @param publishId The publishId
     * @param publication The publication
     * @param publisher The publisher 
     * @param bps The total royalties bps 
     * 
     * @return uint256 The new tokenId.
     */
    function publish(
        uint256 publishId,
        DataTypes.Publication memory publication,
        address publisher,
        uint16 bps
    ) external returns(uint256);

    /**
     * @notice Split some value to a to_, only call by manager, not need approve before
     *
     * @param publishId_ The tokenId to be publish
     * @param fromTokenId_ The tokenId to be split
     * @param to_ amount to split
     * @return uint256 The new tokenId.
     */
    function split(
        uint256 publishId_, 
        uint256 fromTokenId_, 
        address to_,
        uint256 value_
    ) external returns(uint256);
    
    /**
     * @notice Transfer value from a tokenId to a another tokenId,  only call by market place, not need approve before
     *
     * @param fromTokenId_ The tokenId to be transfer
     * @param toTokenId_  The tokenId to be receive
     * @param value_  The value
     */
    function transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) external;

    /**
     * @notice Burns an NFT, removing it from circulation and essentially destroying it. This function can only
     * be called by the NFT to burn's owner.
     *
     * @param tokenId The token ID of the token to burn.
     */
    function burn(uint256 tokenId) external;

    function getCreator() external view returns(address);

}
