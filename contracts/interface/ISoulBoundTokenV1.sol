//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";

interface ISoulBoundTokenV1 is IERC3525Metadata { 
    struct TokenInfoData {
        uint256 id;
        address owner;
        address mintedTo;
        string nickName;
        string role;
        string organization;
        string tokenName;
    }

     
    function version() external view returns (uint256);

    function svgLogo() external view returns (string memory);

     function nickNameOf(uint256 tokenId) external view returns (string memory);

     function roleOf(uint256 tokenId) external view returns (string memory);

    function organization() external view returns (string memory);

    function transferable() external view returns (bool);
    
    function mintable() external view returns (bool);

    function mintedTo(uint256 tokenId) external view returns (address);
}