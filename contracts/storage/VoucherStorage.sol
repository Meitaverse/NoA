//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../libraries/DataTypes.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VoucherStorage  {

    Counters.Counter internal _nextVoucherId;

    mapping(uint256 => string) internal _uris;

    //tokenId => VoucherData
    mapping(uint256 => DataTypes.VoucherData) internal _vouchers;


}
