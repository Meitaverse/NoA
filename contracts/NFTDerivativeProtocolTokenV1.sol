// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";

import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {Constants} from './libraries/Constants.sol';
import {IManager} from "./interfaces/IManager.sol";
import {ERC3525Votes} from "./extensions/ERC3525Votes.sol";
import "./storage/SBTStorage.sol";
import {INFTDerivativeProtocolTokenV1} from "./interfaces/INFTDerivativeProtocolTokenV1.sol";

/**
 *  @title NFT Derivative Protocol Token
 */
contract NFTDerivativeProtocolTokenV1 is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC3525Votes,
    SBTStorage,
    INFTDerivativeProtocolTokenV1, 
    UUPSUpgradeable
{
    // using SafeMathUpgradeable for uint256;

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
        _setManager(manager);
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

    // function isContractWhitelisted(address contract_) external view override returns (bool) {
    //     return _contractWhitelisted[contract_];
    // }

    function whitelistContract(address contract_, bool toWhitelist_) external  { 
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
    ) 
        external 
        whenNotPaused
        onlyManager  
        returns (uint256) 
    { 

        if (balanceOf(vars.wallet) > 0) revert Errors.TokenIsClaimed(); 
        
        uint256 tokenId_ = _mint(vars.wallet, 1, 0);

        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: vars.nickName,
            imageURI: vars.imageURI,
            locked: true
        });

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
    ) 
        external 
        payable 
        whenNotPaused 
        onlyManager 
    { 
        if (value == 0) revert Errors.InvalidParameter();

        total_supply += value;
        if (total_supply > MAX_SUPPLY) revert Errors.MaxSupplyExceeded();

        _mintValue(soulBoundTokenId, value);
        emit Events.MintSBTValue(soulBoundTokenId, value, block.timestamp);
    }

    function burn(uint256 tokenId) 
        external 
        whenNotPaused 
        onlyManager
    { 
        ERC3525Upgradeable._burn(tokenId);
        emit Events.BurnSBT(tokenId, block.timestamp);
    }

    function transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) external  { 
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
        whenNotPaused
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
        whenNotPaused
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

    function setBankTreasury(address bankTreasury, uint256 initialSupply) 
        external  
        
        whenNotPaused
    {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert Errors.Unauthorized();
        
        if (bankTreasury == address(0)) revert Errors.InvalidParameter();
        if (initialSupply == 0) revert Errors.InvalidParameter();
        if (_banktreasury != address(0)) revert Errors.InitialIsAlreadyDone();
        _banktreasury = bankTreasury;
        
        total_supply += initialSupply;
        if (total_supply > MAX_SUPPLY) revert Errors.MaxSupplyExceeded();

        //create profile for bankTreasury, tokenId is 1, not vote power
        uint256 tokenId_ = ERC3525Upgradeable._mint(_banktreasury, 1, initialSupply);

        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: "Bank Treasury",
            imageURI: "",
            locked: true
        });

        emit Events.ProfileCreated(
            tokenId_,
            _msgSender(),
            _banktreasury,    
            "bank treasury",
            "",
            block.timestamp
        );

        // emit Events.BankTreasurySet(
        //     tokenId_, 
        //     bankTreasury,
        //     initialSupply,
        //     block.timestamp);
    }
    
    // function getBankTreasury() external view returns(address) {
    //     return _banktreasury;
    // }



    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _setManager(address manager) internal {
        _manager = manager;
    }   
        
    // function _validateCallerIsSoulBoundTokenOwnerOrDispathcher(uint256 soulBoundTokenId_) internal view {

    //     if (ownerOf(soulBoundTokenId_) == msg.sender || 
    //         IManager(_manager).getDispatcher(soulBoundTokenId_) == msg.sender) {
    //         return;
    //     }

    //     revert Errors.NotProfileOwnerOrDispatcher();
    // }

    function _validateCallerIsManager() internal view {
        if (msg.sender != _manager) revert Errors.NotManager();
    }

    //-- orverride -- //
    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        if (!hasRole(UPGRADER_ROLE, _msgSender())) revert Errors.Unauthorized();
    }
   

}