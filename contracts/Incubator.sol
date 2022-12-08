// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {IIncubator} from "./interfaces/IIncubator.sol";

/**
 * @title Incubator
 * @author Derivative NFT Protocol
 * 
 * @notice This is the contract that is minted upon collecting a given publication of dNFT. 
 *         It is cloned upon the first collect for a given publication of dNFT.
 *         Incubator can receive standard ERC20 and ERC3525 Token
 */
contract Incubator is IIncubator, IERC165, IERC3525Receiver, AccessControl 
{
    using SafeERC20 for IERC20;

    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }

    bool private _initialized;
    uint256 internal _soulBoundTokenId;
    address private immutable MANAGER;
    address private immutable SOULBOUNDTOKEN;

    constructor(
        address manager,
        address soulBoundToken
    ) {
        if (manager == address(0)) revert Errors.InitParamsInvalid();
        if (soulBoundToken == address(0)) revert Errors.InitParamsInvalid();

        MANAGER = manager;
        SOULBOUNDTOKEN = soulBoundToken;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function initialize(uint256 soulBoundTokenId) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        _soulBoundTokenId = soulBoundTokenId;
        emit Events.IncubatorInitialized(_soulBoundTokenId, block.timestamp);
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
        emit Events.Received(operator, fromTokenId, toTokenId, value, data, gasleft());
        return 0x009ce20b;
    }

 

    //TODO withdraw deposit royalties

    
}