// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525SlotEnumerableUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {Constants} from './libraries/Constants.sol';
import {IManager} from "./interfaces/IManager.sol";
import "./storage/SBTStorage.sol";
import {INFTDerivativeProtocolTokenV1} from "./interfaces/INFTDerivativeProtocolTokenV1.sol";

/**
 *  @title NFT Derivative Protocol Token
 */
contract NFTDerivativeProtocolTokenV1 is
    Initializable,
    ReentrancyGuard,
    AccessControlUpgradeable,
    PausableUpgradeable,
    SBTStorage,
    INFTDerivativeProtocolTokenV1, 
    ERC3525SlotEnumerableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    uint256 internal constant VERSION = 1;
    uint256 public constant MAX_SUPPLY = 100000000 * 1e18;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    //===== Modifiers =====//

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyManager() {
        _validateCallerIsManager();
        _;
    }
    
    modifier onlyBankTreasury() {
        _validateCallerIsBankTreasury();
        _;
    }

    modifier isTransferAllowed(uint256 tokenId_) {
        if(_sbtDetails[tokenId_].locked) revert Errors.Locked(); 
        _;
    }

    //===== Initializer =====//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address manager
    ) external override initializer {

        __ERC3525_init_unchained(name, symbol, decimals);
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());

        if (manager == address(0)) revert Errors.InitParamsInvalid();
        _MANAGER = manager;

    }
    
    function version() external pure returns(uint256) {
        return VERSION;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function svgLogo() public view returns (string memory) {
        return _svgLogo;
    }

    function setSvgLogo(string calldata svgLogo_) external whenNotPaused onlyManager{
        _svgLogo = svgLogo_;
    }
 
    function isContractWhitelisted(address contract_) external view override returns (bool) {
        return _contractWhitelisted[contract_];
    }

    function whitelistContract(address contract_, bool toWhitelist_) external nonReentrant {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert Errors.Unauthorized();
        _whitelistContract(contract_, toWhitelist_);
    }

     function _whitelistContract(address contract_, bool toWhitelist_) internal {
        if (contract_ == address(0)) revert Errors.InitParamsInvalid();
        bool prevWhitelisted = _contractWhitelisted[contract_];
        _contractWhitelisted[contract_] = toWhitelist_;
        emit Events.SetContractWhitelisted(
            contract_,
            prevWhitelisted,
            toWhitelist_,
            block.timestamp
        ); 
    }

    function createProfile(
        address creator,
        DataTypes.CreateProfileData calldata vars
    ) external nonReentrant whenNotPaused onlyManager returns (uint256) {
        _validateNickName(vars.nickName);

        if (balanceOf(vars.wallet) > 0) revert Errors.TokenIsClaimed(); 
        
        uint256 tokenId_ = ERC3525Upgradeable._mint(vars.wallet, 1, 0);

        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: vars.nickName,
            imageURI: vars.imageURI,
            locked: true
        });

        _walletToSBTId[creator] = tokenId_;

        emit Events.ProfileCreated(
            tokenId_,
            creator,
            vars.wallet,    
            vars.nickName,
            vars.imageURI,
            block.timestamp
        );

        return tokenId_;
    }

    function mintValue(
        uint256 soulBoundTokenId, 
        uint256 value
    ) external payable whenNotPaused nonReentrant onlyManager {
        if (value == 0) revert Errors.InvalidParameter();

        total_supply += value;
        if (total_supply > MAX_SUPPLY) revert Errors.MaxSupplyExceeded();

        ERC3525Upgradeable._mintValue(soulBoundTokenId, value);
        emit Events.MintSBTValue(soulBoundTokenId, value, block.timestamp);
    }

    function burn(uint256 tokenId) external whenNotPaused nonReentrant onlyManager{
        ERC3525Upgradeable._burn(tokenId);
        emit Events.BurnSBT(tokenId, block.timestamp);
    }

    function burnValue(uint256 tokenId, uint256 value) external whenNotPaused nonReentrant onlyManager {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC3525: caller is not token owner nor approved");
        ERC3525Upgradeable._burnValue(tokenId, value);
        emit Events.BurnSBTValue(tokenId, value, block.timestamp);
    }

    //-----approval functions----//
    // function setApprovalForAll(
    //     address operator_, 
    //     bool approved_
    // ) public virtual override(ERC3525Upgradeable,IERC721Upgradeable) onlyManager{
    //     super.setApprovalForAll(operator_, approved_);
    // }


    function transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) external nonReentrant {
         //call only by BankTreasury or FeeCollectModule or publishModule  or Voucher
        if (_contractWhitelisted[msg.sender]) {
            ERC3525Upgradeable._transferValue(fromTokenId_, toTokenId_, value_);
            return;
        }
        revert Errors.NotTransferValueAuthorised();
    }

    //-- orverride -- //
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) 
        public 
        payable 
        virtual 
        nonReentrant
        whenNotPaused
        override(ERC3525Upgradeable, IERC721Upgradeable) 
        isTransferAllowed(tokenId_)  //Soul bound token can not transfer
    {
        super.transferFrom(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) 
        public 
        payable 
        virtual 
        nonReentrant
        whenNotPaused 
        override(ERC3525Upgradeable, IERC721Upgradeable) 
        isTransferAllowed(tokenId_) 
    {
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    function setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) 
        external 
        payable 
        virtual 
        nonReentrant
        whenNotPaused         
    {
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC3525SlotEnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
        return
            interfaceId == type(AccessControlUpgradeable).interfaceId || 
            super.supportsInterface(interfaceId);
    } 

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _validateCallerIsSoulBoundTokenOwnerOrDispathcher(uint256 soulBoundTokenId_) internal view {

        if (ownerOf(soulBoundTokenId_) == msg.sender || 
            IManager(_MANAGER).getDispatcher(soulBoundTokenId_) == msg.sender) {
            return;
        }

        revert Errors.NotProfileOwnerOrDispatcher();
    }

    function _validateCallerIsManager() internal view {
        if (msg.sender != _MANAGER) revert Errors.NotManager();
    }

    function _validateCallerIsBankTreasury() internal view {
        if (msg.sender != _BANKTREASURY) revert Errors.NotBankTreasury();
    }

    //-- orverride -- //
    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        if (!hasRole(UPGRADER_ROLE, _msgSender())) revert Errors.Unauthorized();
    }

    //V1
    function getManager() external view returns(address) {
        return _MANAGER;
    }
    
    function setBankTreasury(address bankTreasury, uint256 initialSupply) 
        external  
        nonReentrant
        whenNotPaused 
    {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert Errors.Unauthorized();
        
        if (bankTreasury == address(0)) revert Errors.InvalidParameter();
        if (initialSupply == 0) revert Errors.InvalidParameter();
        if (_BANKTREASURY != address(0)) revert Errors.InitialIsAlreadyDone();
        _BANKTREASURY = bankTreasury;
        
        total_supply += initialSupply;
        if (total_supply > MAX_SUPPLY) revert Errors.MaxSupplyExceeded();

        //create profile for bankTreasury, tokenId is 1
        uint256 tokenId_ = ERC3525Upgradeable._mint(_BANKTREASURY, 1, initialSupply);
        ERC3525Upgradeable.setApprovalForAll(_BANKTREASURY, true);

        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: "Bank Treasury",
            imageURI: "",
            locked: true
        });

        emit Events.ProfileCreated(
            tokenId_,
            _msgSender(),
            _BANKTREASURY,    
            "bank treasury",
            "",
            block.timestamp
        );

        emit Events.BankTreasurySet(
            tokenId_, 
            bankTreasury,
            initialSupply,
            block.timestamp);
    }
    
    function getBankTreasury() external view returns(address) {
        return _BANKTREASURY;
    }

    function getSBTIdByWallet(address wallet) external view returns(uint256) {
        return _walletToSBTId[wallet];
    }
    
    function setProfileImageURI(uint256 soulBoundTokenId, string calldata imageURI)
        external
        override
        nonReentrant
        whenNotPaused 
    { 
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(soulBoundTokenId);

        _setProfileImageURI(soulBoundTokenId, imageURI);
    }

    function _setProfileImageURI(uint256 soulBoundTokenId, string calldata imageURI) internal {
        if (bytes(imageURI).length > Constants.MAX_PROFILE_IMAGE_URI_LENGTH)
            revert Errors.ProfileImageURILengthInvalid(); 

        DataTypes.SoulBoundTokenDetail storage detail = _sbtDetails[soulBoundTokenId];
        detail.imageURI = imageURI;

        emit Events.ProfileImageURISet(soulBoundTokenId, imageURI, block.timestamp);
    }

    function _validateNickName(string calldata nickName) private pure {
        bytes memory byteNickName = bytes(nickName);
        if (byteNickName.length == 0 || byteNickName.length > Constants.MAX_NICKNAME_LENGTH)
            revert Errors.NickNameLengthInvalid();
    }

}