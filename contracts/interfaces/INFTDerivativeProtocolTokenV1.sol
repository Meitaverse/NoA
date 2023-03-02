//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/DataTypes.sol";

interface INFTDerivativeProtocolTokenV1  { 

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

    /**
     * @notice Create a profile
     *
     * @param voucher The voucher
     * @param vars CreateProfileData struct
     */
    function createProfile(
        address voucher,
        DataTypes.CreateProfileData calldata vars
    ) external returns(uint256);

    /**
     * @notice get a profile detail
     *
     * @param soulBoundTokenId The creator
     * @return soulBoundTokenDetail detail of SoulBoundTokenDetail
     */
    function getProfileDetail(uint256 soulBoundTokenId) external view returns (DataTypes.SoulBoundTokenDetail memory);

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
