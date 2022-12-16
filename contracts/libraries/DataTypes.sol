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
    
    struct Hub {
        uint256 soulBoundTokenId;
        string name;
        string description;
        string image;
        string metadataURI;
        uint256 timestamp;
    }

    /**
     * @dev  Store Organizer create project 
     * @param hubId hub id
     * @param organizer Organizer of project
     * @param name project name 
     * @param description Description of project
     * @param image Image of project, ipfs or arweave url
     * @param metadataURI metadata 
     */
    struct Project {
        uint256 hubId;
        address organizer;
        string name;
        string description;
        string image;
        string metadataURI;
        uint256 timestamp;
    }
    
    /**
     * @notice Properties of the slot, which determine the value of slot.
     */
    struct SlotDetail {
        uint256 soulBoundTokenId;
        Publication publication;
        // uint256[] previousDerivativeNFTIds;     //from array of dNFT Ids
        // uint256[] previousSoulBoundTokenIds;  //NDPT token id
        uint256 projectId;
        uint256 timestamp; //minted timestamp
    }

    /**
     * @notice Properties of the Publication, using with publish 
     * @param name name of publication
     * @param description description of publication
     * @param materialURIs array of  material URI,  ipfs or arweave uri
     * @param fromTokenIds array of from tokenIds
     */
    struct Publication {
      string name;
      string description;
      string[] materialURIs;
      uint256[] fromTokenIds;
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
        uint256 soundBoundTokenId;
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
     * @param imageURI The URI to set for the profile image.
     * @param followModule The follow module to use, can be the zero address.
     * @param followModuleInitData The follow module initialization data, if any.
     * @param followNFTURI The URI to use for the follow NFT.
     */
    struct CreateProfileData {
        address to;
        string handle;
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
     * @param profileIdPointed The profile token ID this publication points to, for mirrors and comments.
     * @param pubIdPointed The publication ID this publication points to, for mirrors and comments.
     * @param contentURI The URI associated with this publication.
     * @param referenceModule The address of the current reference module in use by this publication, can be empty.
     * @param collectModule The address of the collect module associated with this publication, this exists for all publication.
     * @param collectNFT The address of the collectNFT associated with this publication, if any.
     */
    struct PublicationStruct {
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        string contentURI;
        address referenceModule;
        address collectModule;
        address collectNFT;
    }

    //BankTreasury
    
    struct Transaction {
        address currency;
        DataTypes.CurrencyType currencyType;
        address to;
        uint256 fromTokenId;
        uint256 toTokenId;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }    


}