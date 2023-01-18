// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {Errors} from "./libraries/Errors.sol";
import {DataTypes} from './libraries/DataTypes.sol';
import {IManager} from "./interfaces/IManager.sol";
import {IDerivativeNFTV1} from "./interfaces/IDerivativeNFTV1.sol";
import "./base/DerivativeNFTMultiState.sol";
import {Constants} from './libraries/Constants.sol';

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
  
    /**
     * @dev Emitted when a derivativeNFT's URI is set.
     *
     * @param tokenId The token ID of the derivativeNFT for which the URI is set.
     * @param imageURI The URI set for the given derivativeNFT.
     * @param timestamp The current block timestamp.
     */
    event DerivativeNFTImageURISet(
        uint256 indexed tokenId, 
        string imageURI, 
        uint256 timestamp
    );

    /**
     * @dev Emitted when a dNFT is burned.
     *
     * @param projectId The newly created profile's token ID.
     * @param tokenId The profile creator, who created the token with the given profile ID.
     * @param owner The image uri set for the profile.
     * @param timestamp The current block timestamp.
     */
    event BurnToken(
        uint256 projectId, 
        uint256 tokenId, 
        address owner,
        uint256 timestamp
    );


    using Counters for Counters.Counter;
    // using SafeMathUpgradeable for uint256;

    bool private _initialized;

    Counters.Counter private _nextSlotId;

    uint256 internal _projectId;  //one derivativeNFT include one projectId
    uint256 internal _soulBoundTokenId;

    address internal _receiver;
    DataTypes.FeeShareType internal _feeShareType;

    address public immutable MANAGER;
    address internal _SBT;
    address internal _banktreasury;

    uint96 internal _royaltyBasisPoints; //版税佣金点数, 本协议将版税的10%及金库固定税收5%设置为

    //tokenId => publishId
    mapping(uint256 => uint256) internal _tokenIdByPublishId;

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

    //publication Name => Slot
    mapping(bytes32 => uint256) internal _publicationNameHashBySlot;

    //publishId => Slot
    mapping(uint256 => uint256) internal _publishIdBySlot;

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
        _banktreasury = bankTreasury;

        if (metadataDescriptor_ == address(0x0)) revert Errors.ZeroAddress();

         __ERC3525_init_unchained(name_, symbol_, 0);

        _setMetadataDescriptor(metadataDescriptor_);

        //default Unpaused
        _setState(DataTypes.DerivativeNFTState.Unpaused);

        _projectId = projectId_;
        _soulBoundTokenId = soulBoundTokenId_;
        _receiver = receiver_;

        _setDefaultRoyalty(_banktreasury, defaultRoyaltyPoints_);

        _feeShareType = feeShareType_;

    }

    //only manager
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

    function getPublishIdByTokenId(uint256 tokenId) external view returns (uint256) {
        return _tokenIdByPublishId[tokenId];
    }

    // Publication only can publish once
    function publish(
        uint256 publishId,
        DataTypes.Publication memory publication,
        address publisher
    ) external whenNotPaused onlyManager returns (uint256) { 
        
        if (_publicationNameHashBySlot[keccak256(bytes(publication.name))] > 0) revert Errors.PublicationIsExisted();
        if (publication.soulBoundTokenId != _soulBoundTokenId && publication.fromTokenIds.length == 0) revert Errors.InvalidParameter();
        if (publication.projectId != _projectId) {
            revert Errors.InvalidParameter();
        }
        
        for (uint256 i = 0; i < publication.fromTokenIds.length; ++i) {

            //must approve this contract address or setApprovalForAll
            this.transferFrom(publication.fromTokenIds[i], _receiver, 1);
        }

        uint256 slot = _generateNextSlotId(); //auto increase

        _slotDetails[slot] = DataTypes.SlotDetail({
            publication: publication,
            imageURI:  "",
            timestamp: block.timestamp 
        });

        _publicationNameHashBySlot[keccak256(bytes(publication.name))] = slot;
        _publishIdBySlot[publishId] = slot;
        
        uint256 newTokenId = ERC3525Upgradeable._createOriginalTokenId();
        _tokenIdByPublishId[newTokenId] = publishId;

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
      
        _tokenIdByPublishId[newTokenId] = publishId_;
        _mint(to_, newTokenId, ERC3525Upgradeable.slotOf(fromTokenId_), 0);

        ERC3525Upgradeable._transferValue(fromTokenId_, newTokenId, value_);

        return newTokenId;
    }

    function setTokenImageURI(uint256 tokenId, string calldata imageURI)
        external
        whenNotPaused
    { 
        _setTokenImageURI(tokenId, imageURI);
    }

    function burn(uint256 tokenId_) external virtual whenNotPaused {
        uint256 slot = slotOf(tokenId_);
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) {
            revert Errors.NotAllowed();
        }
        ERC3525Upgradeable._burn(tokenId_);
        _resetTokenRoyalty(tokenId_);
        emit BurnToken(slot, tokenId_, msg.sender, block.timestamp);
    }

    function getSlotDetail(uint256 slot_) external view returns (DataTypes.SlotDetail memory) {
        return _slotDetails[slot_];
    }

    function getSlot(uint256 publishId) external view returns (uint256) {
        return _publishIdBySlot[publishId];
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
    ) public payable virtual override whenNotPaused returns (uint256) {

        uint256 newTokenId = super.transferFrom(fromTokenId_, to_, value_);
      
        //set royalty
        uint256 publishId = _tokenIdByPublishId[fromTokenId_];
        _tokenIdByPublishId[newTokenId] = publishId;

        uint96 _fraction;
        if (_feeShareType == DataTypes.FeeShareType.LEVEL_TWO) {
            _fraction = IManager(MANAGER).calculateRoyalty(publishId);
        } else {
             _fraction = _royaltyBasisPoints;
        }

        //set royaltiespa
        _setTokenRoyalty(
            newTokenId,
            _banktreasury,
            _fraction
        );

       return newTokenId;
    }

    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override whenNotPaused  {
      super.transferFrom(fromTokenId_, toTokenId_, value_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override whenNotPaused {
        super.transferFrom(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override whenNotPaused {
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override  whenNotPaused {
       super.safeTransferFrom(from_, to_, tokenId_, "");
    }

    function _mint(address to_, uint256 tokenId_, uint256 slot_, uint256 value_) internal virtual override {
        super._mint(to_, tokenId_, slot_, value_);

        uint256 publishId = _tokenIdByPublishId[tokenId_];
        uint96 _fraction;
        if (_feeShareType == DataTypes.FeeShareType.LEVEL_TWO) {
            _fraction = IManager(MANAGER).calculateRoyalty(publishId);
        } else {
             _fraction = _royaltyBasisPoints;
        }

        //set royalties
        _setTokenRoyalty(
            tokenId_,
            _banktreasury,
            _fraction
        );
    }

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
        //TODO event RoyaltySet
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

        //TODO event DefaultRoyaltySet
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

    function _generateNextSlotId() internal returns (uint256) {
        _nextSlotId.increment();
        return uint24(_nextSlotId.current());
    }

    function _setTokenImageURI(uint256 tokenId, string calldata imageURI) internal {
        if (bytes(imageURI).length > Constants.MAX_PROFILE_IMAGE_URI_LENGTH)
            revert Errors.ProfileImageURILengthInvalid(); 

        address owner = ERC3525Upgradeable.ownerOf(tokenId);

        if (_msgSender() != owner) {
            revert Errors.NotOwner();
        }

        DataTypes.SlotDetail storage detail = _slotDetails[tokenId];
        detail.imageURI = imageURI;

        emit DerivativeNFTImageURISet(tokenId, imageURI, block.timestamp);
    }



}