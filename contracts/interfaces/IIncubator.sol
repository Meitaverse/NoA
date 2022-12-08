// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IIncubator
 * @author ShowDao Protocol
 *
 * @notice This is the interface for the Incubator contract, which is cloned for any SoulBoundToken.
 */
interface IIncubator {
    /**
     * @notice Initializes the Incubator, setting the manager as the privileged minter and storing the associated SoulBoundToken ID.
     *
     * @param soulBoundTokenId The token ID of the profile in the manager associated with this Incubator, used for transfer hooks.
     */
    function initialize(uint256 soulBoundTokenId) external;

   
}