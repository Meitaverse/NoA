// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title MarketPlaceStorage
 * @author Bitsoul Protocol
 *
 * @notice This is an abstract contract that *only* contains storage for the MarketPlace contract. This
 * *must* be inherited last (bar interfaces) in order to preserve the Manager storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract MarketPlaceStorage {

    Counters.Counter internal _nextSaleId;
    Counters.Counter internal _nextTradeId;

    mapping(address => uint256) public sigNonces;

    // solhint-disable-next-line var-name-mixedcase
    // address internal  _governance;
    address internal  MODULE_GLOBALS;

    //derivativeNFT => saleId
    mapping(address => EnumerableSetUpgradeable.UintSet) internal _derivativeNFTSales;
    // mapping(address => EnumerableSetUpgradeable.AddressSet) internal _allowAddresses;

    // --- market place --- //

    // derivativeNFT => Market
    mapping(address => DataTypes.Market) internal markets;

    //saleId => struct Sale
    mapping(uint24 => DataTypes.Sale) internal sales;
    
    // records of user purchased units from an order
    mapping(uint24 => mapping(address => uint128)) internal saleRecords;



}