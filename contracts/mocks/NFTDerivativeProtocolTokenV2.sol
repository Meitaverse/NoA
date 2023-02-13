// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {Errors} from "../libraries/Errors.sol";
import '../libraries/Constants.sol';
import {IManager} from "../interfaces/IManager.sol";
import {ERC3525Votes} from "../extensions/ERC3525Votes.sol";
import {SBTLogic} from '../libraries/SBTLogic.sol';
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
    UUPSUpgradeable
{
    //upgrade version
    uint256 internal constant VERSION = 2;
    uint256 public constant MAX_SUPPLY = 10000000000 * 1e18;
    bytes32 public constant TRANSFER_VALUE_ROLE = keccak256("TRANSFER_VALUE_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address internal SIGNER;

    /**
     * @dev Emitted when a profile is created.
     *
     * @param soulBoundTokenId The newly created profile's token ID.
     * @param creator The profile creator, who created the token with the given profile ID.
     * @param wallet The address receiving the profile with the given profile ID.
     * @param nickName The nickName set for the profile.
     * @param imageURI The image uri set for the profile.
     */
    event ProfileCreated(
        uint256 indexed soulBoundTokenId,
        address indexed creator,
        address indexed wallet,
        string nickName,
        string imageURI
    );

    event ProfileUpdated(
        uint256 indexed soulBoundTokenId,
        string nickName,
        string imageURI
    );

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
            address(this),
            address(0),
            tokenId_,     
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
        address voucher,
        DataTypes.CreateProfileData calldata vars
    ) 
        external 
        onlyManager  
        returns (uint256) 
    { 
        if (balanceOf(vars.wallet) > 0) revert Errors.TokenIsClaimed(); 
        
        uint256 tokenId_ = _mint(vars.wallet, 1, 0);
        
        SBTLogic.createProfile(
            address(this),
            voucher,
            tokenId_,  
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

        if (soulBoundTokenId == 0) revert Errors.TokenIdIsZero();
        
        _sbtDetails[soulBoundTokenId] = DataTypes.SoulBoundTokenDetail({
            nickName: nickName,
            imageURI: imageURI,
            locked: true
        });

        emit ProfileUpdated(
            soulBoundTokenId,
            nickName,
            imageURI
        );        
    }

    function getProfileDetail(uint256 soulBoundTokenId) external view returns (DataTypes.SoulBoundTokenDetail memory){
        return _sbtDetails[soulBoundTokenId];
    }

    function burn(uint256 soulBoundTokenId) 
        external 
        onlyManager
    { 
        SBTLogic.burnProcess(address(this), soulBoundTokenId, _sbtDetails);
        ERC3525Upgradeable._burn(soulBoundTokenId);
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
    //V2
    function setSigner(address signer) external {
        SIGNER = signer;
    }

    function getSigner() external view returns (address) {
        return SIGNER;
    }


}