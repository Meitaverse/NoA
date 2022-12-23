// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525SlotEnumerableUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {Constants} from './libraries/Constants.sol';
import "./storage/SBTStorage.sol";
import {INFTDerivativeProtocolTokenV1} from "./interfaces/INFTDerivativeProtocolTokenV1.sol";

/**
 *  @title NFT Derivative Protocol Token
 * 
 */
contract NFTDerivativeProtocolTokenV1 is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    SBTStorage,
    INFTDerivativeProtocolTokenV1, 
    ERC3525SlotEnumerableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;
    
    uint256 internal constant VERSION = 1;
    
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
        address manager,
        address bankTreasury
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

        if (bankTreasury == address(0)) revert Errors.InitParamsInvalid();
        _BANKTREASURY = bankTreasury;

        //create profile for bankTreasury
        uint256 tokenId_ = ERC3525Upgradeable._mint(_BANKTREASURY, 1, 1000);

        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: "Bank Treasury",
            handle: "bankTreasury",
            locked: true,
            reputation: 0
        });
        emit Events.BankTreasuryCreated(tokenId_, block.timestamp);
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
 
    function createProfile(
        DataTypes.CreateProfileData calldata vars
    ) external override whenNotPaused onlyManager returns (uint256) {
        _validateHandle(vars.handle);

        if (balanceOf(vars.to) > 0) revert Errors.TokenIsClaimed(); 
        
        //value must at least 1, can't equal 0 
        uint256 tokenId_ = ERC3525Upgradeable._mint(vars.to, 1, 0);

        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: vars.nickName,
            handle: vars.handle,
            locked: true,
            reputation: 0
        });

        return tokenId_;
    }

    function mint(
        address mintTo, 
        uint256 slot, 
        uint256 value
    ) external payable whenNotPaused onlyManager returns(uint256 tokenId){
        tokenId =  ERC3525Upgradeable._mint(mintTo, slot, value);
        emit Events.MintNDPT(mintTo, slot, value, block.timestamp);
        return tokenId;
    }
    

    function mintValue(
        uint256 tokenId, 
        uint256 value
    ) external payable whenNotPaused onlyManager {
        ERC3525Upgradeable._mintValue(tokenId, value);
        emit Events.MintNDPTValue(tokenId, value, block.timestamp);

    }

    function burn(uint256 tokenId) external whenNotPaused onlyManager{
        ERC3525Upgradeable._burn(tokenId);
         emit Events.BurnNDPT(tokenId, block.timestamp);
    }

    function burnValue(uint256 tokenId, uint256 value) external whenNotPaused onlyManager {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC3525: caller is not token owner nor approved");
        ERC3525Upgradeable._burnValue(tokenId, value);
        emit Events.BurnNDPTValue(tokenId, value, block.timestamp);
    }

    //-----approval functions----//
    // function setApprovalForAll(
    //     address operator_, 
    //     bool approved_
    // ) public virtual override(ERC3525Upgradeable,IERC721Upgradeable) onlyManager{
    //     super._setApprovalForAll(_msgSender(), operator_, approved_);
    // }

    //-- orverride -- //
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override(ERC3525Upgradeable, IERC721Upgradeable) isTransferAllowed(tokenId_) {
        super.transferFrom(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override(ERC3525Upgradeable, IERC721Upgradeable) isTransferAllowed(tokenId_) {
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    function setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) external payable virtual {
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

    function _validateCallerIsManager() internal view {
        if (msg.sender != _MANAGER) revert Errors.NotManager();
    }

    //-- orverride -- //
    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        if (!hasRole(UPGRADER_ROLE, _msgSender())) revert Errors.Unauthorized();
    }

    //V1
    function getManager() external view returns(address) {
        return _MANAGER;
    }
    
    function getBankTreasury() external view returns(address) {
        return _BANKTREASURY;
    }

    function _validateHandle(string calldata handle) private pure {
        bytes memory byteHandle = bytes(handle);
        if (byteHandle.length == 0 || byteHandle.length > Constants.MAX_HANDLE_LENGTH)
            revert Errors.HandleLengthInvalid();

        uint256 byteHandleLength = byteHandle.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            if (
                (byteHandle[i] < '0' ||
                    byteHandle[i] > 'z' ||
                    (byteHandle[i] > '9' && byteHandle[i] < 'a')) &&
                byteHandle[i] != '.' &&
                byteHandle[i] != '-' &&
                byteHandle[i] != '_'
            ) revert Errors.HandleContainsInvalidCharacters();
            unchecked {
                ++i;
            }
        }
    }
}