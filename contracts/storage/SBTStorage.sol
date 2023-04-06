//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../libraries/DataTypes.sol";

contract SBTStorage  {
    uint256 internal total_supply; 

    // soulBoundTokenId => slotDetail
    mapping(uint256 => DataTypes.SoulBoundTokenDetail) internal _sbtDetails;

    address internal  _manager;
    
    address internal  _governance;

    address internal _banktreasury;

}
