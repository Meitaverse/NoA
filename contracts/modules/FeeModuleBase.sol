// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {IModuleGlobals} from "../interfaces/IModuleGlobals.sol";

/**
 * @title FeeModuleBase
 * @author Bitsoul Protocol
 *
 * @notice This is an abstract contract to be inherited from by modules that require basic fee functionality. It
 * contains getters for module globals parameters as well as a validation function to check expected data.
 */
abstract contract FeeModuleBase {
    uint16 internal constant BPS_MAX = 10000;

    address public immutable MODULE_GLOBALS;

    constructor(address moduleGlobals) {
        if (moduleGlobals == address(0)) revert Errors.InitParamsInvalid();
        MODULE_GLOBALS = moduleGlobals;
        emit Events.FeeModuleBaseConstructed(moduleGlobals, block.timestamp);
    }

    function _treasuryData() internal view returns (address, uint16) {
        return IModuleGlobals(MODULE_GLOBALS).getTreasuryData();
    }

    function _wallet(uint256 soulBoundTokenId) internal view returns (address) {
        return IModuleGlobals(MODULE_GLOBALS).getWallet(soulBoundTokenId);
    }

    function _treasury() internal view returns (address) {
        return IModuleGlobals(MODULE_GLOBALS).getTreasury();
    }

    function _sbt() internal view returns (address) {
        return IModuleGlobals(MODULE_GLOBALS).getSBT();
    }
    
    function  _publishCurrencyTax() internal returns (uint256) {
        return IModuleGlobals(MODULE_GLOBALS).getPublishCurrencyTax();
    }
    
    function  _isWhitelistTemplate(address template) internal view returns (bool) {
        return IModuleGlobals(MODULE_GLOBALS).isWhitelistTemplate(template);
    }


}
