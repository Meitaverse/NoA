//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../libraries/DataTypes.sol";

contract SBTStorage  {
    string internal _svgLogo;

    // slot => slotDetail
    mapping(uint256 => DataTypes.SoulBoundTokenDetail) internal _sbtDetails;

    // solhint-disable-next-line var-name-mixedcase
    address internal _MANAGER;

    // solhint-disable-next-line var-name-mixedcase
    address internal _BANKTREASURY;

    // address internal _FeeCollectModule;
    // address internal _PublishModule;

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) internal _slotApprovals;
    
    mapping(address => bool) internal _contractWhitelisted;
}
