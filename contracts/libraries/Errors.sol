// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library Errors {
 /* ========== error definitions ========== */
  // revertedWithCustomError
  error InsufficientEarnestFunds();
  error InsufficientBalance();
  error ZeroValue();
  error NotAllowed();
  error NotOwner();
  error Unauthorized();
  error Locked();
  error EventIdNotExists();
  error NotOwnerNorApproved();
  error NotTransferValueAuthorised();
  error NotSameSlot();
  error AmountLimitNotSet();
  error AmountSBTIsZero();
  error NotSameOwnerOfBothTokenId();
  error TokenExisted(uint256 tokenId);
  error NotProfileOwner();
  error ToIsNotSoulBoundToken();
  error ModuleGlobasNotSet();
  error NotProfileOwnerOrDispatcher();
  error ZeroAddress();
  error EventNotExists();
  error InvalidProjectId();
  error ProjectExisted();
  error TokenIsClaimed();
  error PublicationIsExisted();
  error MaxSupplyExceeded();
  error MaxExceeded();
  error CollectPerAddrLimitExceeded();
  error NFTMarketFees_Invalid_Referrer_Fee();
  error ApproveToOwner();
  error ComboLengthNotEnough();
  error LengthNotSame();
  error Initialized();
  error InvalidParameter();
  error NotSoulBoundTokenOwner();
  error NotHubOwner();
  error HubIdIsZero();
  error TokenIdIsZero();
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
  error NotManagerNorMarketPlace();
  error CanNotSplitToAnother();
  error CanNotTransferValueToAnother();
  error NotManagerNorHubOwner();
  error InitParamsManagerInvalid();
  error InitParamsSBTInvalid();
  error InitParamsTreasuryInvalid();
  error InitParamsMarketPlaceInvalid();
  error CurrencyNotInWhitelisted(address currency);
  error NotBankTreasury();
  error NotSinger();
  error TxNotExists();
  error TxAlreadyExecuted();
  error CannotExecuteTx();
  error ExchangePriceIsZero();
  error AmountIsZero();
  error PaymentError();
  error TxFailed();
  error TransferEtherToBankTreasuryFailed();
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
  error HubCreatorNotWhitelisted();
  error HubOnlyCreateOne();
  error HubNotExists();
  error CallerNotWhitelistedModule();
  error CollectModuleNotWhitelisted();
  error FollowModuleNotWhitelisted();
  error PublishModuleNotWhitelisted();
  error TemplateNotWhitelisted();
  error PublishWithZeroSBT();
  error PublisherSetCanNotCollect();
  error NotSameHub();
  error InsufficientAllowance();
  error InsufficientDerivativeNFT();
  error DerivativeNFTIsZero();
  error PublisherIsZero();
  error ManagerIsZero();
  error InsufficientSBT();
  error CannotUpdateAfterMinted();
  error SBTNotSet();
  error HubOwnerNotPermitPublish();

  // Module Errors
  error InitParamsInvalid();
  error ModuleDataMismatch();
  error TokenDoesNotExist();
  error SetBankTreasuryError();

  
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
  error VoucherIsZeroAmount();
  error VoucherExpired();
  error NotOwnerVoucher();
  error ToWalletIsZero();
  error AirdropTotalExceed();
  error NotOwerOFTokenId();
  error ERC3525INSUFFICIENTBALANCE();

  error InvalidRoyaltyBasisPoints();
  error InvalidRoyalties();
  error MintLimitExceeded();
  error CollectExpired();

  error InvalidRecipientSplits();
  error TooManyRecipients();

  error AmountOnlyIncrease();
  error InvalidSale();
  error OnlySeller();

  //market

  /// @param buyPrice The current buy price set for this DNFT.
  error DNFTMarketBuyPrice_Cannot_Buy_At_Lower_Price(uint256 buyPrice);
  error DNFTMarketBuyPrice_Cannot_Buy_Unset_Price();
  error DNFTMarketBuyPrice_Cannot_Cancel_Unset_Price();
  /// @param owner The current owner of this DNFT.
  error DNFTMarketBuyPrice_Only_Owner_Can_Cancel_Price(address owner);
  /// @param owner The current owner of this DNFT.
  error DNFTMarketBuyPrice_Only_Owner_Can_Set_Price(address owner);
  error DNFTMarketBuyPrice_Price_Already_Set();
  error DNFTMarketBuyPrice_Price_Too_High();
  /// @param seller The current owner of this DNFT.
  error DNFTMarketBuyPrice_Seller_Mismatch(address seller);


  error DNFTMarketOffer_Cannot_Be_Made_While_In_Auction();
  /// @param currentOfferAmount The current highest offer available for this DNFT.
  error DNFTMarketOffer_Offer_Below_Min_Amount(uint256 currentOfferAmount);
  /// @param expiry The time at which the offer had expired.
  error DNFTMarketOffer_Offer_Expired(uint256 expiry);
  /// @param currentOfferFrom The address of the collector which has made the current highest offer.
  error DNFTMarketOffer_Offer_From_Does_Not_Match(address currentOfferFrom);
  /// @param minOfferAmount The minimum amount that must be offered in order for it to be accepted.
  error DNFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(uint256 minOfferAmount);


  /// @param auctionId The already listed auctionId for this DNFT.
  error DNFTMarketReserveAuction_Already_Listed(uint256 auctionId);
  /// @param minAmount The minimum amount that must be bid in order for it to be accepted.
  error DNFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(uint256 minAmount);
  /// @param reservePrice The current reserve price.
  error DNFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(uint256 reservePrice);
  /// @param endTime The timestamp at which the auction had ended.
  error DNFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(uint256 endTime);
  error DNFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
  error DNFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
  /// @param endTime The timestamp at which the auction will end.
  error DNFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(uint256 endTime);
  error DNFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
  error DNFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
  /// @param maxDuration The maximum configuration for a duration of the auction, in seconds.
  error DNFTMarketReserveAuction_Exceeds_Max_Duration(uint256 maxDuration);
  /// @param extensionDuration The extension duration, in seconds.
  error DNFTMarketReserveAuction_Less_Than_Extension_Duration(uint256 extensionDuration);
  error DNFTMarketReserveAuction_Must_Set_Non_Zero_Reserve_Price();
  /// @param seller The current owner of the DNFT.
  error DNFTMarketReserveAuction_Not_Matching_Seller(address seller);
  /// @param owner The current owner of the DNFT.
  error DNFTMarketReserveAuction_Only_Owner_Can_Update_Auction(address owner);
  error DNFTMarketReserveAuction_Price_Already_Set();
  error DNFTMarketReserveAuction_Too_Much_Value_Provided();

  error DerivativeNFT_Must_Be_A_Contract();

  error ExceedsPurchaseLimit();
  error NotInAllowList();
  error UnsupportedDerivativeNFT();
  error MinGTMax();
  error MaxGTTotal();
  error UnitsGTTotal();
  error UnitsLTMin();
  error UnitsGTMax();
  error ExceedsUint128Max();
  error TotalIsZero();
  error NotSeller();
  error Cannot_Deposit_For_Lockup_With_SoulBoundTokenId_Zero();
  error Must_Lockup_Non_Zero_Amount();
  error Must_Deposit_Non_Zero_Amount();
  error Must_Escrow_Non_Zero_Amount();
  error Only_BITSOUL_Voucher_Allowed();
  error Only_BITSOUL_Market_Allowed();
  error Only_Fee_Modules_Allowed();
  error Expiration_Too_Far_In_Future();
  error Invalid_Lockup_Duration();
  error Escrow_Expired();
  error BankTreasury_Only_Can_Transfer_SBT();
  error Escrow_Not_Found();
  error Insufficient_Available_Funds(uint256 amount);
  error Insufficient_Available_EarnestMoneys(uint256 amount);
  error DNFTMarketOffer_Offer_Insufficient_Units(uint256 units);
  error DNFTMarketOffer_BuyPrice_Insufficient_Units(uint256 units);
  error Insufficient_Escrow(uint256 amount);
  error SBT_No_Funds_To_Withdraw();
  error Market_DNFT_Is_Not_Open(address dnft);
  error DerivativeNFTIsInMarket();
  error CollectNotStartYet();
  error TokenIsNotSoulBound();
  error NotProjectOwner();
  error ProjectIdIsZero();
  error ProjectRevenueIsZero();
  error ProjectFounderPercentIsZeroOrExceed();
}
