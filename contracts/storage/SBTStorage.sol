//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interface/ISoulBoundTokenV1.sol";

contract SBTStorage  {
    struct TokenInfoData {
        uint256 id;
        address owner;
        // address mintedTo;
        string nickName;
        string role;
        // string organization;
        string tokenName;
    }

   /**
   * @notice Properties of the SBT, which determine the value of slot.
   */
    // struct TokenOwnerInfo {
    //     string nickName;
    //     string role;
    // }

    struct SlotDetail {
        string nickName;
        string role;
        bool locked;
        uint256 reputation;
    }
    
    // string internal _organization;
    address internal _signerAddress;
    string internal _svgLogo;

    // mapping(uint256 => TokenOwnerInfo) internal _tokenOwnerInfo;
    
    // mapping(uint256 => address) internal _mintedTo;

    // slot => slotDetail
    mapping(uint256 => SlotDetail) internal _slotDetails;


}
