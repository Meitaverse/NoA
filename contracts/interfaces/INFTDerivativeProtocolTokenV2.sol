//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/DataTypes.sol";

interface INFTDerivativeProtocolTokenV2  { 


    function version() external view returns(uint256);

    function whitelistContract(address contract_, bool toWhitelist_) external;

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

    function transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) external;


    //V2 
    function setSigner(address signer)  external;
    function getSigner()  external returns(address);

}
