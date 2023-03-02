// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";

import {Errors} from "./libraries/Errors.sol";
import './libraries/Constants.sol';
import {ERC3525Votes} from "./extensions/ERC3525Votes.sol";
import "./storage/SBTStorage.sol";
import {INFTDerivativeProtocolTokenV1} from "./interfaces/INFTDerivativeProtocolTokenV1.sol";
// import "hardhat/console.sol";

/**
 *  @title dNFT Derivative Protocol Token
 * 
 * includes built-in governance power and delegation mechanisms.
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
    uint256 internal constant MAX_SUPPLY = 10000000000 * 1e18;
    bytes32 public constant TRANSFER_VALUE_ROLE = keccak256("TRANSFER_VALUE_ROLE");
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 private treasury_SBT_ID;

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
    ) external initializer {

        __ERC3525_init_unchained(name, symbol, decimals);
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());

        if (manager == address(0x0) || metadataDescriptor_ == address(0x0)) 
            revert Errors.InitParamsInvalid();

        _setManager(manager);

        _setMetadataDescriptor(metadataDescriptor_);

    }

    function setBankTreasury(address bankTreasury, uint256 amount) 
        external  
    {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) 
            revert Errors.Unauthorized();
        
        total_supply += amount * 1e18;

        if (bankTreasury == address(0) || amount == 0 || total_supply > MAX_SUPPLY)
            revert Errors.InvalidParameter();
        
        _banktreasury = bankTreasury;
        

        if (treasury_SBT_ID == 0) {
            //create profile for bankTreasury, slot is 1, not vote power
            treasury_SBT_ID = 1;

            _createProfile(
                _banktreasury,
                treasury_SBT_ID,   
                "Bank Treasury",
                ""
            );
            
           ERC3525Upgradeable._mint(_banktreasury, 1, amount * 1e18);

        } else {
            //emit TransferValue
            ERC3525Upgradeable._mintValue(treasury_SBT_ID, amount * 1e18);
        }
    }
    
    function version() external pure returns(uint256) {
        return VERSION;
    }

    function createProfile(
        address voucher,
        DataTypes.CreateProfileData calldata vars
    ) 
        external 
        onlyManager  
        returns (uint256) 
    { 
        if (this.balanceOf(vars.wallet) > 0) revert Errors.TokenIsClaimed(); 
        
        uint256 tokenId_ = _mint(vars.wallet, 1, 0);

        ERC3525Upgradeable._setApprovalForAll(vars.wallet, voucher, true);
        ERC3525Upgradeable._setApprovalForAll(vars.wallet, _banktreasury, true);
       
        _createProfile(
            vars.wallet,
            tokenId_,
            vars.nickName,
            vars.imageURI
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
    { 
        if (msg.sender != ownerOf(soulBoundTokenId)) 
            revert Errors.NotOwner();

        uint256 balance = this.balanceOf(soulBoundTokenId);

        if (balance > 0 ) {
            this.transferValue(soulBoundTokenId, BANK_TREASURY_SOUL_BOUND_TOKENID, balance);
        }
        
        delete _sbtDetails[soulBoundTokenId];

        ERC3525Upgradeable._burn(soulBoundTokenId);
    }

    function transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) external  { 
        //call only by BankTreasury, FeeCollectModule, publishModule, Voucher Or MarketPlace
        if (!hasRole(TRANSFER_VALUE_ROLE, _msgSender())) 
            revert Errors.NotTransferValueAuthorised();
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

    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override isTransferAllowed(fromTokenId_) returns (uint256) {
        return super.transferFrom(fromTokenId_, to_, value_);
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

    function _createProfile(
        address wallet_,
        uint256 tokenId_,
        string memory nickName,
        string memory imageURI
    ) internal {
        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: nickName,
            imageURI: imageURI,
            locked: true
        });

         emit ProfileCreated(
            tokenId_,
            tx.origin,
            wallet_,    
            nickName,
            imageURI
        );
    }

    //-- orverride -- //
    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        if (!hasRole(UPGRADER_ROLE, _msgSender())) revert Errors.Unauthorized();
    }
   
}