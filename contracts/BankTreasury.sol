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
import {DataTypes} from './libraries/DataTypes.sol';
import {IBankTreasury} from './interfaces/IBankTreasury.sol';
import {IIncubator} from "./interfaces/IIncubator.sol";

/**
 *  @title Bank Treasury
 *  @author bitsoul Protocol
 * 
 */
contract BankTreasury is IBankTreasury, IERC165, IERC3525Receiver, AccessControl {
    using SafeERC20 for IERC20;

    bool private _initialized;

    // solhint-disable-next-line var-name-mixedcase
    address private immutable _MANAGER;
    // solhint-disable-next-line var-name-mixedcase
    address private immutable _SOULBOUNDTOKEN;
    // solhint-disable-next-line var-name-mixedcase
    address private immutable _NDPT;

    address private _goverance;

    constructor( 
        address manager,
        address soulBoundToken,
        address ndpt
    ) {
        if (manager == address(0)) revert Errors.InitParamsInvalid();
        if (soulBoundToken == address(0)) revert Errors.InitParamsInvalid();
        if (ndpt == address(0)) revert Errors.InitParamsInvalid();
       
        _MANAGER = manager;
        _SOULBOUNDTOKEN = soulBoundToken;
        _NDPT = ndpt;
       
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function initialize(address goverance) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;

        if (goverance == address(0)) revert Errors.InitParamsInvalid();
        _goverance = goverance;
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

    function burnValue(uint256 tokenId, uint256 value) external {

    }

    function burnValueWithSig(
        uint256 tokenId, 
        uint256 value, 
        DataTypes.EIP712Signature calldata sig
    ) external {

    }

}