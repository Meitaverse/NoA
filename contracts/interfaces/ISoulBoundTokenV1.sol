//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface ISoulBoundTokenV1 is IERC3525Metadata { 
    
    function mint(
       DataTypes.CreateProfileData calldata vars,
       string memory nickName
    ) external returns(uint256) ;

    // function version() external view returns (uint256);

    function svgLogo() external view returns (string memory);

    //  function nickNameOf(uint256 tokenId) external view returns (string memory);

    //  function roleOf(uint256 tokenId) external view returns (string memory);

    // function organization() external view returns (string memory);

    // function mintedTo(uint256 tokenId) external view returns (address);
}