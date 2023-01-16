// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@solvprotocol/erc-3525/contracts/ERC3525SlotEnumerableUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
// import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {Constants} from '../libraries/Constants.sol';
import {SBTLogic} from '../libraries/SBTLogic.sol';
import {IManager} from "../interfaces/IManager.sol";
import {ERC3525Votes} from "../extensions/ERC3525Votes.sol";
import "../storage/SBTStorage.sol";
import {INFTDerivativeProtocolTokenV2} from "../interfaces/INFTDerivativeProtocolTokenV2.sol";

/**
 *  @title NFT Derivative Protocol Token
 */
contract NFTDerivativeProtocolTokenV2 is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC3525Votes,
    SBTStorage,
    INFTDerivativeProtocolTokenV2,
    // ERC3525SlotEnumerableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    uint256 internal constant VERSION = 2;
    uint256 public constant MAX_SUPPLY = 100000000 * 1e18;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address internal SIGNER;

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
    
    function version() external pure returns(uint256) {
        return VERSION;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function whitelistContract(address contract_, bool toWhitelist_) external  { 
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert Errors.Unauthorized();
        _whitelistContract(contract_, toWhitelist_);
    }

     function _whitelistContract(address contract_, bool toWhitelist_) internal {

        SBTLogic.contractWhitelistedSet(
            contract_,
            toWhitelist_,
            _contractWhitelisted
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
        emit Events.MintSBTValue(msg.sender, soulBoundTokenId, value, block.timestamp);
    }


    function burn(uint256 soulBoundTokenId) 
        external 
        whenNotPaused 
        onlyManager
    { 
        uint256 balance = ERC3525Upgradeable.balanceOf(soulBoundTokenId);
        if (balance > 0 ) {
            ERC3525Upgradeable._transferValue(soulBoundTokenId, Constants._BANK_TREASURY_SOUL_BOUND_TOKENID, balance);
        }
        ERC3525Upgradeable._burn(soulBoundTokenId);
        emit Events.BurnSBT(msg.sender, soulBoundTokenId, balance, block.timestamp);
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

        SBTLogic.createProfile(
            tokenId_,
            _msgSender(),
            _banktreasury,    
            "Bank Treasury",
            "",
            _sbtDetails
        );


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
   

    //V2
    function setSigner(address signer) external {
        SIGNER = signer;
    }

    function getSigner() external view returns (address) {
        return SIGNER;
    }


}