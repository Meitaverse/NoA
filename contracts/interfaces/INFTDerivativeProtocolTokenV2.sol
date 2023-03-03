//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/DataTypes.sol";

interface INFTDerivativeProtocolTokenV2  { 

    /**
     * @dev Emitted when a profile is created.
     *
     * @param soulBoundTokenId The newly created profile's token ID.
     * @param creator The profile creator, who created the token with the given profile ID.
     * @param wallet The address receiving the profile with the given profile ID.
     * @param nickName The nickName set for the profile.
     * @param imageURI The image uri set for the profile.
     */
    event ProfileCreated(
        uint256 indexed soulBoundTokenId,
        address indexed creator,
        address indexed wallet,
        string nickName,
        string imageURI
    );

    /**
     * @dev Emitted when a profile is updated.
     *
     * @param soulBoundTokenId The updated profile's token ID.
     * @param nickName The nickName set for the profile.
     * @param imageURI The image uri set for the profile.
     */
    event ProfileUpdated(
        uint256 indexed soulBoundTokenId,
        string nickName,
        string imageURI
    );

    function version() external view returns(uint256);
    
    function createProfile(
       address voucher,
       DataTypes.CreateProfileData calldata vars
    ) external returns(uint256);


    // /**
    //  * @notice Mint value to a soulBoundTokenId.
    //  *  Only admin can execute.
    //  *
    //  * @param soulBoundTokenId is the soulBoundTokenId of ERC3525 Token
    //  * @param value is the value of tokenId
    //  */
    // function mintValue(
    //     uint256 soulBoundTokenId,
    //     uint256 value
    // ) external payable;

    // /**
    //  * @notice Burn a tokenId.
    //  *  Only admin can execute.
    //  *
    //  * @param tokenId is the tokenId of ERC3525 Token
    //  */
    // function burn(uint256 tokenId) external;

    function transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) external;

    //V2 
    function setSigner(address signer)  external;
    function getSigner()  external returns(address);

}
