// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/ERC3525SlotEnumerableUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {Errors} from "./libraries/Errors.sol";
import {DataTypes} from './libraries/DataTypes.sol';
import {Events} from "./libraries/Events.sol";
import {INoAV1} from "./interfaces/INoAV1.sol";

/**
 *  @title Derivative NFT
 * 
 * 
 * , and includes built-in governance power and delegation mechanisms.
 */
contract NoAV1 is INoAV1, ERC3525SlotEnumerableUpgradeable {
    using Counters for Counters.Counter;
    using SafeMathUpgradeable for uint256;

    bool private _initialized;

    Counters.Counter private _eventIds;

    uint256 internal _soulBoundTokenId;
    address internal _governance;
    address internal _emergencyAdmin;
    address internal _receiver;

    uint256 internal _royaltyBasisPoints; //版税佣金点数

    // bytes4(keccak256('royaltyInfo(uint256,uint256)')) == 0x2a55205a
    bytes4 internal constant INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint16 internal constant BASIS_POINTS = 10000;

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;

    // eventId => EventData
    // mapping(uint256 => bytes32) private _eventIdTomerkleRoots;

    // eventId => Event
    mapping(uint256 => DataTypes.Event) private _eventInfos;

    // slot => slotDetail
    mapping(uint256 => DataTypes.SlotDetail) private _slotDetails;


    //===== Initializer =====//

    /// @custom:oz-upgrades-unsafe-allow constructor
    // `initializer` marks the contract as initialized to prevent third parties to
    // call the `initialize` method on the implementation (this contract)
    constructor() initializer {

    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address metadataDescriptor_,
        address receiver_
    ) external override initializer {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;

        if (metadataDescriptor_ == address(0x0)) revert Errors.ZeroAddress();
        if (receiver_ == address(0x0)) revert Errors.ZeroAddress();

        __ERC3525_init_unchained(name_, symbol_, 0);
        _setMetadataDescriptor(metadataDescriptor_);

        _receiver = receiver_;
    }

    //only owner
    function setMetadataDescriptor(address metadataDescriptor_) external {
        _setMetadataDescriptor(metadataDescriptor_);
    }

    function createEvent(DataTypes.Event memory event_) external returns (uint256) {
        return _createEvent(event_);
    }

    function mint(DataTypes.SlotDetail memory slotDetail_, address to_) external payable returns (bool) {
        if (_eventInfos[slotDetail_.eventId].organizer == address(0x0)) {
            revert Errors.EventIdNotExists();
        }

        if (_eventHasUser(slotDetail_.eventId, to_)) {
            revert Errors.TokenIsClaimed();
        }

        if (tokenSupplyInSlot(slotDetail_.eventId) >= _eventInfos[slotDetail_.eventId].mintMax) {
            revert Errors.MaxExceeded();
        }

        uint256 slot = slotDetail_.eventId; //same slot
        if (_slotDetails[slot].eventId == 0) {
            _slotDetails[slot] = DataTypes.SlotDetail({
                eventId: slotDetail_.eventId,
                name: slotDetail_.name,
                description: slotDetail_.description,
                image: slotDetail_.image,
                eventMetadataURI: slotDetail_.eventMetadataURI
            });
        }

        uint256 tokenId_ = ERC3525Upgradeable._mint(to_, slot, 1);
        emit Events.EventToken(slotDetail_.eventId, tokenId_, _eventInfos[slotDetail_.eventId].organizer, to_);

        return true;
    }

    //TODO any one can called
    function mintEventToManyUsers(
        DataTypes.SlotDetail memory slotDetail_,
        address[] memory to_
    ) external payable returns (bool) {
        if (_eventInfos[slotDetail_.eventId].organizer == address(0x0)) {
            revert Errors.EventIdNotExists();
        }

        if (tokenSupplyInSlot(slotDetail_.eventId) + to_.length >= _eventInfos[slotDetail_.eventId].mintMax) {
            revert Errors.MaxExceeded();
        }

        uint256 slot = slotDetail_.eventId; //same slot

        if (_slotDetails[slot].eventId == 0) {
            _slotDetails[slot] = DataTypes.SlotDetail({
                eventId: slotDetail_.eventId,
                name: slotDetail_.name,
                description: slotDetail_.description,
                image: slotDetail_.image,
                eventMetadataURI: slotDetail_.eventMetadataURI
            });
        }

        for (uint256 i = 0; i < to_.length; ++i) {
            if (_eventHasUser(slotDetail_.eventId, to_[i])) {
                revert Errors.TokenIsClaimed();
            }

            uint256 tokenId_ = ERC3525Upgradeable._mint(to_[i], slot, 1);
            emit Events.EventToken(slotDetail_.eventId, tokenId_, _eventInfos[slotDetail_.eventId].organizer, to_[i]);
        }
        return true;
    }

    function combo(
        uint256 eventId_,
        uint256[] memory fromTokenIds_,
        string memory image_,
        string memory eventMetadataURI_,
        address to_,
        uint256 value_
    ) external payable returns (bool) {
        if (fromTokenIds_.length < 2) {
            revert Errors.ComboLengthNotEnough();
        }
        //must same slot
        for (uint256 i = 0; i < fromTokenIds_.length; ++i) {
            if (!(_isApprovedOrOwner(msg.sender, fromTokenIds_[i]))) {
                revert Errors.NotOwnerNorApproved();
            }

            if (eventId_ != slotOf(fromTokenIds_[i])) {
                revert Errors.EventIdNotSame();
            }

            //cant not burn
            transferFrom(fromTokenIds_[i], _receiver, 1);
        }

        uint256 slot = _slotDetails[eventId_].eventId; //same slot
        _slotDetails[slot] = DataTypes.SlotDetail({
            eventId: _slotDetails[eventId_].eventId,
            name: _slotDetails[eventId_].name,
            description: _slotDetails[eventId_].description,
            image: image_,
            eventMetadataURI: eventMetadataURI_
        });

        uint256 amount_ = 1;
        uint256 tokenId_;
        if (_eventInfos[eventId_].organizer == msg.sender) {
            amount_ = value_;
            tokenId_ = ERC3525Upgradeable._mint(to_, slot, value_);
        } else {
            tokenId_ = ERC3525Upgradeable._mint(to_, slot, 1);
        }
        emit Events.EventToken(_slotDetails[eventId_].eventId, tokenId_, _eventInfos[eventId_].organizer, to_);
        return true;
    }

    // Publications
    // function publish(uint256 tokenId_, uint256 value_) external virtual {

    // }

    function burn(uint256 tokenId_) external virtual {
        uint256 eventId_ = slotOf(tokenId_);
        if (!(_isApprovedOrOwner(msg.sender, tokenId_) || msg.sender == _governance)) {
            revert Errors.NotAllowed();
        }
        ERC3525Upgradeable._burn(tokenId_);
        emit Events.BurnToken(eventId_, tokenId_, msg.sender);
    }

    function getSlotDetail(uint256 slot_) external view returns (DataTypes.SlotDetail memory) {
        return _slotDetails[slot_];
    }

    function getEventInfo(uint256 eventId_) external view returns (DataTypes.Event memory) {
        if (_eventInfos[eventId_].organizer == address(0x0)) {
            revert Errors.EventIdNotExists();
        }

        return _eventInfos[eventId_];
    }

    //------override------------//
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC3525SlotEnumerableUpgradeable) returns (bool) {
        return
            interfaceId == type(IERC3525SlotEnumerable).interfaceId ||
            interfaceId == INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    //----internal functions----//
    function _eventHasUser(uint256 eventId_, address user_) internal view returns (bool) {
        uint256 balance = balanceOf(user_);
        if (balance == 0) {
            return false;
        } else {
            for (uint i = 0; i < balance; i++) {
                uint tokeId_ = tokenOfOwnerByIndex(user_, i);
                if (slotOf(tokeId_) == eventId_) {
                    return true;
                }
            }
        }
        return false;
    }

    function _createEvent(DataTypes.Event memory event_) internal returns (uint256) {
        _eventIds.increment();
        uint256 eventId = _eventIds.current();

        _eventInfos[eventId].organizer = msg.sender;
        _eventInfos[eventId].eventName = event_.eventName;
        _eventInfos[eventId].eventImage = event_.eventImage;
        _eventInfos[eventId].eventDescription = event_.eventDescription;
        _eventInfos[eventId].mintMax = event_.mintMax;

        emit Events.EventAdded(
            msg.sender,
            eventId,
            event_.eventName,
            event_.eventDescription,
            event_.eventImage,
            event_.mintMax
        );
        return eventId;
    }

    //-----approval functions----//

    function setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) external payable virtual {
        if (!(_msgSender() == owner_ || isApprovedForAll(owner_, _msgSender()))) {
            revert Errors.NotAllowed();
        }
        _setApprovalForSlot(owner_, slot_, operator_, approved_);
    }

    function isApprovedForSlot(address owner_, uint256 slot_, address operator_) external view virtual returns (bool) {
        return _slotApprovals[owner_][slot_][operator_];
    }

    function _setApprovalForSlot(address owner_, uint256 slot_, address operator_, bool approved_) internal virtual {
        if (owner_ == operator_) {
            revert Errors.ApproveToOwner();
        }
        _slotApprovals[owner_][slot_][operator_] = approved_;
        emit Events.ApprovalForSlot(owner_, slot_, operator_, approved_);
    }


    // function getRevision() internal pure virtual override returns (uint256) {
    //     return REVISION;
    // }

   

    uint256[50] private __gap;
}