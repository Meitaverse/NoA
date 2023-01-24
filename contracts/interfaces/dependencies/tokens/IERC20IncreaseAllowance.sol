// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IERC20IncreaseAllowance {
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}
