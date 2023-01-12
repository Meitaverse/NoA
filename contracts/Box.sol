// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";


//这是提案通过投票后执行代码的合约。
contract Box is Ownable {
  uint256 private _value;

  // Emitted when the stored value changes
  event ValueChanged(uint256 newValue);

  // Stores a new value in the contract
  // owner可以为合约地址，由合约来调用
  function store(uint256 newValue) public onlyOwner {
    console.log('store: ', msg.sender);
    _value = newValue;
    emit ValueChanged(newValue);
  }

  // Reads the last stored value
  function retrieve() public view returns (uint256) {
    return _value;
  }
}