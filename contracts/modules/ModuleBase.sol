// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';

/**
 * @title ModuleBase
 * @author Bitsoul Protocol
 *
 * @notice This abstract contract adds a public `MANAGER` immutable to inheriting modules, as well as an
 * `onlyManager` modifier.
 */
abstract contract ModuleBase {
    address public immutable MANAGER;
    address public immutable MARKET;

    modifier onlyManager() {
        if (msg.sender != MANAGER) revert Errors.NotManager();
        _;
    }

    modifier onlyManagerOrMarket() {
        if (!(msg.sender == MANAGER || msg.sender == MARKET)) revert Errors.NotManager();
        _;
    }

    constructor(address manager_, address market_) {
        if (manager_ == address(0)) revert Errors.InitParamsInvalid();
        MANAGER = manager_;
        if (market_ == address(0)) revert Errors.InitParamsInvalid();
        MARKET = market_;
        emit Events.ModuleBaseConstructed(manager_, market_, block.timestamp);
    }
}
