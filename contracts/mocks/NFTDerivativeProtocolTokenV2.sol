// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {Errors} from "../libraries/Errors.sol";
import '../libraries/Constants.sol';
import {IManager} from "../interfaces/IManager.sol";
import {ERC3525Votes} from "../extensions/ERC3525Votes.sol";
import "../storage/SBTStorage.sol";
import {INFTDerivativeProtocolTokenV2} from "../interfaces/INFTDerivativeProtocolTokenV2.sol";

/**
 *  @title dNFT Derivative Protocol Token
 */
contract NFTDerivativeProtocolTokenV2 is
    Initializable,
    AccessControlUpgradeable,
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

    uint256 private treasury_SBT_ID;

    //New variables should be placed after all existing inherited variables
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

    // V2
    function setBankTreasury(address bankTreasury, uint256 amount) 
        external  
    {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) 
            revert Errors.Unauthorized();
        
        if (bankTreasury == address(0)) 
            revert Errors.InvalidParameter();
        
        if (amount == 0) 
            revert Errors.InvalidParameter();
        
        if (_banktreasury == address(0)) {
            _banktreasury = bankTreasury;
        }
        
        total_supply += amount * 1e18;

        if (total_supply > MAX_SUPPLY) 
            revert Errors.MaxSupplyExceeded();
        
        uint256  slot = 1;

        if (treasury_SBT_ID == 0) {
            //create profile for bankTreasury, slot is 1, not vote power
            treasury_SBT_ID = 1;
            
            uint256 _sbtId = ERC3525Upgradeable._mint(_banktreasury, slot, amount * 1e18);
            
            if (_sbtId != treasury_SBT_ID) revert Errors.SetBankTreasuryError();
        
        
        } else {
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
        if (balanceOf(vars.wallet) > 0) revert Errors.TokenIsClaimed(); 
        
        uint256 tokenId_ = _mint(vars.wallet, 1, 0);

        ERC3525Upgradeable._setApprovalForAll(vars.wallet, voucher, true);
        ERC3525Upgradeable._setApprovalForAll(vars.wallet, _banktreasury, true);
       
        _createProfile(
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

        uint256 balance = balanceOf(soulBoundTokenId);

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
        uint256 tokenId_,
        string memory nickName,
        string memory imageURI
    ) internal {
        if (tokenId_ == 0) revert Errors.TokenIdIsZero();
        
        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: nickName,
            imageURI: imageURI,
            locked: true
        });

         emit ProfileCreated(
            tokenId_,
            _msgSender(),
            _banktreasury,    
            nickName,
            imageURI
        );
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