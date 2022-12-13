// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {Errors} from "./libraries/Errors.sol";
import {DataTypes} from './libraries/DataTypes.sol';
import {Events} from "./libraries/Events.sol";
import {IManager} from "./interfaces/IManager.sol";
import {IDerivativeNFTV1} from "./interfaces/IDerivativeNFTV1.sol";
 import "./base/NoAMultiState.sol";

/**
 *  @title Derivative NFT
 * 
 * 
 * , and includes built-in governance power and delegation mechanisms.
 */
contract DerivativeNFTV1 is IDerivativeNFTV1, NoAMultiState, ERC3525Upgradeable {
    using Counters for Counters.Counter;
    using SafeMathUpgradeable for uint256;

    bool private _initialized;

    Counters.Counter private  _nextSlotId;

    uint256 internal _hubId;
    uint256 internal _projectId;
    uint256 internal _soulBoundTokenId;

    address internal _emergencyAdmin;
    address internal _receiver;

    // solhint-disable-next-line var-name-mixedcase
    address private immutable _MANAGER;
    // solhint-disable-next-line var-name-mixedcase
    address private immutable _NDPT;

    uint256 internal _royaltyBasisPoints; //版税佣金点数

    // bytes4(keccak256('royaltyInfo(uint256,uint256)')) == 0x2a55205a
    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint16 internal constant _BASIS_POINTS = 10000;

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;

    // slot => slotDetail
    mapping(uint256 => DataTypes.SlotDetail) private _slotDetails;

    //publication Name to Slot
    mapping(bytes32 => uint256) internal _publicationNameHashBySlot;

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyManager() {
        _validateCallerIsManager();
        _;
    }
    

    //===== Initializer =====//

    /// @custom:oz-upgrades-unsafe-allow constructor
    // `initializer` marks the contract as initialized to prevent third parties to
    // call the `initialize` method on the implementation (this contract)
    constructor(address manager, address ndpt) initializer {
        if (manager == address(0)) revert Errors.InitParamsInvalid();
        _MANAGER = manager;
        _NDPT = ndpt;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 hubId_,
        uint256 projectId_,
        uint256 soulBoundTokenId_,
        address metadataDescriptor_
    ) external override initializer { 
        if (_initialized) revert Errors.Initialized();
        _initialized = true;

        if (metadataDescriptor_ == address(0x0)) revert Errors.ZeroAddress();

        __ERC3525_init_unchained(name_, symbol_, 0);
        _setMetadataDescriptor(metadataDescriptor_);

        //default Unpaused
        _setState(DataTypes.ProtocolState.Unpaused);

        _hubId = hubId_;
         _projectId = projectId_;
        _soulBoundTokenId = soulBoundTokenId_;
        _receiver = IManager(_MANAGER).getReceiver();
    }

    //only owner
    function setMetadataDescriptor(address metadataDescriptor_) external onlyManager {
        _setMetadataDescriptor(metadataDescriptor_);
    }

    function setState(DataTypes.ProtocolState newState) external override onlyManager{
        _setState(newState);
    }


    // Publication only can publish once
    function publish(
        uint256 soulBoundTokenId,
        DataTypes.Publication memory publication,
        uint256 value_
    ) external virtual onlyManager whenPublishingEnabled returns (uint256) {
        if (_publicationNameHashBySlot[keccak256(bytes(publication.name))] > 0) revert Errors.PublicationIsExisted();
        if (soulBoundTokenId != _soulBoundTokenId && publication.fromTokenIds.length == 0) revert Errors.InvalidParameter();
        
        for (uint256 i = 0; i < publication.fromTokenIds.length; ++i) {
            if (!(_isApprovedOrOwner(msg.sender, publication.fromTokenIds[i])))  revert Errors.NotOwnerNorApproved();

            //cant not burn
            this.transferFrom(publication.fromTokenIds[i], _receiver, 1);
        }

        uint256 slot = _generateNextSlotId(); //auto increase

        _slotDetails[slot] = DataTypes.SlotDetail({
            soulBoundTokenId: soulBoundTokenId,
            publication: DataTypes.Publication(
                publication.name,
                publication.description,
                publication.materialURIs,
                publication.fromTokenIds
            ),
            projectId:  _projectId,
            timestamp: block.timestamp 
        });

        _publicationNameHashBySlot[keccak256(bytes(publication.name))] = slot;

        address to_ = IManager(_MANAGER).getIncubatorOfSoulBoundTokenId(soulBoundTokenId);
        if (!ERC3525Upgradeable.isApprovedForAll(to_, _MANAGER)) {
            ERC3525Upgradeable.setApprovalForAll(_MANAGER, true);
        }
        return ERC3525Upgradeable._mint(to_, slot, value_);
    }

    function split(
        uint256 toSoulBoundTokenId_,
        uint256 fromTokenId_, 
        uint256 value_
    ) external onlyManager whenNotPaused returns(uint256) {
        address to_ = IManager(_MANAGER).getIncubatorOfSoulBoundTokenId(toSoulBoundTokenId_);
        if (!ERC3525Upgradeable.isApprovedForAll(to_, _MANAGER)) {
            ERC3525Upgradeable.setApprovalForAll(_MANAGER, true);
        }
        return ERC3525Upgradeable.transferFrom(fromTokenId_, to_, value_);
    }

    function burn(uint256 tokenId_) external virtual whenNotPaused {
        uint256 slot = slotOf(tokenId_);
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) {
            revert Errors.NotAllowed();
        }
        ERC3525Upgradeable._burn(tokenId_);
        emit Events.BurnToken(slot, tokenId_, msg.sender);
    }

    function getSlotDetail(uint256 slot_) external view returns (DataTypes.SlotDetail memory) {
        return _slotDetails[slot_];
    }

    function getProjectInfo(uint256 projectId_) external view returns (DataTypes.Project memory) {
       
        return IManager(_MANAGER).getProjectInfo(projectId_);
    }

    //------override------------//
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override onlyManager whenNotPaused returns (uint256) {
       return super.transferFrom(fromTokenId_, to_, value_);
    }

    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override onlyManager whenNotPaused {
      super.transferFrom(fromTokenId_, toTokenId_, value_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override onlyManager whenNotPaused {
        super.transferFrom(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override onlyManager whenNotPaused {
        super.safeTransferFrom(from_, to_, tokenId_,data_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override onlyManager whenNotPaused {
       super.safeTransferFrom(from_, to_, tokenId_, "");
    }

    function setApprovalForAll(
        address operator_, 
        bool approved_
    ) public virtual override onlyManager whenNotPaused{
        super._setApprovalForAll(_msgSender(), operator_, approved_);
    }

    //----internal functions----//


    //-----approval functions----//

    function setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) external payable virtual onlyManager whenNotPaused{
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

    /**
     * @notice Changes the royalty percentage for secondary sales. Can only be called publication's
     *         soulBoundToken owner.
     *
     * @param royaltyBasisPoints The royalty percentage meassured in basis points. Each basis point
     *                           represents 0.01%.
     */
    function setRoyalty(uint256 royaltyBasisPoints) external onlyManager {
        if (IERC3525(_NDPT).ownerOf(_soulBoundTokenId) == msg.sender) {
            if (royaltyBasisPoints > _BASIS_POINTS) {
                revert Errors.InvalidParameter();
            } else {
                _royaltyBasisPoints = royaltyBasisPoints;
            }
        } else {
            revert Errors.NotSoulBoundTokenOwner();
        }
    }

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     *
     *
     * @param tokenId The token ID of the NoA queried for royalty information.
     * @param salePrice The sale price of the NoA specified.
     * @return A tuple with the address who should receive the royalties and the royalty
     * payment amount for the given sale price.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        return (
            IERC3525(_NDPT).ownerOf(_soulBoundTokenId),
            (salePrice * _royaltyBasisPoints) / _BASIS_POINTS
        );
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _validateCallerIsManager() internal view {
        if (msg.sender != _MANAGER) revert Errors.NotManager();
    }

    function _generateNextSlotId() internal returns (uint256) {
        _nextSlotId.increment();
        return uint24(_nextSlotId.current());
    }


    uint256[50] private __gap;

}