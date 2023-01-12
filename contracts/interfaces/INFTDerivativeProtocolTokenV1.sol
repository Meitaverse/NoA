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

    /**
     * @notice Return the version of current contract
     *
     * @return version number
     */
    function version() external view returns(uint256);

    /**
     * @notice Set whitelist with a contract 
     *  Only admin can execute.
     *
     * @param contract_ is the contract
     * @param toWhitelist_ true of false
     */
    function whitelistContract(address contract_, bool toWhitelist_) external;

    /**
     * @notice Create a profile
     *
     * @param creator The creator
     * @param vars CreateProfileData struct
     */
    function createProfile(
        address creator,
       DataTypes.CreateProfileData calldata vars
    ) external returns(uint256);

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
     * @notice Transfer value from a tokenId to tokenId.
     *  Only whitelist contract can execute.
     *
     * @param fromTokenId_ is the from tokenId of ERC3525 Token
     * @param toTokenId_ is the to tokenId of ERC3525 Token
     * @param value_ value to be transfer
     */
    function transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) external;


}
