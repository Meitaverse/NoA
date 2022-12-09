// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525SlotEnumerableUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./libralies/MerkleProof.sol";
import "./interface/INoAV1.sol";


contract NoAV1 is Initializable, INoAV1, ERC3525SlotEnumerableUpgradeable
 {
/* ========== error definitions ========== */
// revertedWithCustomError
  error InsufficientFund();
  error InsufficientBalance();
  error ZeroValue();
  error NotAllowed();
  error NotAuthorised();
  error NotSameSlot();
  error NotSameOwnerOfBothTokenId();
  error TokenAlreadyExisted(uint256 tokenId);
  error ZeroAddress();
  error EventNotExists();

   using Counters for Counters.Counter;
   using SafeMathUpgradeable for uint256;
   Counters.Counter private _eventIds;

    address private _receiver;
    address private _uToken;
    address private _owner;
    bool private _isWhiteListedMint;

    //price per NoA with UToken
    uint256 private _price;

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;

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

    //===== Initializer =====//

    /// @custom:oz-upgrades-unsafe-allow constructor
    // `initializer` marks the contract as initialized to prevent third parties to
    // call the `initialize` method on the implementation (this contract)
    constructor() initializer {}

    function initialize(
        string memory name_,
        string memory symbol_, 
        address metadataDescriptor_,
        address receiver_,
        address uToken_
    ) public virtual initializer {
        if (metadataDescriptor_ == address(0x0)) {
            revert ZeroAddress();
        }
        if (receiver_ == address(0x0)) {
            revert ZeroAddress();
        }
        if (uToken_ == address(0x0)) {
            revert ZeroAddress();
        }

        __ERC3525_init_unchained(name_, symbol_, 0);
        _setMetadataDescriptor(metadataDescriptor_);
        _owner = msg.sender;
        _isWhiteListedMint = false;
        _receiver = receiver_;
        _uToken = uToken_;
        _price = 0; 
    }

    //only owner
    function setMetadataDescriptor(address metadataDescriptor_) public onlyOwner {
        _setMetadataDescriptor(metadataDescriptor_);
    }

    //only owner
    function setComboPreNoAPrice(uint256 price_) public onlyOwner{
        _price = price_;
    }

    //only owner
    function setWhiteListedMint(bool isWhiteListMint_) public onlyOwner {
        _isWhiteListedMint = isWhiteListMint_;
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
        require(!_eventHasUser(slotDetail_.eventId, to_), "NoA: Token already claimed!");

        require(tokenSupplyInSlot(slotDetail_.eventId) <  _eventInfos[slotDetail_.eventId].mintMax, "NoA: max exceeded");

        uint256 slot = slotDetail_.eventId;  //same slot
        if (_slotDetails[slot].eventId == 0) {
            _slotDetails[slot] = SlotDetail({
                eventId: slotDetail_.eventId,
                name: slotDetail_.name,
                description: slotDetail_.description,
                image: slotDetail_.image,            
                eventMetadataURI: slotDetail_.eventMetadataURI
            });

        }

        uint256 tokenId_ = ERC3525Upgradeable._mint(to_, slot, 1);
        emit EventToken(slotDetail_.eventId, tokenId_,  _eventInfos[slotDetail_.eventId].organizer, to_);

        return true;
    }

    //TODO any one can called 
    function mintEventToManyUsers(
       SlotDetail memory slotDetail_,
       address[] memory to_
    ) public payable eventExist(slotDetail_.eventId)  returns (bool) { 

        require(tokenSupplyInSlot(slotDetail_.eventId) + to_.length <  _eventInfos[slotDetail_.eventId].mintMax, "NoA: max exceeded");
        uint256 slot = slotDetail_.eventId;  //same slot

        if (_slotDetails[slot].eventId == 0) {
            _slotDetails[slot] = SlotDetail({
                eventId: slotDetail_.eventId,
                name: slotDetail_.name,
                description: slotDetail_.description,
                image: slotDetail_.image,                     
                eventMetadataURI: slotDetail_.eventMetadataURI
            });
        }

        for (uint256 i = 0; i < to_.length; ++i) {
            require(!_eventHasUser(slotDetail_.eventId, to_[i]), "NoA: Token already claimed!");
            uint256 tokenId_ = ERC3525Upgradeable._mint(to_[i], slot, 1);
            emit EventToken(slotDetail_.eventId, tokenId_, _eventInfos[slotDetail_.eventId].organizer, to_[i]);
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
        require(fromTokenIds_.length >= 2, "NoA: combo must need at least 2 tokens");
        //must same slot
        for (uint256 i = 0; i < fromTokenIds_.length; ++i) {
            require(_isApprovedOrOwner(msg.sender, fromTokenIds_[i]), "NoA: caller is not token owner nor approved");
            require(eventId_  ==  slotOf(fromTokenIds_[i]), "NoA: event id error");
            //cant not burn
            transferFrom(fromTokenIds_[i], _receiver, 1);
        }

        uint256 slot =  _slotDetails[eventId_].eventId;  //same slot
        _slotDetails[slot] = SlotDetail({
            eventId:  _slotDetails[eventId_].eventId,
            name:  _slotDetails[eventId_].name,
            description:  _slotDetails[eventId_].description,
            image: image_,            
            eventMetadataURI: eventMetadataURI_
        });  
        uint256 amount_ = 1;  
        uint256 tokenId_ ;
        if ( _eventInfos[eventId_].organizer == msg.sender) {
            amount_  = value_;
            tokenId_ = ERC3525Upgradeable._mint(to_, slot, value_);
        } else {
            tokenId_ = ERC3525Upgradeable._mint(to_, slot, 1);
        }
        _validating(amount_.mul(_price));
        emit EventToken( _slotDetails[eventId_].eventId, tokenId_, _eventInfos[eventId_].organizer, to_);
        return true;
    }

    function burn(uint256 tokenId_) public virtual {
        uint256 eventId_ = slotOf(tokenId_);
        require(_isApprovedOrOwner(msg.sender, tokenId_) || msg.sender == _owner, "NoA: caller is not token owner nor approved");
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

    //----internal functions----//
    function _eventHasUser(uint256 eventId_, address user_)
        internal
        view
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

    function _createEvent(
         Event memory event_
    ) internal returns(uint256){
        _eventIds.increment();
        uint256 eventId =  _eventIds.current();
        
        _eventInfos[eventId].organizer = msg.sender;
        _eventInfos[eventId].eventName = event_.eventName;
        _eventInfos[eventId].eventImage = event_.eventImage;
        _eventInfos[eventId].eventDescription = event_.eventDescription;
        _eventInfos[eventId].mintMax = event_.mintMax;

        emit EventAdded(msg.sender, eventId, event_.eventName, event_.eventDescription, event_.eventImage, event_.mintMax);
        return eventId;
    }

    /**
     * @notice Validates the uToken asset and the value.
     *  receive wallet is _receiver contract
     * @param value_ Value
     */
    function _validating(uint256 value_) internal {
        if (value_ == 0) {
            return;
            //TODO revert ZeroValue();
        }

        // if uToken is zero address then see the slot receives ETH (only if it's on Ethereum/Goerli)
        if (_uToken == address(0)) {
            revert ZeroAddress();
        }

        if (_uToken != address(0)) {
            if (msg.value > 0) { // just in case the user send ETH accidently
                revert NotAllowed();
            }

            if (IERC20Upgradeable(_uToken).balanceOf(_msgSender()) < value_) {
                revert InsufficientBalance();
            }
            if (IERC20Upgradeable(_uToken).allowance(_msgSender(), _receiver) < value_) {
                revert InsufficientFund();
            }
            
            IERC20Upgradeable(_uToken).transferFrom(_msgSender(), _receiver, value_);
        }
    }
  
   //-----approval functions----//

    function setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) public payable virtual  {
        require(_msgSender() == owner_ || isApprovedForAll(owner_, _msgSender()), "NoA: caller is not owner nor approved for all");
        _setApprovalForSlot(owner_, slot_, operator_, approved_);
    }

    function isApprovedForSlot(
        address owner_,
        uint256 slot_,
        address operator_
    ) public view virtual  returns (bool) {
        return _slotApprovals[owner_][slot_][operator_];
    }

    function _setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) internal virtual {
        require(owner_ != operator_, "NoA: approve to owner");
        _slotApprovals[owner_][slot_][operator_] = approved_;
        emit ApprovalForSlot(owner_, slot_, operator_, approved_);
    }


    uint256[50] private __gap;
}