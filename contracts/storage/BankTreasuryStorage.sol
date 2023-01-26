//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';

contract BankTreasuryStorage  {

    // Lockup configuration
    /// @notice The minimum lockup period in seconds.
   uint256 internal  lockupDuration;
    /// @notice The interval to which lockup expiries are rounded, limiting the max number of outstanding lockup buckets.
   uint256 internal  lockupInterval;
 

    //SBT id of BankTreasury
    uint256 public soulBoundTokenIdBankTreasury;
    
    mapping(address => uint256) public sigNonces;

    address internal  _governance;

    /// @notice The Foundation market contract with permissions to manage lockups.
    address payable internal _foundationMarket;


    address internal  MODULE_GLOBALS;

    address[] internal _signers;
    
    mapping(address => bool) internal _isSigner;

    uint256 internal _numConfirmationsRequired;
 
    // mapping from tx index => signer => bool
    mapping(uint256 => mapping(address => bool)) internal _isConfirmed;

    DataTypes.Transaction[] internal _transactions;

    uint256 internal _exchangePrice;

    mapping(DataTypes.VoucherParValueType => uint256) internal _voucherParValues;

}
