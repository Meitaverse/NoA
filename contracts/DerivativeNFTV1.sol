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
import "./base/DerivativeNFTMultiState.sol";

/**
 *  @title Derivative NFT
 * 
 * , and includes built-in governance power and delegation mechanisms.
 */
contract DerivativeNFTV1 is IDerivativeNFTV1, DerivativeNFTMultiState, ERC3525Upgradeable {
    bytes32 internal constant EIP712_REVISION_HASH = keccak256('1');
    bytes32 internal constant SET_DISPATCHER_WITH_SIG_TYPEHASH =
        keccak256(
            'SetDispatcherWithSig(uint256 profileId,address dispatcher,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant BURN_WITH_SIG_TYPEHASH =
        keccak256('BurnWithSig(uint256 tokenId,uint256 nonce,uint256 deadline)');
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        );
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256('Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');
    bytes32 internal constant PERMIT_FOR_ALL_TYPEHASH =
        keccak256(
            'PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)'
        );
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant PERMIT_VALUE_TYPEHASH =
        keccak256('PermitValue(address spender,uint256 tokenId,uint256 value,uint256 nonce,uint256 deadline)');
    
    using Counters for Counters.Counter;
    using SafeMathUpgradeable for uint256;

    bool private _initialized;

    Counters.Counter private  _nextSlotId;

    uint256 internal _hubId;
    uint256 internal _projectId;  //one derivativeNFT include one projectId
    uint256 internal _soulBoundTokenId;

    address internal _emergencyAdmin;
    address internal _receiver;

    // solhint-disable-next-line var-name-mixedcase
    address internal _MANAGER;
    // solhint-disable-next-line var-name-mixedcase
    address internal _NDPT;
    // solhint-disable-next-line var-name-mixedcase
    address internal _BANKTREASURY;

    uint256 internal _royaltyBasisPoints; //版税佣金点数, 本协议将版税的10%及金库固定税收5%设置为

    // bytes4(keccak256('royaltyInfo(uint256,uint256)')) == 0x2a55205a
    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint16 internal constant _BASIS_POINTS = 10000;

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;

    // slot => slotDetail
    mapping(uint256 => DataTypes.SlotDetail) private _slotDetails;

    //publication Name to Slot
    mapping(bytes32 => uint256) internal _publicationNameHashBySlot;


    mapping(address => uint256) public sigNonces;

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
    constructor(address manager) {
        if (manager == address(0)) revert Errors.InitParamsInvalid();
        _MANAGER = manager;
    }

    function initialize(
        address ndpt, 
        address bankTreasury,
        string memory name_,
        string memory symbol_,
        uint256 hubId_,
        uint256 projectId_,
        uint256 soulBoundTokenId_,
        address metadataDescriptor_
    ) external override initializer {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        
        if (ndpt == address(0)) revert Errors.InitParamsInvalid();
        _NDPT = ndpt;
        if (bankTreasury == address(0)) revert Errors.InitParamsInvalid();
        _BANKTREASURY = bankTreasury;

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
        DataTypes.Publication memory publication
    ) external virtual onlyManager whenPublishingEnabled returns (uint256) {
        if (_publicationNameHashBySlot[keccak256(bytes(publication.name))] > 0) revert Errors.PublicationIsExisted();
        //if (publication.soulBoundTokenId != _soulBoundTokenId && publication.fromTokenIds.length == 0) revert Errors.InvalidParameter();
        if (publication.projectId != _projectId) {
            revert Errors.InvalidParameter();
        }
        
        for (uint256 i = 0; i < publication.fromTokenIds.length; ++i) {
            if (!(_isApprovedOrOwner(msg.sender, publication.fromTokenIds[i])))  revert Errors.NotOwnerNorApproved();

            //cant not burn
            this.transferFrom(publication.fromTokenIds[i], _receiver, 1);
        }

        uint256 slot = _generateNextSlotId(); //auto increase

        _slotDetails[slot] = DataTypes.SlotDetail({
            soulBoundTokenId: publication.soulBoundTokenId,
            publication: publication,
            projectId:  _projectId,
            timestamp: block.timestamp 
        });

        _publicationNameHashBySlot[keccak256(bytes(publication.name))] = slot;

        address to_ = IManager(_MANAGER).getIncubatorOfSoulBoundTokenId(publication.soulBoundTokenId);
        if (!ERC3525Upgradeable.isApprovedForAll(to_, _MANAGER)) {
            ERC3525Upgradeable.setApprovalForAll(_MANAGER, true);
        }
        return ERC3525Upgradeable._mint(to_, slot, publication.amount);
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

    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        if (spender == address(0)) revert Errors.ZeroSpender();
        address owner = ownerOf(tokenId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            spender,
                            tokenId,
                            sigNonces[owner]++,
                            sig.deadline
                        )
                    )
                ),
                owner,
                sig
            );
        }
        _approve(spender, tokenId);
    }
    
    function permitValue(
        address spender,
        uint256 tokenId,
        uint256 value,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        if (spender == address(0)) revert Errors.ZeroSpender();
        
        address owner = ownerOf(tokenId);

        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            PERMIT_VALUE_TYPEHASH,
                            spender,
                            tokenId,
                            value,
                            sigNonces[owner]++,
                            sig.deadline
                        )
                    )
                ),
                owner,
                sig
            );
        }
        approve(tokenId, spender, value);
    }

    function permitForAll(
        address owner,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        if (operator == address(0)) revert Errors.ZeroSpender();
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            PERMIT_FOR_ALL_TYPEHASH,
                            owner,
                            operator,
                            approved,
                            sigNonces[owner]++,
                            sig.deadline
                        )
                    )
                ),
                owner,
                sig
            );
        }
        _setApprovalForAll(owner, operator, approved);
    }

    function burn(uint256 tokenId_) external virtual whenNotPaused {
        uint256 slot = slotOf(tokenId_);
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) {
            revert Errors.NotAllowed();
        }
        ERC3525Upgradeable._burn(tokenId_);
        emit Events.BurnToken(slot, tokenId_, msg.sender);
    }
    
    function burnWithSig(uint256 tokenId, DataTypes.EIP712Signature calldata sig)
        public
        virtual
        override
    {
        address owner = ownerOf(tokenId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            BURN_WITH_SIG_TYPEHASH,
                            tokenId,
                            sigNonces[owner]++,
                            sig.deadline
                        )
                    )
                ),
                owner,
                sig
            );
        }
        _burn(tokenId);
    }

    function getSlotDetail(uint256 slot_) external view returns (DataTypes.SlotDetail memory) {
        return _slotDetails[slot_];
    }

    function getProjectInfo(uint256 projectId_) external view returns (DataTypes.ProjectData memory) {
       
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
     * @param tokenId The token ID of the derivativeNFT queried for royalty information.
     * @param salePrice The sale price of the derivativeNFT specified.
     * @return A tuple with the address who should receive the royalties and the royalty
     * payment amount for the given sale price.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        //TODO , get salePrice from PriceManager
        tokenId;
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


    function _validateCallerIsSoulBoundTokenOwner(uint256 soulBoundTokenId_) internal view {
        if (IERC3525(_NDPT).ownerOf(soulBoundTokenId_) != msg.sender) revert Errors.NotProfileOwner();
    }

    function _generateNextSlotId() internal returns (uint256) {
        _nextSlotId.increment();
        return uint24(_nextSlotId.current());
    }

    function getDomainSeparator() external view override returns (bytes32) {
        return _calculateDomainSeparator();
    }

    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(
        bytes32 digest,
        address expectedAddress,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        if (sig.deadline < block.timestamp) revert Errors.SignatureExpired();
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        if (recoveredAddress == address(0) || recoveredAddress != expectedAddress)
            revert Errors.SignatureInvalid();
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(name())),
                    EIP712_REVISION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
     *
     * @param hashedMessage The message hash from which the digest should be calculated.
     *
     * @return bytes32 A 32-byte output representing the EIP712 digest.
     */
    function _calculateDigest(bytes32 hashedMessage) internal view returns (bytes32) {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked('\x19\x01', _calculateDomainSeparator(), hashedMessage)
            );
        }
        return digest;
    }    
}