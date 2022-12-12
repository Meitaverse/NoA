// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title DataTypes
 * @author ShowDao Protocol
 *
 * @notice A standard library of data types used throughout the ShowDao Protocol.
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
    

    /**
     * @dev  Store Organizer create event 
     * @param organizer Event of Organizer
     * @param eventName Event name 
     * @param eventDescription Description of event
     * @param eventImage Image of event, ipfs or arweave url
     * @param mintMax Max count can mint
     */
    struct Event {
      address organizer;
      string eventName;
      string eventDescription;
      string eventImage;
      string eventMetadataURI;
      uint256 mintMax;
    }
    
    /**
     * @notice Properties of the slot, which determine the value of slot.
     */
    struct SlotDetail {
      string name;
      string description;
      uint256 eventId;
      string eventMetadataURI;
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
        uint256 eventId;
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


}