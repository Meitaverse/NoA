//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../libraries/DataTypes.sol";

contract SBTStorage  {
    string internal _svgLogo;

    // slot => slotDetail
    mapping(uint256 => DataTypes.SoulBoundTokenDetail) internal _sbtDetails;
}
