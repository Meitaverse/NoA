//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../libraries/DataTypes.sol";

contract BankTreasuryStorage  {

    //SBT id of BankTreasury
    uint256 _soulBoundTokenId;

    // solhint-disable-next-line var-name-mixedcase
    address internal _MANAGER;
    address internal  _governance;
    address internal  _NDPT;

    address[] internal owners;
    mapping(address => bool) internal isOwner;
    uint256 internal numConfirmationsRequired;


 
    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) internal isConfirmed;

    DataTypes.Transaction[] internal transactions;
}
