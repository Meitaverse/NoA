// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IRoles.sol";

/**
 * @author bitsoul Protocol
 */
interface IHasRolesContract {
  function rolesManager() external returns (IRoles);
}
