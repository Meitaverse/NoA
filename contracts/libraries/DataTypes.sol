// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../libraries/LockedBalance.sol";

/**
 * @title DataTypes
 * @author Bitsoul Protocol
 *
 * @notice A standard library of data types used throughout the Bitsoul Protocol.
 */
library DataTypes {
    enum PriceType {FIXED, DECLIINING_BY_TIME, AUCTION, BID}

    enum FeeShareType {
        LEVEL_TWO,
        LEVEL_FIVE
    }

    enum FeePayType {
        SELLER_PAY,
        BUYER_PAY
    }
    
    enum CurrencyType {
        ETHER,
        ERC20,
        ERC3525
    }

    /**
     * @notice An enum containing the different states the protocol can be in, limiting certain actions.
     *
     * @param Unpaused The fully unpaused state.
     * @param PublishingPaused The state where only publication creation functions are paused.
     * @param Paused The fully paused state.
     */
    enum ProtocolState {
        Unpaused,
        PublishingPaused,
        Paused
    }
    
    enum DerivativeNFTState {
        Unpaused,
        PublishingPaused,
        Paused
    }
    
    struct SoulBoundTokenDetail {
        string nickName;
        string imageURI;
        bool locked;
    }
    
    struct HubData {
        uint256 soulBoundTokenId;
        string name;
        string description;
        string imageURI;
    }

    struct HubInfoData {
        uint256 soulBoundTokenId;
        address hubOwner;
        string name;
        string description;
        string imageURI;
    }

    /**
     * @dev  Store Organizer create project 
     * @param hubId hub id
     * @param soulBoundTokenId soulBoundTokenId of this project
     * @param name project name 
     * @param description Description of project
     * @param image Image of project, ipfs or arweave url
     * @param metadataURI metadata 
     * @param descriptor descriptor for SVG 
     * @param defaultRoyaltyPoints the default Royalty Points
     * @param permitByHubOwner  Default false. If true: User prePublish must permit by hub owner 
     */
    struct ProjectData {
        uint256 hubId;
        uint256 soulBoundTokenId;
        string name;
        string description;
        string image;
        string metadataURI;
        address descriptor;
        uint16 defaultRoyaltyPoints;
        bool permitByHubOwner;
    }
    
    /**
     * @notice Properties of the publication datas, using for publish parameters
     * @param soulBoundTokenId id of SBT
     * @param hubId id of hub
     * @param projectId id of project
     * @param salePrice price for sale
     * @param royaltyBasisPoints fee point of publish, base 10000, when royalty      
     * @param currency Which currency to pay
     * @param amount amount of publish
     * @param name name of publication, must unique
     * @param description description of publication
     * @param canCollect bool indicate can collect by other user, default is true
     * @param materialURIs array of  material URI,  ipfs or arweave uri
     * @param fromTokenIds array of from tokenIds
     * @param collectModule collect module
     * @param collectModuleInitData  init data of collect module
     * @param publishModule publish module
     * @param publishModuleInitData  init data of publish module
     */
    struct Publication {
        uint256 soulBoundTokenId;
        uint256 hubId;
        uint256 projectId;
        uint256 salePrice;
        uint16 royaltyBasisPoints;       
        address currency;
        uint256 amount;
        string name;
        string description;
        bool canCollect;
        string[] materialURIs;
        uint256[] fromTokenIds; 
        address collectModule;
        bytes collectModuleInitData;
        address publishModule;
        bytes publishModuleInitData;
    }

    /**
     * @notice A struct containing data associated with each new publication.
     *
     * @param publishId The publish id
     * @param hubId The hub ID 
     * @param projectId The project Id
     * @param name The name
     * @param description The description
     * @param materialURIs The array of the materialURI
     * @param fromTokenIds The array of the fromTokenId
     * @param publishModule The address of the template module associated with this publication, this exists for all publication.
     * @param derivativeNFT The address of the derivativeNFT associated with this publication, if any.
     * @param collectModule The address of the collect module associated with this publication, this exists for all publication.
     */
    struct PublicationStruct {
        uint256 publishId;
        uint256 hubId;
        uint256 projectId;      
        string name;
        string description;
        string[] materialURIs;
        uint256[] fromTokenIds;
        address publishModule;
        address derivativeNFT;
        address collectModule;
    }

    /**
     * @notice Properties of the slot, which determine the value of slot.
     * 
     * @param publication The Publication infomantion
     * @param imageURI The image url of product or preview image
     * @param timestamp The current timestamp
     */
    struct SlotDetail {
        Publication publication;
        string imageURI;
        uint256 timestamp;
    }

    struct CollectData {
        uint256 publishId;
        uint256 collectorSoulBoundTokenId;
        uint256 collectUnits;
        bytes data;
    }    

    struct CollectDataParam {
        uint256 publishId;
        uint256 collectorSoulBoundTokenId;
        uint256 collectUnits;
        bytes data;
        uint256 tokenId;
        uint256 newTokenId;
        address derivativeNFT;
        address sbt;
        address treasury;
    }    
       

    struct AirdropData {
        uint256 publishId;
        uint256 ownershipSoulBoundTokenId;
        uint256[] toSoulBoundTokenIds;
        uint256 tokenId;
        uint256[] values;
    }    

    /**
     * @notice Data of the Publish
     * @param publication The Publication struct
     * @param previousPublishId The previous Publish Id 
     * @param isMinted bool of minted 
     * @param tokenId The token Id of publish
     */
    struct PublishData {
        Publication publication;
        uint256 previousPublishId;
        bool isMinted;
        uint256 tokenId;
    }

    /**
     * @notice Properties of the Market Item
     */
    struct Market {
        bool isOpen;
        FeeShareType feeShareType;
        FeePayType feePayType;
        uint16 royaltySharesPoints;
        uint256 projectId;
        address collectModule;
    }

   
    /**
     * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
     *
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter
     * @param deadline The signature's deadline
     */
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` function.
     *
     * @param wallet The address receiving the profile.
     * @param nickName The nick name to set for the profile, must be unique and non-empty.
     * @param imageURI The URI to set for the profile image.
     */
    struct CreateProfileData {
        address wallet;
        string nickName;
        string imageURI;
    }

    //BankTreasury
    struct ExchangePrice {
        uint256 currencyAmount;
        uint256 sbtAmount;
    }
    
    struct CurrencyInfo {
        string currencyName;
        string currencySymbol;
        uint8 currencyDecimals;
    }
    
    struct Transaction {
        address currency;
        CurrencyType currencyType;
        address to;
        uint256 fromTokenId;
        uint256 toTokenId;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }    

    /**
     * @notice A struct containing the parameters required for the `setDispatcherWithSig()` function. Parameters are the same
     * as the regular `setDispatcher()` function, with an added EIP712Signature.
     *
     * @param soulBoundTokenId The token ID of the SoulBoundToken to set the dispatcher for.
     * @param dispatcher The dispatcher address to set for the profile.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetDispatcherWithSigData {
        uint256 soulBoundTokenId;
        address dispatcher;
        EIP712Signature sig;
    }

    struct CanvasData {
        uint256 width;
        uint256 height;
    }

    struct Position {
        uint256 x;
        uint256 y;
    }

    struct CollectFeeUsers {
       uint256 ownershipSoulBoundTokenId;
       uint256 collectorSoulBoundTokenId;
       uint256 genesisSoulBoundTokenId;
       uint256 previousSoulBoundTokenId;
       uint256 referrerSoulBoundTokenId;
    }

    struct RoyaltyAmounts {
       uint96 treasuryAmount;
       uint96 genesisAmount;
       uint96 previousAmount;
       uint96 referrerAmount;
       uint96 adjustedAmount;
    }

    struct BuyPriceParam {
        /// @notice The SBT Id of seller
        uint256 soulBoundTokenId;

        /// @notice The DNFT contract address.
        address derivativeNFT;

        /// @notice The DNFT token id.
        uint256 tokenId;

        /// @notice The ERC20 currency
        address currency;

        /// @notice The price of one unit
        uint128 salePrice;
    }

    struct OfferParam {
        /// @notice The SBT Id of buyer
        uint256 soulBoundTokenIdBuyer;

        /// @notice The DNFT contract address.
        address derivativeNFT;

        /// @notice tokenId can be empty
        uint256 tokenId; 

        /// @notice The ERC20 currency
        address currency;

        /// @notice max amount to offer 
        uint96 amount;

        uint256 soulBoundTokenIdReferrer;
    }

    /// @notice Stores the buy price details for a specific DNFT.
    /// @dev The struct is packed into a single slot to optimize gas.
    struct BuyPrice {
        /// @notice The SBT id of seller
        uint256 soulBoundTokenIdSeller;

        /// @notice The current owner of this DNFT which set a buy price.
        /// @dev A zero price is acceptable so a non-zero address determines whether a price has been set.
        address payable seller;

        /// @notice The DNFT contract address.
        address derivativeNFT;

        /// @notice The projectId of the DNFT contract.
        uint256 projectId;
        
        /// @notice The publishId of the token.
        uint256 publishId;
        
        /// @notice The DNFT token id.
        uint256 tokenId;

        /// @notice The ERC20 currency
        address currency;

        /// @notice The current buy price set for this DNFT.
        uint128 salePrice;

        /// @notice The current units set for this DNFT.
        uint128 units;

        /// @notice The total amount, units * salePrice
        uint96 amount;
    }

    /// @notice Stores offer details for a specific DNFT.
    struct Offer {
        // @notice The soulBoundTokenId of buyer.
        uint256 soulBoundTokenIdBuyer;
        
        /// @notice The address of the collector who made this offer.
        address buyer;

        address derivativeNFT;

        /// @notice The publishId of the token.
        uint256 publishId;        
        
        /// @notice The expiration timestamp of when this offer expires.
        uint32 expiration;

        /// @notice The ERC20 currency will pay for
        address currency;

        /// @notice The total amount in wei, of the highest offer.
        uint96 amount;

        /// @notice The units of this offer.
        uint128 units;

        /// @notice The soulBoundTokenId of referrer.
        uint256 soulBoundTokenIdReferrer;
    }

    /// @notice The auction configuration for a specific DNFT.
    struct ReserveAuction {
        /// @notice The SBT id of the DNFT owner.
        uint256 soulBoundTokenId;
        /// @notice The address of the DNFT contract.
        address derivativeNFT;
        /// @notice The project id of the DNFT.
        uint256 projectId;
        /// @notice The publishId of the token.
        uint256 publishId;        
        /// @notice The id of the DNFT.
        uint256 tokenId;
        /// @notice The units of auction.
        uint128 units;
        /// @notice The owner of the DNFT which listed it in auction.
        address payable seller;
        /// @notice The duration for this auction.
        uint256 duration;
        /// @notice The extension window for this auction.
        uint256 extensionDuration;
        /// @notice The time at which this auction will not accept any new bids.
        /// @dev This is `0` until the first bid is placed.
        uint256 endTime;
        /// @notice The current highest bidder in this auction.
        /// @dev This is `address(0)` until the first bid is placed.
        address payable bidder;
        /// @notice The SBT id of the bidder.
        uint256 soulBoundTokenIdBidder;

        address currency;

        /// @notice The initial reserve price for the auction.
        uint256 reservePrice;
        
        /// @notice The latest total amount of the DNFT in this auction.
        /// @dev This is set to the reserve price, and then to the highest bid once the auction has started.
        uint96 amount;
    }

    /// @notice Stores the auction configuration for a specific DNFT.
    /// @dev This allows us to modify the storage struct without changing external APIs.
    struct ReserveAuctionStorage {
        uint256 soulBoundTokenId;
        /// @notice The address of the DNFT contract.
        address derivativeNFT;
        /// @notice The project id of the DNFT.
        uint256 projectId;    
        /// @notice The publish id of the DNFT.
        uint256 publishId;        
        /// @notice The id of the DNFT.        
        uint256 tokenId;
        /// @notice The units of this reserve auction.
        uint128 units;
        /// @notice The owner of the DNFT which listed it in auction.
        address payable seller;
        /// @notice The SBT id  of referrer in auction.
        uint256 soulBoundTokenIdReferrer;
        /// @dev This field is no longer used.
        uint256 __gap_was_duration;
        /// @dev This field is no longer used.
        uint256 __gap_was_extensionDuration;
        /// @notice The time at which this auction will not accept any new bids.
        /// @dev This is `0` until the first bid is placed.
        uint256 endTime;
        /// @notice The current highest bidder in this auction.
        /// @dev This is `address(0)` until the first bid is placed.
        address payable bidder;
        /// @notice The SBT id of the bidder.
        uint256 soulBoundTokenIdBidder;
        /// @notice The ERC20 currency.
        address currency;

        /// @notice The initial reserve price for the auction.
        uint256 reservePrice;
        
        /// @notice The latest price of the DNFT in this auction.
        /// @dev This is set to the reserve price * units, and then to the highest bid once the auction has started.
        uint96 amount;
    }    

    /// @notice Tracks an account's info.
    struct AccountInfo {
        /// @notice The number of tokens which have been unlocked already.
        uint96 freedBalance;
        /// @notice The first applicable lockup bucket for this account.
        uint32 lockupStartIndex;
        /// @notice Stores up to 25 buckets of locked balance for a user, one per hour.
        LockedBalance.Lockups lockups;
        /// @notice Returns the amount which a spender is still allowed to withdraw from this account.
        mapping(address => uint256) allowance;
    }

    struct PercentFounderData {
       uint256 escrowAmount;
       uint256 unEscrowTimestamp;
       bool isConfirmedByGenesis;
       uint16 percent;
    }

    struct FounderRevenueData {
        address currency;
        uint96 revenue;
    }


}