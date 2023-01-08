// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
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
contract DerivativeNFTV1 is 
    IDerivativeNFTV1, 
    DerivativeNFTMultiState, 
    ERC3525Upgradeable
{
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
    // using SafeMathUpgradeable for uint256;

    bool private _initialized;

    Counters.Counter private  _nextSlotId;

    uint256 internal _projectId;  //one derivativeNFT include one projectId
    uint256 internal _soulBoundTokenId;

    address internal _emergencyAdmin;
    address internal _receiver;
    DataTypes.FeeShareType internal _feeShareType;

    // solhint-disable-next-line var-name-mixedcase
    address public immutable MANAGER;
    // solhint-disable-next-line var-name-mixedcase
    address internal _SBT;
    // solhint-disable-next-line var-name-mixedcase
    address internal _BANKTREASURY;

    uint96 internal _royaltyBasisPoints; //版税佣金点数, 本协议将版税的10%及金库固定税收5%设置为

    mapping(uint256 => uint256) internal _tokenIdToPublishId;

    // bytes4(keccak256('royaltyInfo(uint256,uint256)')) == 0x2a55205a
    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint16 internal constant _BASIS_POINTS = 10000;

     struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

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
        MANAGER = manager;
        _initialized = true;
    }

    function initialize(
        address sbt, 
        address bankTreasury,
        string memory name_,
        string memory symbol_,
        uint256 projectId_,
        uint256 soulBoundTokenId_,
        address metadataDescriptor_,
        address receiver_,
        uint96 defaultRoyaltyPoints_,
        DataTypes.FeeShareType feeShareType_
    ) public virtual initializer {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        
        if (sbt == address(0)) revert Errors.InitParamsInvalid();
        _SBT = sbt;
        if (bankTreasury == address(0)) revert Errors.InitParamsInvalid();
        _BANKTREASURY = bankTreasury;

        if (metadataDescriptor_ == address(0x0)) revert Errors.ZeroAddress();

         __ERC3525_init_unchained(name_, symbol_, 0);

        _setMetadataDescriptor(metadataDescriptor_);

        //default Unpaused
        _setState(DataTypes.DerivativeNFTState.Unpaused);

        _projectId = projectId_;
        _soulBoundTokenId = soulBoundTokenId_;
        _receiver = receiver_;

        _setDefaultRoyalty(_BANKTREASURY, defaultRoyaltyPoints_);

        _feeShareType = feeShareType_;

    }

    //only owner
    function setMetadataDescriptor(address metadataDescriptor_) external onlyManager {
        _setMetadataDescriptor(metadataDescriptor_);
    }

    function setState(DataTypes.DerivativeNFTState newState) external override onlyManager{
        _setState(newState);
    }
    
    function setTokenRoyalty(
        uint256 tokenId,
        address recipient,
        uint96 fraction
    ) public onlyManager {
        _setTokenRoyalty(tokenId, recipient, fraction);
    }

    function setDefaultRoyalty(address recipient, uint96 fraction) public onlyManager{
        _setDefaultRoyalty(recipient, fraction);
    }

    function getDefaultRoyalty() external view returns(uint96) {
        return _defaultRoyaltyInfo.royaltyFraction;
    }

    function deleteDefaultRoyalty() public onlyManager{
        _deleteDefaultRoyalty();
    }

    // Publication only can publish once
    function publish(
        uint256 publishId,
        DataTypes.Publication memory publication,
        address publisher
    ) external whenNotPaused onlyManager returns (uint256) { //
        
        if (_publicationNameHashBySlot[keccak256(bytes(publication.name))] > 0) revert Errors.PublicationIsExisted();
        if (publication.soulBoundTokenId != _soulBoundTokenId && publication.fromTokenIds.length == 0) revert Errors.InvalidParameter();
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
            publication: publication,
            // projectId:  _projectId,
            timestamp: block.timestamp 
        });

        _publicationNameHashBySlot[keccak256(bytes(publication.name))] = slot;
        uint256 newTokenId = ERC3525Upgradeable._createOriginalTokenId();
        _tokenIdToPublishId[newTokenId] = publishId;

        _mint(publisher, newTokenId, slot, publication.amount);
        
        return newTokenId;
    }

    function split(
        uint256 publishId_, 
        uint256 fromTokenId_, 
        address to_,
        uint256 value_
    ) external whenNotPaused onlyManager returns(uint256) {
        uint256 newTokenId = ERC3525Upgradeable._createDerivedTokenId(fromTokenId_);
      
        _tokenIdToPublishId[newTokenId] = publishId_;
        _mint(to_, newTokenId, ERC3525Upgradeable.slotOf(fromTokenId_), 0);

        ERC3525Upgradeable._transferValue(fromTokenId_, newTokenId, value_);

        return newTokenId;
    }

    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external override whenNotPaused {
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
    ) external override whenNotPaused {
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
    ) external override whenNotPaused {
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
        _resetTokenRoyalty(tokenId_);
        emit Events.BurnToken(slot, tokenId_, msg.sender, block.timestamp);
    }

    function burnWithSig(uint256 tokenId, DataTypes.EIP712Signature calldata sig)
        public
        virtual
        override
        whenNotPaused
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
        uint256 slot = slotOf(tokenId);
        ERC3525Upgradeable._burn(tokenId);
        _resetTokenRoyalty(tokenId);
        
        emit Events.BurnTokenWithSig(slot, tokenId, owner, block.timestamp);
    }

    function getSlotDetail(uint256 slot_) external view returns (DataTypes.SlotDetail memory) {
        return _slotDetails[slot_];
    }

    function transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) external whenNotPaused onlyManager {
        ERC3525Upgradeable._transferValue(fromTokenId_, toTokenId_, value_);
    }
    
    //------override------------//
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override whenNotPaused returns (uint256) { //onlyManager
        //to_ must a valid SBT Id
        uint256 _toSoulBoundTokenId = IManager(MANAGER).getSoulBoundTokenIdByWallet(to_);
        if (_toSoulBoundTokenId == 0 ) revert Errors.ToIsNotSoulBoundToken();

        uint256 newTokenId = super.transferFrom(fromTokenId_, to_, value_);
      
        //set royalty
        uint256 publishId = _tokenIdToPublishId[fromTokenId_];
        uint96 _fraction;
        if (_feeShareType == DataTypes.FeeShareType.LEVEL_TWO) {
            _fraction = IManager(MANAGER).calculateRoyalty(publishId);
        } else {
             _fraction = _royaltyBasisPoints;
        }

        //set royalties
        _setTokenRoyalty(
            newTokenId,
            _BANKTREASURY,
            _fraction
        );

       return newTokenId;
    }

    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override whenNotPaused  { //onlyManager
      super.transferFrom(fromTokenId_, toTokenId_, value_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override  whenNotPaused  { //onlyManager
        //to_ must a valid SBT wallet who had create profile
        uint256 _toSoulBoundTokenId = IManager(MANAGER).getSoulBoundTokenIdByWallet(to_);
        if (_toSoulBoundTokenId == 0 ) revert Errors.ToIsNotSoulBoundToken();
        super.transferFrom(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override  whenNotPaused  { //onlyManager
        //to_ must a valid SBT Id
        uint256 _toSoulBoundTokenId = IManager(MANAGER).getSoulBoundTokenIdByWallet(to_);
        if (_toSoulBoundTokenId == 0 ) revert Errors.ToIsNotSoulBoundToken();
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override  whenNotPaused {  //onlyManager
        //to_ must a valid SBT Id
        uint256 _toSoulBoundTokenId = IManager(MANAGER).getSoulBoundTokenIdByWallet(to_);
        if (_toSoulBoundTokenId == 0 ) revert Errors.ToIsNotSoulBoundToken();
       super.safeTransferFrom(from_, to_, tokenId_, "");
    }

    function _mint(address to_, uint256 tokenId_, uint256 slot_, uint256 value_) internal virtual override {
        super._mint(to_, tokenId_, slot_, value_);

        uint256 publishId = _tokenIdToPublishId[tokenId_];
        uint96 _fraction;
        if (_feeShareType == DataTypes.FeeShareType.LEVEL_TWO) {
            _fraction = IManager(MANAGER).calculateRoyalty(publishId);
        } else {
             _fraction = _royaltyBasisPoints;
        }

        //set royalties
        _setTokenRoyalty(
            tokenId_,
            _BANKTREASURY,
            _fraction
        );
    }

    // function setApprovalForAll(
    //     address operator_, 
    //     bool approved_
    // ) public virtual override onlyManager whenNotPaused{
    //     super._setApprovalForAll(_msgSender(), operator_, approved_);
    // }

    function setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) external payable virtual whenNotPaused onlyManager {
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
    }

    /**
     * @notice Changes the royalty percentage for secondary sales. Can only be called publication's
     *         soulBoundToken owner.
     *
     * @param royaltyBasisPoints The royalty percentage meassured in basis points. Each basis point
     *                           represents 0.01%.
     */
    function setRoyalty(uint96 royaltyBasisPoints) external whenNotPaused onlyManager {
        if (IERC3525(_SBT).ownerOf(_soulBoundTokenId) == msg.sender) {
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
     * @param _tokenId The token ID of the derivativeNFT queried for royalty information.
     * @param _salePrice The sale price of the derivativeNFT specified.
     * @return A tuple with the address who should receive the royalties and the royalty
     * payment amount for the given sale price.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);

    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return _BASIS_POINTS;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    function _validateCallerIsManager() internal view {
        if (msg.sender != MANAGER) revert Errors.NotManager();
    }

    function _validateCallerIsSoulBoundTokenOwner(uint256 soulBoundTokenId_) internal view {
        if (IERC3525(_SBT).ownerOf(soulBoundTokenId_) != msg.sender) revert Errors.NotProfileOwner();
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