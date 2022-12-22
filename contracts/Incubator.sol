// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {IIncubator} from "./interfaces/IIncubator.sol";
import {DataTypes} from './libraries/DataTypes.sol';

/**
 * @title Incubator
 * @author Bitsoul Protocol
 * 
 * @notice This is the contract that is minted upon collecting a given publication of dNFT. 
 *         It is cloned upon the first collect for a given publication of dNFT.
 *         Incubator can receive standard ERC20 and ERC3525 Token
 */
contract Incubator is IIncubator, IERC165, IERC3525Receiver, AccessControl 
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // solhint-disable-next-line const-name-snakecase
    string internal constant _name = "Incubator";

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;

    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }

    bool private _initialized;

    uint256 internal _soulBoundTokenId;

    // solhint-disable-next-line var-name-mixedcase
    address private immutable _MANAGER;
    // solhint-disable-next-line var-name-mixedcase
    address private immutable _NDPT;

    constructor(
        address manager,
        address ndpt
    ) {
        if (manager == address(0)) revert Errors.InitParamsInvalid();
        if (ndpt == address(0)) revert Errors.InitParamsInvalid();

        _MANAGER = manager;
        _NDPT = ndpt;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function initialize(uint256 soulBoundTokenId) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        _soulBoundTokenId = soulBoundTokenId;
         
        emit Events.IncubatorInitialized(_soulBoundTokenId, block.timestamp);
    }

    function name() external pure returns(string memory) {
        return _name;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId || 
            interfaceId == type(AccessControl).interfaceId || 
            interfaceId == type(IERC3525Receiver).interfaceId;
    } 

    function onERC3525Received(
        address operator, 
        uint256 fromTokenId, 
        uint256 toTokenId, 
        uint256 value, 
        bytes calldata data
    ) public override returns (bytes4) {
        emit Events.IncubatorReceived(operator, fromTokenId, toTokenId, value, data, gasleft());
        return 0x009ce20b;
    }
 
     //TODO
     // split
     // publish
    //TODO withdraw deposit royalties

    
}