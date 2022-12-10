// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525SlotEnumerableUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {INFTDerivativeProtocolTokenV1} from "./interfaces/INFTDerivativeProtocolTokenV1.sol";

/**
 *  @title NFT Derivative Protocol Token
 * 
 * 
 * , and includes built-in governance power and delegation mechanisms.
 */
contract NFTDerivativeProtocolTokenV1 is INFTDerivativeProtocolTokenV1, ERC3525SlotEnumerableUpgradeable {
    using SafeMathUpgradeable for uint256;

    bool private _initialized;
    
    // solhint-disable-next-line var-name-mixedcase
    address internal _MANAGER;

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;

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
    constructor() initializer {}

    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address manager
    ) external override initializer {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;

        __ERC3525_init_unchained(name, symbol, decimals);
        _MANAGER = manager;
    }

    function mint(address mintTo, uint256 tokenId, uint256 slot, uint256 value) external payable onlyManager {
        ERC3525Upgradeable._mint(mintTo, tokenId, slot, value);
    }

    function mintValue(uint256 tokenId, uint256 value) external payable onlyManager {
        ERC3525Upgradeable._mintValue(tokenId, value);
    }

    function burn(uint256 tokenId) external onlyManager{
        ERC3525Upgradeable._burn(tokenId);
    }

    function burnValue(uint256 tokenId, uint256 value) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC3525: caller is not token owner nor approved");
        ERC3525Upgradeable._burnValue(tokenId, value);
    }

    //-----approval functions----//
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