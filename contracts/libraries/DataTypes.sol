// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title DataTypes
 * @author Bitsoul Protocol
 *
 * @notice A standard library of data types used throughout the Bitsoul Protocol.
 */
library DataTypes {
    enum PriceType {FIXED, DECLIINING_BY_TIME}

    //0.1eth, 0.2eth, 0.3eth, 0.4eth, 0.5 eth
    enum VoucherParValueType {ZEROPOINTONE, ZEROPOINTTWO, ZEROPOINTTHREE, ZEROPOINTFOUR, ZEROPOINTFIVE}

    enum FeeType {
        BY_AMOUNT,
        FIXED
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
    
    struct TokenInfoData {
        uint256 id;
        address owner;
        string nickName;
        string handle;
        string tokenName;
    }
    
    struct SoulBoundTokenDetail {
        string nickName;
        string handle;
        bool locked;
        uint256 reputation;
    }
    
    struct HubData {
        address creator;
        uint256 soulBoundTokenId;
        string name;
        string description;
        string image;
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
     */
    struct ProjectData {
        uint256 hubId;
        uint256 soulBoundTokenId;
        string name;
        string description;
        string image;
        string metadataURI;
        address descriptor;
    }
    
    /**
     * @notice Properties of the Publication, using with publish 
     * @param soulBoundTokenId id of NDPT
     * @param hubId id of hub
     * @param projectId id of project
     * @param amount amount of publish
     * @param name name of publication
     * @param description description of publication
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
        uint256 amount;
        string name;
        string description;
        string[] materialURIs;
        uint256[] fromTokenIds;
        address collectModule;
        bytes collectModuleInitData;
        address publishModule;
        bytes publishModuleInitData;
    }
        
    /**
     * @notice Properties of the slot, which determine the value of slot.
     */
    struct SlotDetail {
        uint256 soulBoundTokenId;
        Publication publication;
        uint256 projectId;
        uint256 timestamp; //minted timestamp
    }

    struct CollectData {
        uint256 publishId;
        uint256 collectorSoulBoundTokenId;
        uint256 collectValue;
    }    

    struct AirdropData {
        uint256 publishId;
        uint256 ownershipSoulBoundTokenId;
        uint256[] toSoulBoundTokenIds;
        uint256 tokenId;
        uint256[] values;
    }    

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
        bool isValid;
        uint64 precision;
        FeeType feeType;
        FeePayType feePayType;
        uint128 feeAmount;
        uint16 feeRate;
    }

    struct Sale {
        uint24 saleId;
        uint256 soulBoundTokenId;
        uint256 projectId;
        uint256 tokenId;
        uint32 startTime;
        address seller;
        uint128 price;
        PriceType priceType;
        uint256 total; //sale units
        uint128 units; //current units
        uint128 min; //min units
        uint128 max; //max units
        address derivativeNFT; //sale asset
        address currency; //pay currency
        bool useAllowList;
        bool isValid;
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
     * @param to The address receiving the profile.
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param nickName The nick name to set for the profile, must be unique and non-empty.
     * @param imageURI The URI to set for the profile image.
     * @param followModule The follow module to use, can be the zero address.
     * @param followModuleInitData The follow module initialization data, if any.
     * @param followNFTURI The URI to use for the follow NFT.
     */
    struct CreateProfileData {
        address to;
        string handle;
        string nickName;
        string imageURI;
        address followModule;
        bytes followModuleInitData;
        string followNFTURI;
    }

    /**
     * @notice A struct containing profile data.
     *
     * @param pubCount The number of publications made to this profile.
     * @param followModule The address of the current follow module in use by this profile, can be empty.
     * @param followNFT The address of the followNFT associated with this profile, can be empty..
     * @param handle The profile's associated handle.
     * @param imageURI The URI to be used for the profile's image.
     * @param followNFTURI The URI to be used for the follow NFT.
     */
    struct ProfileStruct {
        uint256 pubCount;
        address followModule;
        address followNFT;
        string handle;
        string imageURI;
        string followNFTURI;
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
        uint256 ndptValue;
        uint256 generateTimestamp;
        uint256 deadTimestamp;
        bool isUsed;
        uint256 soulBoundTokenId;
        uint256 usedTimestamp;
    }
}