//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';

contract BankTreasuryStorage  {

    // Lockup configuration
    /// @notice The minimum lockup period in seconds.
   uint256 internal  lockupDuration;
   
    /// @notice The interval to which lockup expiries are rounded, limiting the max number of outstanding lockup buckets.
   uint256 internal  lockupInterval;
 
    
    mapping(address => uint256) public sigNonces;

    address internal  _governance;

    address internal  _projectFounder;

    /// @notice The Foundation market contract with permissions to manage lockups.
    address payable internal _foundationMarket;

    address internal  MODULE_GLOBALS;

    address[] internal _signers;
    
    mapping(address => bool) internal _isSigner;

    uint256 internal _numConfirmationsRequired;
 
    // mapping from tx index => signer => bool
    mapping(uint256 => mapping(address => bool)) internal _isConfirmed;

    DataTypes.Transaction[] internal _transactions;

    mapping(address => DataTypes.ExchangePrice) internal _exchangePrice;

    /// @notice Stores per-account details.
    mapping(uint256 => mapping(address => DataTypes.AccountInfo)) internal accountToInfo;

    //projectId => founder SBT Id => ProjectFounderRevenueData
    mapping(uint256 => mapping(uint256 => DataTypes.PercentFounderData)) internal _founders;
    
     //projectId =>  project revenue amount
    mapping(uint256 => DataTypes.FounderRevenueData) internal _projectRevenues;

}
