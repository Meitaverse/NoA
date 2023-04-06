// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {Errors} from "./libraries/Errors.sol";
import {DataTypes} from './libraries/DataTypes.sol';
import {IManager} from "./interfaces/IManager.sol";
import {IDerivativeNFT} from "./interfaces/IDerivativeNFT.sol";
import './libraries/Constants.sol';
import "./base/DerivativeNFTMultiState.sol";
// import "hardhat/console.sol";

/**
 *  @title Derivative NFT
 * 
 */
contract DerivativeNFT is 
    IDerivativeNFT, 
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

    event DefaultRoyaltiesUpdated(
        uint256  projectId,
        address  receiver, 
        uint16  basisPoint
    );

    event RoyaltiesUpdated(
        uint256 indexed publishId, 
        uint256 indexed tokenId, 
        address indexed receiver, 
        uint16  basisPoint
    );
    
    // Royalty configurations
    struct RoyaltyConfig {
        address payable receiver;
        uint16 bps;
    }

    using Counters for Counters.Counter;

    bool private _initialized;

    Counters.Counter private _nextSlotId;

    uint256 internal _projectId;  //one derivativeNFT include one projectId
    uint256 internal _soulBoundTokenId;
   
    address internal _receiver;

    address internal immutable MANAGER;

    address internal _SBT;
    address internal _banktreasury;
    address internal _marketPlace;
    uint256 internal _defaultRoyaltyBPS;

    //tokenId => publishId
    mapping(uint256 => uint256) internal _tokenIdByPublishId;

    mapping (uint256 => RoyaltyConfig[]) internal _tokenRoyalty;

    // bytes4(keccak256('royaltyInfo(uint256,uint256)')) == 0x2a55205a
    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

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
        if (manager == address(0)) revert Errors.InitParamsManagerInvalid();
        MANAGER = manager;
        _initialized = true;
    }

    function initialize(
        address sbt, 
        address bankTreasury,
        address marketPlace,
        string memory name_,
        string memory symbol_,
        uint256 projectId_,
        uint256 soulBoundTokenId_,
        address metadataDescriptor_,
        address receiver_,
        uint256 defaultRoyaltyBPS_
    ) public virtual initializer {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        
        if (sbt == address(0)) revert Errors.InitParamsSBTInvalid();
        _SBT = sbt;
        if (bankTreasury == address(0)) revert Errors.InitParamsTreasuryInvalid();
        _banktreasury = bankTreasury;
        if (marketPlace == address(0)) revert Errors.InitParamsMarketPlaceInvalid();
        _marketPlace = marketPlace;

        if (metadataDescriptor_ == address(0x0)) revert Errors.ZeroAddress();

         __ERC3525_init_unchained(name_, symbol_, 0);

        _setMetadataDescriptor(metadataDescriptor_);


        _projectId = projectId_;
        _soulBoundTokenId = soulBoundTokenId_;

        _receiver = receiver_;

        if (defaultRoyaltyBPS_ ==0 ) {
            //default Unpaused
            _setState(DataTypes.DerivativeNFTState.Unpaused);

        } else {
            //set paused
            _setState(DataTypes.DerivativeNFTState.Paused);
            _defaultRoyaltyBPS = defaultRoyaltyBPS_;
        }
    }
    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     *
     * @param tokenId The token ID of the derivativeNFT queried for royalty information.
     * @param value The sale price of the derivativeNFT specified.
     * @return A tuple with the address who should receive the royalties and the royalty
     * payment amount for the given sale price.
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256) {

        return _getRoyaltyInfo(tokenId, value);
    }

    function getRoyalties(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        return _getRoyalties(tokenId);
    }

    function getFeeRecipients(uint256 tokenId) external view virtual override returns (address payable[] memory) {
        return _getRoyaltyReceivers(tokenId);
    }

    function getFeeBps(uint256 tokenId) external view virtual override returns (uint[] memory) {
        return _getRoyaltyBPS(tokenId);
    }

    function getFees(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        return _getRoyalties(tokenId);
    }

    function getPublishIdByTokenId(uint256 tokenId) external view returns (uint256) {
        return _tokenIdByPublishId[tokenId];
    }

    function getCreator() external view returns(address) {
        return IERC3525(_SBT).ownerOf(_soulBoundTokenId);
    }

    function tokenCreator(uint256 tokenId) external view returns (address) {
        DataTypes.SlotDetail storage detail = _slotDetails[tokenId];

       uint256 soulBoundTokenIdOfCreator = detail.publication.soulBoundTokenId;
        
       return IManager(MANAGER).getWalletBySoulBoundTokenId(soulBoundTokenIdOfCreator);
    }

    /**
     * @notice Can only be called by manager
     */    
    function setMetadataDescriptor(
        address metadataDescriptor_
    ) 
        external 
        whenNotPaused 
        onlyManager 
    {
        _setMetadataDescriptor(metadataDescriptor_);
    }

    /**
     * @notice Can only be called by manager
     */    
    function setState(DataTypes.DerivativeNFTState newState) external override {
        if (msg.sender == MANAGER) {
             _setState(newState);
        } else {
            revert Errors.NotManager();
        } 
    }


    /**
     * @notice Publication only can publish once.
     * Can only be called by manager
     */ 
    function publish(
        uint256 publishId,
        DataTypes.Publication memory publication,
        address publisher,
        uint16 bps
    ) external whenPublishingEnabled onlyManager returns (uint256) { 
        
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

        if (_defaultRoyaltyBPS == 0) {
            //set royalty
            _setTokenRoyalty(
                newTokenId,
                _banktreasury,
                bps
            );

            emit RoyaltiesUpdated(
                publishId,
                newTokenId,
                _banktreasury,
                bps
            );
        }

        //valid materialURIs length
        if (publication.materialURIs.length > 0)
            _setTokenImageURI(newTokenId, publication.materialURIs[0]);
        
        return newTokenId;
    }

    /**
     * @notice Can only be called by manager
     */ 
    function split(
        uint256 publishId_, 
        uint256 fromTokenId_, 
        address to_,
        uint256 value_
    ) external whenPublishingEnabled returns(uint256) {
        //call only by manager or market place contract or owner
        if (!(MANAGER == msg.sender || 
                _marketPlace == msg.sender || 
                msg.sender == ERC3525Upgradeable.ownerOf(fromTokenId_)
            ))
            revert Errors.NotManagerNorMarketPlace();
        
        if (msg.sender == ERC3525Upgradeable.ownerOf(fromTokenId_)) {
            if (to_ != msg.sender) revert Errors.CanNotSplitToAnother();
        }

        uint256 newTokenId = ERC3525Upgradeable._createDerivedTokenId(fromTokenId_);
      
        _tokenIdByPublishId[newTokenId] = publishId_;
        _mint(to_, newTokenId, ERC3525Upgradeable.slotOf(fromTokenId_), 0);

        ERC3525Upgradeable._transferValue(fromTokenId_, newTokenId, value_);

        RoyaltyConfig[] storage royalties_from = _tokenRoyalty[fromTokenId_];

        if (_defaultRoyaltyBPS == 0) {
            //set royalty
            _setTokenRoyalty(
                newTokenId,
                _banktreasury,
                royalties_from[0].bps
            );
            emit RoyaltiesUpdated(
                publishId_,
                newTokenId,
                _banktreasury,
                royalties_from[0].bps
            );
        }
        return newTokenId;
    }

    function transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) external whenNotPaused whenPublishingEnabled {
        //call only by manager or market place contract or owner
        if (!(MANAGER == msg.sender || 
                _marketPlace == msg.sender || 
                msg.sender == ERC3525Upgradeable.ownerOf(fromTokenId_)
        )) {
            revert Errors.NotManagerNorMarketPlace();
        } 

        if (msg.sender == ERC3525Upgradeable.ownerOf(fromTokenId_)) 
        {
            if (ERC3525Upgradeable.ownerOf(toTokenId_) != msg.sender)
                revert Errors.CanNotTransferValueToAnother();
        }

        ERC3525Upgradeable._transferValue(fromTokenId_, toTokenId_, value_);
    }

    function setTokenImageURI(uint256 tokenId, string memory imageURI)
        external
        whenPublishingEnabled
        onlyManager
    { 
        _setTokenImageURI(tokenId, imageURI);
    }

    function burn(uint256 tokenId_) 
        external 
        virtual 
        whenNotPaused
    {
        if (!( msg.sender == ERC3525Upgradeable.ownerOf(tokenId_) || msg.sender == IERC3525(_SBT).ownerOf(_soulBoundTokenId) )) {
            revert Errors.NotManagerNorHubOwner();
        } 

        if (!_isApprovedOrOwner(msg.sender, tokenId_)) {
            revert Errors.NotAllowed();
        }

        ERC3525Upgradeable._burn(tokenId_);

        _resetTokenRoyalty(tokenId_);
    }

    function getSlotDetail(uint256 slot_) external view returns (DataTypes.SlotDetail memory) {
        return _slotDetails[slot_];
    }

    function getSlot(uint256 publishId) external view returns (uint256) {
        return _publishIdBySlot[publishId];
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

        RoyaltyConfig[] storage royalties_from = _tokenRoyalty[fromTokenId_];

        if (_defaultRoyaltyBPS == 0) {
            //set royalty
            _setTokenRoyalty(
                newTokenId,
                _banktreasury,
                royalties_from[0].bps
            );

            emit RoyaltiesUpdated(
                publishId,
                newTokenId,
                _banktreasury,
                royalties_from[0].bps
            );
        }

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
    ) public payable virtual override whenNotPaused {
       super.safeTransferFrom(from_, to_, tokenId_, "");
    }

    function updateDefaultRoyaltyBPS(uint16 defaultRoyaltyBPS_) external {
         if (msg.sender == IERC3525(_SBT).ownerOf(_soulBoundTokenId)) {
             _defaultRoyaltyBPS = defaultRoyaltyBPS_;
            emit DefaultRoyaltiesUpdated(
                _projectId,
                address(this),
                defaultRoyaltyBPS_
            );
        
        } else {
            revert Errors.NotHubOwner();
        } 
       
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` cannot be the zero .
     * - `receiver` cannot be the zero address.
     * - `basisPoints` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint16 basisPoints
    ) internal virtual {
        require(basisPoints <= uint16(BASIS_POINTS), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");
        RoyaltyConfig[] storage royalties = _tokenRoyalty[tokenId];
        royalties.push(
                RoyaltyConfig(
                    {
                        receiver: payable(receiver),
                        bps: uint16(basisPoints)
                    }
                )
            );
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyalty[tokenId];
    }

    function _validateCallerIsManager() internal view {
        if (msg.sender != MANAGER) revert Errors.NotManager();
    }

    function _generateNextSlotId() internal returns (uint256) {
        _nextSlotId.increment();
        return uint24(_nextSlotId.current());
    }

    function _setTokenImageURI(uint256 tokenId, string memory imageURI) internal {
        if (bytes(imageURI).length > MAX_PROFILE_IMAGE_URI_LENGTH)
            revert Errors.ProfileImageURILengthInvalid(); 

        address owner = ERC3525Upgradeable.ownerOf(tokenId);

        if (_msgSender() != owner) {
            revert Errors.NotOwner();
        }

        DataTypes.SlotDetail storage detail = _slotDetails[tokenId];
        detail.imageURI = imageURI;

        emit DerivativeNFTImageURISet(tokenId, imageURI, block.timestamp);
    }

    /**
     * Helper to get royalties for a token
     */
    function _getRoyalties(uint256 tokenId) view internal returns (address payable[] memory receivers, uint256[] memory bps) {
        if (_defaultRoyaltyBPS == 0) {
            // Get token level royalties
            RoyaltyConfig[] memory royalties = _tokenRoyalty[tokenId];
            
            if (royalties.length > 0) {
                receivers = new address payable[](royalties.length);
                bps = new uint256[](royalties.length);
                for (uint i; i < royalties.length;) {
                    receivers[i] = royalties[i].receiver;
                    bps[i] = royalties[i].bps;
                    unchecked { ++i; }
                }
            }

        } else {
            receivers = new address payable[](1);
            bps = new uint256[](1);
            receivers[0] = payable(address(this));
            bps[0] = _defaultRoyaltyBPS;
        }
    }

    /**
     * Helper to get royalty receivers for a token
     */
    function _getRoyaltyReceivers(uint256 tokenId) view internal returns (address payable[] memory recievers) {
        (recievers, ) = _getRoyalties(tokenId);
    }

    /**
     * Helper to get royalty basis points for a token
     */
    function _getRoyaltyBPS(uint256 tokenId) view internal returns (uint256[] memory bps) {
        (, bps) = _getRoyalties(tokenId);
    }

    function _getRoyaltyInfo(uint256 tokenId, uint256 value) view internal returns (address receiver, uint256 amount){
        if (_defaultRoyaltyBPS == 0) {

            (address payable[] memory receivers, uint256[] memory bps) = _getRoyalties(tokenId);
            require(receivers.length <= 1, "More than 1 royalty receiver");
            
            if (receivers.length == 0) {
                return (address(this), 0);
            }
            return (receivers[0], bps[0] * value / 10000);
        } else {
            return (address(this), _defaultRoyaltyBPS * value / 10000);
        }
    }


}