// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";

import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import './libraries/Constants.sol';
import {SBTLogic} from './libraries/SBTLogic.sol';
import {IManager} from "./interfaces/IManager.sol";
import {ERC3525Votes} from "./extensions/ERC3525Votes.sol";
import "./storage/SBTStorage.sol";
import {INFTDerivativeProtocolTokenV1} from "./interfaces/INFTDerivativeProtocolTokenV1.sol";
// import "hardhat/console.sol";

/**
 *  @title NFT Derivative Protocol Token
 */
contract NFTDerivativeProtocolTokenV1 is
    Initializable,
    AccessControlUpgradeable,
    ERC3525Votes,
    SBTStorage,
    INFTDerivativeProtocolTokenV1, 
    UUPSUpgradeable
{
    uint256 internal constant VERSION = 1;
    uint256 public constant MAX_SUPPLY = 10000000000 * 1e18;
    bytes32 public constant TRANSFER_VALUE_ROLE = keccak256("TRANSFER_VALUE_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    //===== Modifiers =====//

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyManager() {
        _validateCallerIsManager();
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
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        address manager,
        address metadataDescriptor_
    ) external override initializer {

        __ERC3525_init_unchained(name, symbol, decimals);
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());

        if (manager == address(0)) revert Errors.InitParamsInvalid();
        _setManager(manager);

        if (metadataDescriptor_ == address(0x0)) revert Errors.ZeroAddress();
        _setMetadataDescriptor(metadataDescriptor_);

    }

    function setBankTreasury(address bankTreasury, uint256 initialSupply) 
        external  
    {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert Errors.Unauthorized();
        
        if (bankTreasury == address(0)) revert Errors.InvalidParameter();
        if (initialSupply == 0) revert Errors.InvalidParameter();
        if (_banktreasury != address(0)) revert Errors.InitialIsAlreadyDone();
        _banktreasury = bankTreasury;
        
        total_supply += initialSupply * 1e18;
        if (total_supply > MAX_SUPPLY) revert Errors.MaxSupplyExceeded();

        //create profile for bankTreasury, tokenId is 1, not vote power
        uint256 tokenId_ = ERC3525Upgradeable._mint(_banktreasury, 1, initialSupply * 1e18);

        SBTLogic.createProfile(
            tokenId_,
            _msgSender(),
            _banktreasury,    
            "Bank Treasury",
            "",
            _sbtDetails
        );
    }
    
    function version() external pure returns(uint256) {
        return VERSION;
    }

    function createProfile(
        address creator,
        DataTypes.CreateProfileData calldata vars
    ) 
        external 
        onlyManager  
        returns (uint256) 
    { 
        if (balanceOf(vars.wallet) > 0) revert Errors.TokenIsClaimed(); 
        
        uint256 tokenId_ = _mint(vars.wallet, 1, 0);
        
        SBTLogic.createProfile(
            tokenId_,
            creator,
            vars.wallet,    
            vars.nickName,
            vars.imageURI,
            _sbtDetails
        );

        return tokenId_;
    }

    function updateProfile(
        uint256 soulBoundTokenId,
        string calldata nickName,
        string calldata imageURI
    ) 
        external 
    { 
        if (msg.sender != ownerOf(soulBoundTokenId)) 
            revert Errors.NotOwner();

        SBTLogic.updateProfile(
            soulBoundTokenId,   
            nickName,
            imageURI,
            _sbtDetails
        );
    }

    function getProfileDetail(uint256 soulBoundTokenId) external view returns (DataTypes.SoulBoundTokenDetail memory){
        return _sbtDetails[soulBoundTokenId];
    }

/*
    function mintValue(
        uint256 soulBoundTokenId, 
        uint256 value
    ) 
        external 
        payable 
        onlyManager 
    { 
        if (value == 0) revert Errors.InvalidParameter();

        total_supply += value;
        if (total_supply > MAX_SUPPLY) revert Errors.MaxSupplyExceeded();

        _mintValue(soulBoundTokenId, value);
        emit Events.MintSBTValue(msg.sender, soulBoundTokenId, value, block.timestamp);
    }
    */

    function burn(uint256 soulBoundTokenId) 
        external 
        onlyManager
    { 
        uint256 balance = ERC3525Upgradeable.balanceOf(soulBoundTokenId);
        if (balance > 0 ) {
            ERC3525Upgradeable._transferValue(soulBoundTokenId, BANK_TREASURY_SOUL_BOUND_TOKENID, balance);
        }
        ERC3525Upgradeable._burn(soulBoundTokenId);
        SBTLogic.burnProcess(msg.sender, balance, soulBoundTokenId, _sbtDetails);
    }

    function transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) external  { 
        //call only by BankTreasury, FeeCollectModule, publishModule, Voucher Or MarketPlace
        if (!hasRole(TRANSFER_VALUE_ROLE, _msgSender())) revert Errors.NotTransferValueAuthorised();
        ERC3525Upgradeable._transferValue(fromTokenId_, toTokenId_, value_);
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
        override
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
        override 
        isTransferAllowed(tokenId_) 
    {
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC3525Upgradeable) returns (bool) {
        return
            interfaceId == type(AccessControlUpgradeable).interfaceId || 
            super.supportsInterface(interfaceId);
    } 

    
    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _setManager(address manager) internal {
        _manager = manager;
    }   

    function _validateCallerIsManager() internal view {
        if (msg.sender != _manager) revert Errors.NotManager();
    }

    //-- orverride -- //
    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        if (!hasRole(UPGRADER_ROLE, _msgSender())) revert Errors.Unauthorized();
    }
   
}