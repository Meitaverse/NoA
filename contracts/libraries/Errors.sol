// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library Errors {
 /* ========== error definitions ========== */
  // revertedWithCustomError
  error InsufficientFund();
  error InsufficientBalance();
  error ZeroValue();
  error NotAllowed();
  error Unauthorized();
  error Locked();
  error EventIdNotExists();
  error NotOwnerNorApproved();
  error NotAuthorised();
  error NotSameSlot();
  error NotSameOwnerOfBothTokenId();
  error TokenExisted(uint256 tokenId);
  error ZeroAddress();
  error EventNotExists();
  error ProjectExisted();
  error TokenIsClaimed();
  error PublicationIsExisted();
  error MaxExceeded();
  error ApproveToOwner();
  error ComboLengthNotEnough();
  error EventIdNotSame();
  error Initialized();
  error InvalidParameter();
  error NotSoulBoundTokenOwner();
  error CannotInitImplementation();
  error NotGovernance();
  error NotManager();
  error EmergencyAdminCannotUnpause();
  error NotGovernanceOrEmergencyAdmin();
  error PublicationDoesNotExist();
  error ArrayMismatch();
  error FollowInvalid();
  error ZeroSpender();
  error ZeroIncubator();
  error SignatureExpired();
  error SignatureInvalid();

  // Module Errors
  error InitParamsInvalid();
  error ModuleDataMismatch();
  error TokenDoesNotExist();

  // MultiState Errors
  error Paused();
  error PublishingPaused();


  //Receiver Errors
  error RevertWithMessage();
  error RevertWithoutMessage();
  // error Panic();
}