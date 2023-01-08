// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Events} from "../libraries/Events.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";

/**
 * @title DerivativeNFTMultiState
 *
 * @notice This is an abstract contract that implements internal derivativeNFT state setting and validation.
 *
 * whenNotPaused: Either publishingPaused or Unpaused.
 * whenPublishingEnabled: When Unpaused only.
 */
abstract contract DerivativeNFTMultiState {
    DataTypes.DerivativeNFTState private _state;

    modifier whenNotPaused() {
        _validateNotPaused();
        _;
    }

    /**
     * @notice Returns the current DerivativeNFT state.
     *
     * @return DerivativeNFTState The DerivativeNFT state, an enum, where:
     *      0: Unpaused
     *      1: Paused
     */
    function getState() external view returns (DataTypes.DerivativeNFTState) {
        return _state;
    }

    function _setState(DataTypes.DerivativeNFTState newState) internal {
        DataTypes.DerivativeNFTState prevState = _state;
        _state = newState;
        emit Events.DerivativeNFTStateSet(msg.sender, prevState, newState, block.timestamp);
    }

    function _validateNotPaused() internal view {
        if (_state == DataTypes.DerivativeNFTState.Paused) revert Errors.Paused();
    }

}