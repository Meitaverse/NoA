// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525SlotEnumerableUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";

import "./storage/SBTStorage.sol";
import {INFTDerivativeProtocolTokenV1} from "./interfaces/INFTDerivativeProtocolTokenV1.sol";

/**
 *  @title NFT Derivative Protocol Token
 * 
 * 
 * , and includes built-in governance power and delegation mechanisms.
 */
contract NFTDerivativeProtocolTokenV1 is
    SBTStorage,
    INFTDerivativeProtocolTokenV1, 
    ERC3525SlotEnumerableUpgradeable 
{
    using SafeMathUpgradeable for uint256;

    bool private _initialized;
    
    // solhint-disable-next-line var-name-mixedcase
    address internal _MANAGER;

    // solhint-disable-next-line var-name-mixedcase
    address internal _BankTreasury;

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;
    
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
    // `initializer` marks the contract as initialized to prevent third parties to
    // call the `initialize` method on the implementation (this contract)
    constructor() initializer {}

    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address manager,
        address bankTreasury
    ) external override initializer {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;

        __ERC3525_init_unchained(name, symbol, decimals);
        _MANAGER = manager;
        _BankTreasury = bankTreasury;
    }

    function svgLogo() public view returns (string memory) {
        return _svgLogo;
    }

    function setSvgLogo(string calldata svgLogo_) external onlyManager{
        _svgLogo = svgLogo_;
    }
 
    function createProfile(
        DataTypes.CreateProfileData calldata vars,
        string memory nickName
    ) external override onlyManager returns (uint256) {
        if (balanceOf(vars.to) > 0) revert Errors.TokenIsClaimed(); 

        uint256 tokenId_ = ERC3525Upgradeable._mint(vars.to, 1, 0);

        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: nickName,
            handle: vars.handle,
            locked: true,
            reputation: 0
        });

        return tokenId_;
    }

    function mint(uint256 tokenId, uint256 slot, uint256 value) external payable onlyManager {
        ERC3525Upgradeable._mint(_BankTreasury, tokenId, slot, value);
         emit Events.MintNDPT(tokenId, slot, value, block.timestamp);
    }

    function mintValue(uint256 tokenId, uint256 value) external payable onlyManager {
        ERC3525Upgradeable._mintValue(tokenId, value);
        emit Events.MintNDPTValue(tokenId, value, block.timestamp);

    }

    function burn(uint256 tokenId) external onlyManager{
        ERC3525Upgradeable._burn(tokenId);
         emit Events.BurnNDPT(tokenId, block.timestamp);
    }

    function burnValue(uint256 tokenId, uint256 value) external {
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

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _validateCallerIsManager() internal view {
        if (msg.sender != _MANAGER) revert Errors.NotManager();
    }

    uint256[50] private __gap;

}