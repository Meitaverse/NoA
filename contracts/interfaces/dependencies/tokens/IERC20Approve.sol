// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IERC20Approve {
  function approve(address spender, uint256 amount) external returns (bool);
}
