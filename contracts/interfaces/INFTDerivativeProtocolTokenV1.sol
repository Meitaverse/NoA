//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/DataTypes.sol";

interface INFTDerivativeProtocolTokenV1  { 
  
    /**
     * @notice Initializes the NFT Derivative Protocol Token, setting the initial governance address as well as the name and symbol in
     * the ERC3525 base contract.
     *
     * @param name The name to set for the Token.
     * @param symbol The symbol to set for the Token.
     * @param decimals The decimal to set for the Token.
     * @param manager The address of Manager contract
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address manager
    ) external ;

     function version() external returns(uint256);
     function getManager() external returns(address);
     function getBankTreasury() external returns(address);

     function isContractWhitelisted(address contract_) external view returns (bool);

     function whitelistContract(address contract_, bool toWhitelist_) external;

    function setProfileImageURI(uint256 soulBoundTokenId, string calldata imageURI) external;
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

    // /**
    //  * @notice Mint to a address spec tokenId.
    //  *  Only admin can execute.
    //  *
    //  * @param mintTo to address 
    //  * @param slot is the lost of tokenId
    //  * @param value is the value of tokenId
    //  */
    // function mint(
    //     address mintTo,
    //     uint256 slot,
    //     uint256 value
    // ) external payable returns(uint256 tokenId);
  
    function createProfile(
        address creator,
       DataTypes.CreateProfileData calldata vars
    ) external returns(uint256);

    // function version() external view returns (uint256);

    function svgLogo() external view returns (string memory);

    /**
     * @notice Mint value to a soulBoundTokenId.
     *  Only admin can execute.
     *
     * @param soulBoundTokenId is the soulBoundTokenId of ERC3525 Token
     * @param value is the value of tokenId
     */
    function mintValue(
        uint256 soulBoundTokenId,
        uint256 value
    ) external payable;

    /**
     * @notice Burn a tokenId.
     *  Only admin can execute.
     *
     * @param tokenId is the tokenId of ERC3525 Token
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Burn value of a tokenId.
     *  Only admin can execute.
     *
     * @param tokenId is the tokenId of ERC3525 Token
     * @param value is the valueof the tokenId 
     */
    function burnValue(uint256 tokenId, uint256 value) external;


    function transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) external;


}
