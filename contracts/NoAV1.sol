// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525SlotEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./libralies/MerkleProof.sol";
import "./interfaces/INoAV1.sol";

contract NoAV1 is Initializable, ContextUpgradeable, INoAV1, ERC3525SlotEnumerableUpgradeable {
   using Strings for uint256;
   using Counters for Counters.Counter;

   Counters.Counter private _eventIds;
   Counters.Counter private _lastId;

   event EventAdded(
        address organizer, 
        uint256 eventId,
        string eventName,
        string eventDescription,
        string eventImage,
        uint256 mintMax
    );
    
    event EventToken(
        uint256 eventId, 
        uint256 tokenId, 
        address organizer, 
        address owner
    );

    event BurnToken(
        uint256 eventId, 
        uint256 tokenId, 
        address owner
    );

    struct EventData {
      bytes32  merkleRoot;
    }

    // eventId => EventData
    mapping(uint256 => EventData)  _eventIdToEventDatas;

    // eventId => Event
    mapping(uint256 => Event) private _eventInfos;

    // slot => slotDetail
    mapping(uint256 => SlotDetail) private _slotDetails;

    // modifer
    modifier eventExist(uint256 eventId_) {
        require(_eventInfos[eventId_].organizer != address(0x0), "NoA: event not exists");
        _;
    }
    
    function initialize(
        string memory name_,
         string memory symbol_, 
         uint8 decimals_,
         address metadataDescriptor
    ) public virtual initializer {
        __ERC3525AllRound_init(name_, symbol_, decimals_);
        _setMetadataDescriptor(metadataDescriptor);
    }

    function __ERC3525AllRound_init(string memory name_, string memory symbol_, uint8 decimals_) internal onlyInitializing {
        __ERC3525_init_unchained(name_, symbol_, decimals_);
    }

    function __ERC3525AllRound_init_unchained() internal onlyInitializing{
    }

    function getSlotDetail(uint256 slot_) public view returns (SlotDetail memory) {
        return _slotDetails[slot_];
    }

    function isWhiteListed(uint256 eventId_, address account_, bytes32[] calldata proof_) public view returns(bool) {
        return _verify(eventId_, _leaf(account_), proof_);
    }

    function setMerkleRoot(uint256 eventId_, bytes32 merkleRoot_) public  {
        _eventIdToEventDatas[eventId_].merkleRoot = merkleRoot_;
    }

    function getLatestTokenId() public view returns(uint256) {
        return _lastId.current();
    }

    function createEvent(
        Event memory event_
    ) public returns(uint256) {
       return _createEvent(event_);
    }

     /**
     * @dev Function to mint event to a user
     * @param slotDetail_ for the new token
     * @param to_ The  address that will receive the minted token.
     */
    function mint(
        SlotDetail memory slotDetail_,
        address to_
    ) external payable eventExist(slotDetail_.eventId) returns (bool)  {
        Event memory eventInfo  = _eventInfos[slotDetail_.eventId];

        require(!eventHasUser(slotDetail_.eventId, to_), "NoA: Token already claimed!");

        require(tokenSupplyInSlot( slotDetail_.eventId) < eventInfo.mintMax, "NoA: max exceeded");

        _lastId.increment(); //tokenId started at 1
        uint256 tokenId_ = _lastId.current();

        uint256 slot = slotDetail_.eventId;  //same slot
        _slotDetails[slot] = SlotDetail({
            eventId: slotDetail_.eventId,
            name: slotDetail_.name,
            description: slotDetail_.description,
            image: slotDetail_.image,            
            eventMetadataURI: slotDetail_.eventMetadataURI
        });

        ERC3525Upgradeable._mint(to_, tokenId_, slot, 1);
        emit EventToken(slotDetail_.eventId, tokenId_, eventInfo.organizer, to_);

        return true;
    }
    
    function getTokenAmountOfEventId(uint256 eventId_) public view returns(uint256){
        return tokenSupplyInSlot(eventId_);
    }
    
     /**
     * @dev Function to mint event to many users
     * @param slotDetail_ for the new token
     * @param to_ The array o addresses that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintEventToManyUsers(
       SlotDetail memory slotDetail_,
       address[] memory to_
    ) external payable returns (bool) { //eventExist(slotDetail_.eventId) 
        Event memory eventInfo  = _eventInfos[slotDetail_.eventId];

        require(tokenSupplyInSlot(slotDetail_.eventId) + to_.length < eventInfo.mintMax, "NoA: max exceeded");

        for (uint256 i = 0; i < to_.length; ++i) {
                        
            require(!eventHasUser(slotDetail_.eventId, to_[i]), "NoA: Token already claimed!");

            _lastId.increment();
            uint256 tokenId_ = _lastId.current();
            uint256 slot = slotDetail_.eventId;  //same slot
            _slotDetails[slot] = SlotDetail({
                eventId: slotDetail_.eventId,
                name: slotDetail_.name,
                description: slotDetail_.description,
                image: slotDetail_.image,                     
                eventMetadataURI: slotDetail_.eventMetadataURI
            });

            ERC3525Upgradeable._mint(to_[i], tokenId_, slot, 1);
            emit EventToken(slotDetail_.eventId, tokenId_, eventInfo.organizer, to_[i]);
        }
        return true;
    }

   
    /**
     * @dev Function to mint tokens
     * @param slotDetails_ SlotDetail array
     * @param to_ The address that will receive the minted tokens. 
     * @return A boolean that indicates if the operation was successful.
     */
    function mintUserToManyEvents(
        SlotDetail[] memory slotDetails_,
        address to_
    ) external payable  returns (bool) {

        for (uint256 i = 0; i < slotDetails_.length; ++i) {
            
            Event memory eventInfo  = _eventInfos[slotDetails_[i].eventId];
            
            require(!eventHasUser(slotDetails_[i].eventId, to_), "NoA: Token already claimed!");

            require(tokenSupplyInSlot(slotDetails_[i].eventId) < eventInfo.mintMax, "NoA: max exceeded");

            _lastId.increment();
            uint256 tokenId_ = _lastId.current();
            uint256 slot = slotDetails_[i].eventId;  //same slot
            _slotDetails[slot] = SlotDetail({
                eventId:slotDetails_[i].eventId,
                name: slotDetails_[i].name,
                description: slotDetails_[i].description,
                image: slotDetails_[i].image,
                eventMetadataURI: slotDetails_[i].eventMetadataURI
            });
            ERC3525Upgradeable._mint(to_, tokenId_, slot, 1);
            emit EventToken(slotDetails_[i].eventId, tokenId_, eventInfo.organizer, to_);
        }
        return true;
    }

    function burn(uint256 tokenId_) public virtual {
        uint256 eventId_ = tokenEvent(tokenId_);
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "NoA: caller is not token owner nor approved");
        ERC3525Upgradeable._burn(tokenId_);
        emit BurnToken(eventId_, tokenId_, msg.sender);
    }

    function eventMetaName(uint256 eventId_)
        public
        view
        eventExist(eventId_)
        returns (string memory)
    {
        return _eventInfos[eventId_].eventName;
    }

    function eventHasUser(uint256 eventId_, address user_)
        public
        view
        eventExist(eventId_)
        returns (bool)
    {
        uint256 balance = balanceOf(user_);
        if (balance == 0 ) {
            return false;
        } else {
            for(uint i= 0; i< balance; i++){
                uint tokeId_ =  tokenOfOwnerByIndex(user_, i);
                 if (slotOf(tokeId_) > 0) {
                     return true;
                 }
            } 
        }
        return false ; 
    }

    function claimNoA(
        SlotDetail memory slotDetail_,
        bytes32[] calldata proof_
    ) 
     external  
    {
        require(isWhiteListed(slotDetail_.eventId, msg.sender, proof_), "Not in whitelisted");

        require(!eventHasUser(slotDetail_.eventId, msg.sender), "NoA: Token already claimed!");

        _lastId.increment();//tokenId started at 1
        uint256 tokenId_ = _lastId.current();

        uint256 slot = slotDetail_.eventId;  //same slot
        _slotDetails[slot] = SlotDetail({
            eventId: slotDetail_.eventId,
            name: slotDetail_.name,
            description: slotDetail_.description,
            image: slotDetail_.image,
            eventMetadataURI: slotDetail_.eventMetadataURI
        });

        ERC3525Upgradeable._mint(msg.sender, tokenId_, slot, 1);
	}

     function getEventInfo(uint256 eventId_)
        public
        view
        eventExist(eventId_)
        returns (Event memory)
    {
        return _eventInfos[eventId_];
    }

    function tokenEvent(uint256 tokenId_)
        public
        view
        returns (uint256)
    {
        //slotOf(..) is eventId
        return slotOf(tokenId_);
    }

    //----internal functions----//
    
    function _leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(uint256 eventId_, bytes32 leaf_, bytes32[] memory proof_) internal view returns(bool) {
        return MerkleProof.verify(proof_, _eventIdToEventDatas[eventId_].merkleRoot, leaf_);
    }

    /**
     * @dev Generate the value of slot by utilizing keccak256 algorithm to calculate the hash
     * value of multi properties.
     */
    function _getSlot(
        uint256 eventId_,
        uint256 tokenId_,
        uint256 sbtId_
    ) internal pure virtual returns (uint256 slot_) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        eventId_,
                        tokenId_,
                        sbtId_
                    )
                )
            );
    }
 
    function _createEvent(
         Event memory event_
    ) internal returns(uint256){
        _eventIds.increment();
        uint256 eventId =  _eventIds.current();
        
        _eventInfos[eventId].organizer = msg.sender;
        _eventInfos[eventId].eventName = event_.eventName;
        _eventInfos[eventId].eventDescription = event_.eventDescription;
        _eventInfos[eventId].eventImage = event_.eventImage;
        _eventInfos[eventId].mintMax = event_.mintMax;

        emit EventAdded(msg.sender, eventId, event_.eventName, event_.eventDescription, event_.eventImage, event_.mintMax);
        return eventId;
    }

    uint256[50] private __gap;
}