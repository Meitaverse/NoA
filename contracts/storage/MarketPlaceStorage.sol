// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';
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


    Counters.Counter internal _nextAuctionId;

    mapping(address => uint256) public sigNonces;

    address internal MODULE_GLOBALS;

    // derivativeNFT => Market
    mapping(address => DataTypes.Market) internal markets;

}