// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title DataTypes
 * @author Bitsoul Protocol
 *
 * @notice A standard library of data types used throughout the Bitsoul Protocol.
 */
library DataTypes {
    enum PriceType {FIXED, DECLIINING_BY_TIME, AUCTION, BID}

    //0.1eth, 0.2eth, 0.3eth, 0.4eth, 0.5 eth
    enum VoucherParValueType {ZEROPOINT, ZEROPOINTONE, ZEROPOINTTWO, ZEROPOINTTHREE, ZEROPOINTFOUR, ZEROPOINTFIVE}

    // enum FeeType {
    //     BY_AMOUNT,
    //     FIXED
    // }

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

    /**
     * @dev  Store Organizer create project 
     * @param hubId hub id
     * @param soulBoundTokenId soulBoundTokenId of this project
     * @param name project name 
     * @param description Description of project
     * @param image Image of project, ipfs or arweave url
     * @param metadataURI metadata 
     * @param descriptor descriptor for SVG 
     * @param defaultRoyaltyPoints default royalty points
     * @param feeShareType fee share type, level two or five
     * @param permitByHubOwner True: User prePublish will permit by hub owner, default false
     */
    struct ProjectData {
        uint256 hubId;
        uint256 soulBoundTokenId;
        string name;
        string description;
        string image;
        string metadataURI;
        address descriptor;
        uint96  defaultRoyaltyPoints;
        FeeShareType feeShareType;
        bool permitByHubOwner;
    }
    
    /**
     * @notice Properties of the publication datas, using for publish paramters
     * @param soulBoundTokenId id of SBT
     * @param hubId id of hub
     * @param projectId id of project
     * @param salePrice price for sale
     * @param royaltyBasisPoints fee point of publish, base 10000, when royalty      
     * @param amount amount of publish
     * @param name name of publication
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
        uint256 royaltyBasisPoints;          
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
        uint256 timestamp; //minted timestamp
    }

    struct CollectData {
        uint256 publishId;
        uint256 collectorSoulBoundTokenId;
        uint256 collectUnits;
        bytes data;
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
        uint16 royaltyBasisPoints;
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

    //voucher struct
    struct VoucherData {
        VoucherParValueType vouchType;
        uint256 tokenId;
        uint256 etherValue;
        uint256 sbtValue;
        uint256 generateTimestamp;
        uint256 endTimestamp;
        bool isUsed;
        uint256 soulBoundTokenId;
        uint256 usedTimestamp;
    }

    struct CollectFeeUsers {
       uint256 ownershipSoulBoundTokenId;
       uint256 collectorSoulBoundTokenId;
       uint256 genesisSoulBoundTokenId;
       uint256 previousSoulBoundTokenId;
       uint256 referrerSoulBoundTokenId;
    }

    struct RoyaltyAmounts {
    //    uint256 collectUnits;
       uint256 treasuryAmount;
       uint256 genesisAmount;
       uint256 previousAmount;
       uint256 referrerAmount;
       uint256 adjustedAmount;
    }

    struct SaleParam {
        uint256 soulBoundTokenId;

        /// @notice The DNFT contract address.
        address derivativeNFT;

        /// @notice The DNFT token id.
        uint256 tokenId;
        
        /// @notice The uints want put on list
        uint128 onSellUnits;

        /// @notice The start time on sell
        uint32 startTime;

        /// @notice The sale price
        uint128 salePrice;

        /// @notice The minimum unit buy limit
        uint128 min;

        /// @notice The miximum unit limit
        uint128 max;
    }

    struct Sale {
        uint256 soulBoundTokenId;
        uint256 projectId;
        uint256 tokenId;
        uint256 tokenIdOfMarket;
        uint32 startTime;
        uint128 salePrice;
        PriceType priceType;
        uint128 onSellUnits; //on sell units
        uint128 seledUnits; //selled units
        uint128 min; //min units
        uint128 max; //max units
        address derivativeNFT; //sale asset
        bool isOpen;
        uint256 genesisSoulBoundTokenId;
        uint256 genesisRoyaltyBasisPoints;
        uint256 previousSoulBoundTokenId;
        uint256 previousRoyaltyBasisPoints;
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

        /// @notice When DNFT is escrowed, a new tokenId is generated.
        uint256 tokenIdEscrow;

        /// @notice The start time on sell
        uint32 startTime;

        /// @notice The current buy price set for this DNFT.
        uint128 salePrice;

        /// @notice The current units set for this DNFT.
        uint128 onSellUnits;

        /// @notice The selled units.
        uint128 seledUnits; 

        /// @notice The min units.
        uint128 min;

        /// @notice The max units
        uint128 max; 
    }

    /// @notice Stores offer details for a specific DNFT.
    struct Offer {
        uint256 soulBoundTokenId;
        
        // Slot 1: When increasing an offer, only this slot is updated.
        /// @notice The expiration timestamp of when this offer expires.
        uint32 expiration;

        /// @notice The amount, in wei, of the highest offer.
        uint96 amount;

        /// @notice First slot (of 16B) used for the offerReferrerAddress.
        // The offerReferrerAddress is the address used to pay the
        // referrer on an accepted offer.
        // uint128 offerReferrerAddressSlot0;

        // Slot 2: When the buyer changes, both slots need updating
        /// @notice The address of the collector who made this offer.
        address buyer;
        
        /// @notice The units of this offer.
        uint128 units;

        /// @notice Second slot (of 4B) used for the offerReferrerAddress.
        // uint32 offerReferrerAddressSlot1;
        // 96 bits (12B) are available in slot 1.

        uint256 soulBoundTokenIdReferrer;
    }

}