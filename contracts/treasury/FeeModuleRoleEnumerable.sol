// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


import "../market/OZAccessControlUpgradeable.sol";

/**
 * @title Defines a role for FeeModule accounts.
 * @dev Wraps a role from OpenZeppelin's AccessControl for easy integration.
 * @author batu-inal & HardlyDifficult
 */
abstract contract FeeModuleRoleEnumerable is Initializable, OZAccessControlUpgradeable {
  bytes32 private constant FEEMODULE_ROLE = keccak256("FEEMODULE_ROLE");

  modifier onlyFeeModule() {
    require(hasRole(FEEMODULE_ROLE, msg.sender), "FeeModule: caller does not have the FeeModule role");
    _;
  }

  /**
   * @notice Adds the account to the list of approved operators.
   * @dev Only callable by admins as enforced by `grantRole`.
   * @param account The address to be approved.
   */
  function grantFeeModule(address account) external {
    grantRole(FEEMODULE_ROLE, account);
  }

  /**
   * @notice Removes the account from the list of approved operators.
   * @dev Only callable by admins as enforced by `revokeRole`.
   * @param account The address to be removed from the approved list.
   */
  function revokeFeeModule(address account) external {
    revokeRole(FEEMODULE_ROLE, account);
  }

  /**
   * @notice Returns one of the operator by index.
   * @param index The index of the operator to return from 0 to getFeeModuleMemberCount() - 1.
   * @return account The address of the operator.
   */
  function getFeeModuleMember(uint256 index) external view returns (address account) {
    account = getRoleMember(FEEMODULE_ROLE, index);
  }

  /**
   * @notice Checks how many accounts have been granted operator access.
   * @return count The number of accounts with operator access.
   */
  function getFeeModuleMemberCount() external view returns (uint256 count) {
    count = getRoleMemberCount(FEEMODULE_ROLE);
  }

  /**
   * @notice Checks if the account provided is an operator.
   * @param account The address to check.
   * @return approved True if the account is an operator.
   */
  function isFeeModule(address account) public view returns (bool approved) {
    approved = hasRole(FEEMODULE_ROLE, account);
  }
}
