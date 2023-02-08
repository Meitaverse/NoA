// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @notice Interface for AdminRole which wraps the default admin role from
 * OpenZeppelin's AccessControl for easy integration.
 * @author bitsoul
 */
interface IAdminRole {
  function isAdmin(address account) external view returns (bool);
}
