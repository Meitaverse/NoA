//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../libraries/DataTypes.sol";

contract ProjectFounderStorage  {

    address internal  _manager;

    address internal  _sbt;
    
    address internal  _governance;

    address internal _banktreasury;

    mapping(uint256 => address) _projectTokens;

}
