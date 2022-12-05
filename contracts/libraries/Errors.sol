// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library Errors {
 /* ========== error definitions ========== */
  // revertedWithCustomError
  error InsufficientFund();
  error InsufficientBalance();
  error ZeroValue();
  error NotAllowed();
  error EventIdNotExists();
  error NotOwnerNorApproved();
  error NotAuthorised();
  error NotSameSlot();
  error NotSameOwnerOfBothTokenId();
  error TokenExisted(uint256 tokenId);
  error ZeroAddress();
  error EventNotExists();
  error TokenIsClaimed();
  error MaxExceeded();
  error ApproveToOwner();
  error ComboLengthNotEnough();
  error EventIdNotSame();

}