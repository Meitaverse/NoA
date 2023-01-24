// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @notice Interface for OperatorRole which wraps a role from
 * OpenZeppelin's AccessControl for easy integration.
 * @author batu-inal & HardlyDifficult
 */
interface IOperatorRole {
  function isOperator(address account) external view returns (bool);
}
