// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @notice Interface for functions the voucher market uses in FETH.
 * @author Bitsoul Protocol
 */
interface IFethMarket {
  function depositFor(address account) external payable;

  function marketLockupFor(address account, uint256 amount) external payable returns (uint256 expiration);

  function marketWithdrawFrom(address from, uint256 amount) external;

  function marketWithdrawLocked(
    address account,
    uint256 expiration,
    uint256 amount
  ) external;

  function marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) external;

  function marketChangeLockup(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address lockupFor,
    uint256 lockupAmount
  ) external payable returns (uint256 expiration);
}
