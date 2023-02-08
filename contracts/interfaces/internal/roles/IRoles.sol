// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @notice Interface for a contract which implements admin roles.
 * @author bitsoul
 */
interface IRoles {
  function isAdmin(address account) external view returns (bool);

  function isOperator(address account) external view returns (bool);
}
