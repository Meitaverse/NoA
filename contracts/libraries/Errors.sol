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
  error NotProfileOwner();
  error NotProfileOwnerOrDispatcher();
  error ZeroAddress();
  error EventNotExists();
  error ProjectExisted();
  error TokenIsClaimed();
  error PublicationIsExisted();
  error MaxExceeded();
  error ApproveToOwner();
  error ComboLengthNotEnough();
  error LengthNotSame();
  error Initialized();
  error InvalidParameter();
  error NotSoulBoundTokenOwner();
  error NotHubOwner();
  error SoulBoundTokenIdNotExists();
  error TokenIdNotExists();
  error HandleLengthInvalid();
  error HandleContainsInvalidCharacters();
  error NickNameLengthInvalid();
  error NickNameContainsInvalidCharacters();
  error ProfileImageURILengthInvalid();
  error CannotInitImplementation();
  error NotGovernance();
  error NotManager();
  error NotBankTreasury();
  error NotSinger();
  error TxNotExists();
  error TxAlreadyExecuted();
  error CannotExecuteTx();
  error ExchangePriceIsZero();
  error AmountIsZero();
  error PaymentError();
  error TxFailed();
  error TxNotConfirmed();
  error TxAlreadyConfirmed();
  error SignersRequired();
  error SignerNotUnique();
  error InvalidSignersNumbers();
  error InvalidSigner();
  error EmergencyAdminCannotUnpause();
  error NotGovernanceOrEmergencyAdmin();
  error PublicationDoesNotExist();
  error ArrayMismatch();
  error FollowInvalid();
  error ZeroSpender();
  error SignatureExpired();
  error SignatureInvalid();
  error ProfileCreatorNotWhitelisted();
  error CallerNotWhitelistedModule();
  error CollectModuleNotWhitelisted();
  error FollowModuleNotWhitelisted();
  error PublishModuleNotWhitelisted();
  error PublishWithZeroNDPT();
  error NotSameHub();
  error InsufficientAllowance();
  error InsufficientDerivativeNFT();
  error DerivativeNFTIsZero();
  error PublisherIsZero();
  error ManagerIsZero();
  error InsufficientNDPT();
  error CannotUpdateAfterMinted();
  error NDPTNotSet();

  // Module Errors
  error InitParamsInvalid();
  error ModuleDataMismatch();
  error TokenDoesNotExist();
  error InitialIsAlreadyDone();

  // MultiState Errors
  error Paused();
  error PublishingPaused();


  //Receiver Errors
  error RevertWithMessage();
  error RevertWithoutMessage();
  // error Panic();

  error UpdateURITwice();
  error InvidVoucherParValueType();
  error VoucherNotExists();
  error VoucherIsUsed();
  error NotOwnerVoucher();
  error ToWalletIsZero();
  error AirdropTotalExceed();
  error NotOwerOFTokenId();
  error ERC3525INSUFFICIENTBALANCE();

  error InvalidRoyaltyBasisPoints();
  error MintLimitExceeded();
  error CollectExpired();

  error InvalidRecipientSplits();
}