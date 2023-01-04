// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title GlobalStorage
 * @author Bitsoul Protocol
 *
 * @notice This is an abstract contract that *only* contains storage for the ModuleGlobals contract. This
 * *must* be inherited last (bar interfaces) in order to preserve the ModuleGlobals storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract GlobalStorage {

    address internal _manager;
    address internal _ndpt; 
    address internal _governance;
    address internal _treasury;
    address internal _voucher;
    uint16 internal _treasuryFee; 

    mapping(address => uint256) internal _publishCurrencyTaxes; //publish的币种及数量

   
    mapping(address => bool) internal _profileCreatorWhitelisted;

    //soubBoundTokenId => true/false
    mapping(uint256 => bool) internal _hubCreatorWhitelisted;

    mapping(address => bool) internal _collectModuleWhitelisted;
    mapping(address => bool) internal _publishModuleWhitelisted;
    mapping(address => bool) internal _templateWhitelisted;
  
}
