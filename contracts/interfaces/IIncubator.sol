// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IIncubator
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the Incubator contract, which is cloned for any SoulBoundToken.
 */
interface IIncubator {
    /**
     * @notice Initializes the Incubator, setting the manager as the privileged minter and storing the associated SoulBoundToken ID.
     *
     * @param ndpt The NDPT contract
     * @param soulBoundTokenId The token ID of the profile in the manager associated with this Incubator, used for transfer hooks.
     */
    function initialize(
        address ndpt,        
        uint256 soulBoundTokenId
    ) external;

    function name() external returns(string memory);


     //TODO withdraw deposit royalties
}