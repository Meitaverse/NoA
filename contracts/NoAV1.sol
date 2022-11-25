// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solvprotocol/erc-3525/contracts/ERC3525SlotEnumerableUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./libralies/MerkleProof.sol";
import "./interfaces/INoAV1.sol";

contract NoAV1
    is 
    INoAV1, 
    ERC3525SlotEnumerableUpgradeable
 {
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

    event Publish(
        uint256 eventId, 
        uint256 tokenId, 
        address organizer, 
        address owner,
        uint256 value
    );
    
    event BurnToken(
        uint256 eventId, 
        uint256 tokenId, 
        address owner
    );

    address private _receiver;
    address private _owner;
    bool private _isWhiteListedMint;

    // eventId => EventData
    mapping(uint256 => bytes32) private _eventIdTomerkleRoots;

    // eventId => Event
    mapping(uint256 => Event) private _eventInfos;

    // slot => slotDetail
    mapping(uint256 => SlotDetail) private _slotDetails;

    // modifer
    modifier eventExist(uint256 eventId_) {
        require(_eventInfos[eventId_].organizer != address(0x0), "NoA: event not exists");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == _owner, "NoA: Not owner");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_, 
        address metadataDescriptor,
        address receiver_
    ) public virtual initializer {
        __ERC3525_init_unchained(name_, symbol_, 0);
        _setMetadataDescriptor(metadataDescriptor);
        _owner = msg.sender;
        _isWhiteListedMint = false;
        _receiver = receiver_;
    }

    //only owner
    function setMetadataDescriptor(address metadataDescriptor_) public onlyOwner returns(bool) {
        _setMetadataDescriptor(metadataDescriptor_);
        return true;
    }

    //only owner
    function setWhiteListedMint(bool isWhiteListMint_) public onlyOwner returns(bool) {
        _isWhiteListedMint = isWhiteListMint_;
        return true;
    }

    function setMerkleRoot(uint256 eventId_, bytes32 merkleRoot_) public  {
        require( _eventInfos[eventId_].organizer == msg.sender, "NoA: Not organizer");
        _eventIdTomerkleRoots[eventId_] = merkleRoot_;
    }

    function createEvent(
        Event memory event_
    ) public returns(uint256) {
       return _createEvent(event_);
    }

    function mint(
        SlotDetail memory slotDetail_,
        address to_,
        bytes32[] calldata proof_
    ) public payable eventExist(slotDetail_.eventId) returns (bool)  {
        if (_isWhiteListedMint){
         require(_isWhiteListed(slotDetail_.eventId, to_, proof_), "NoA: Not allow");
        }

        Event memory eventInfo  = _eventInfos[slotDetail_.eventId];

        require(!_eventHasUser(slotDetail_.eventId, to_), "NoA: Token already claimed!");

        require(tokenSupplyInSlot(slotDetail_.eventId) < eventInfo.mintMax, "NoA: max exceeded");

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

    function mintEventToManyUsers(
       SlotDetail memory slotDetail_,
       address[] memory to_
    ) public payable returns (bool) { //eventExist(slotDetail_.eventId) 
        Event memory eventInfo  = _eventInfos[slotDetail_.eventId];

        require(tokenSupplyInSlot(slotDetail_.eventId) + to_.length < eventInfo.mintMax, "NoA: max exceeded");

        for (uint256 i = 0; i < to_.length; ++i) {
                        
            require(!_eventHasUser(slotDetail_.eventId, to_[i]), "NoA: Token already claimed!");

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

    function combo(
        uint256 eventId_ , 
        uint256[] memory fromTokenIds_, 
        string memory image_,
        string memory eventMetadataURI_,
        address to_,
        uint256 value_
    ) public payable returns (bool){
        require(fromTokenIds_.length>1 , "NoA: at least 2");
        //must same slot
        for (uint256 i = 0; i < fromTokenIds_.length; ++i) {
            require(_isApprovedOrOwner(msg.sender, fromTokenIds_[i]), "NoA: caller is not token owner nor approved");
            require(eventId_  ==  slotOf(fromTokenIds_[i]), "NoA: event id error");
            //cant not burn
            transferFrom(fromTokenIds_[i], _receiver, 1);

        }
        Event memory eventInfo  = _eventInfos[eventId_];
        SlotDetail memory slotDetail_ = _slotDetails[eventId_];

        _lastId.increment(); //tokenId started at 1
        uint256 tokenId_ = _lastId.current();

        uint256 slot = slotDetail_.eventId;  //same slot
        _slotDetails[slot] = SlotDetail({
            eventId: slotDetail_.eventId,
            name: slotDetail_.name,
            description: slotDetail_.description,
            image: image_,            
            eventMetadataURI: eventMetadataURI_
        });    
        if ( _eventInfos[eventId_].organizer == msg.sender) {
            ERC3525Upgradeable._mint(to_, tokenId_, slot, value_);

        } else {
             ERC3525Upgradeable._mint(to_, tokenId_, slot, 1);
        }
        emit EventToken(slotDetail_.eventId, tokenId_, eventInfo.organizer, to_);
        return true;
    }

    function burn(uint256 tokenId_) public virtual {
        uint256 eventId_ = slotOf(tokenId_);
        require(_isApprovedOrOwner(msg.sender, tokenId_), "NoA: caller is not token owner nor approved");
        ERC3525Upgradeable._burn(tokenId_);
        emit BurnToken(eventId_, tokenId_, msg.sender);
    }

    function getSlotDetail(uint256 slot_) public view returns (SlotDetail memory) {
        return _slotDetails[slot_];
    }

    function getEventInfo(uint256 eventId_)
        public
        view
        eventExist(eventId_)
        returns (Event memory)
    {
        return _eventInfos[eventId_];
    }


    //------override------------//
    
    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override {
        super._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }

    function _afterValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override {
        super._afterValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }

    //----internal functions----//
    function _eventHasUser(uint256 eventId_, address user_)
        internal
        view
        // eventExist(eventId_)
        returns (bool)
    {
        uint256 balance = balanceOf(user_);
        if (balance == 0 ) {
            return false;
        } else {
            for(uint i= 0; i< balance; i++){
                uint tokeId_ =  tokenOfOwnerByIndex(user_, i);
                 if (slotOf(tokeId_) == eventId_) {
                     return true;
                 }
            } 
        }
        return false ; 
    }

    function _isWhiteListed(uint256 eventId_, address account_, bytes32[] calldata proof_) private view returns(bool) {
        return _verify(eventId_, _leaf(account_), proof_);
    }

    function _leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(uint256 eventId_, bytes32 leaf_, bytes32[] memory proof_) internal view returns(bool) {
        return MerkleProof.verify(proof_, _eventIdTomerkleRoots[eventId_], leaf_);
    }

    /**
     * @dev Generate the value of slot by utilizing keccak256 algorithm to calculate the hash
     * value of multi properties.
     */
    function _getSlot(
        uint256 eventId_,
        uint256 tokenId_
    ) internal pure virtual returns (uint256 slot_) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        eventId_,
                        tokenId_
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