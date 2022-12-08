// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';

/**
 * @title ModuleBase
 * @author ShowDao Protocol
 *
 * @notice This abstract contract adds a public `MANAGER` immutable to inheriting modules, as well as an
 * `onlyManager` modifier.
 */
abstract contract ModuleBase {
    address public immutable MANAGER;

    modifier onlyManager() {
        if (msg.sender != MANAGER) revert Errors.NotManager();
        _;
    }

    constructor(address manager_) {
        if (manager_ == address(0)) revert Errors.InitParamsInvalid();
        MANAGER = manager_;
        emit Events.ModuleBaseConstructed(manager_, block.timestamp);
    }
}
