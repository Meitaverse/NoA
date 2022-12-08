// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IManager} from '../interfaces/IManager.sol';
import {IFollowModule} from '../interfaces/IFollowModule.sol';
import {ISoulBoundTokenV1} from '../interfaces/ISoulBoundTokenV1.sol';
import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';
import {ModuleBase} from './ModuleBase.sol';
import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";
/**
 * @title FollowValidationModuleBase
 * @author Devirative NFT Protocol
 *
 * @notice This abstract contract adds a simple non-specific follow validation function.
 *
 * NOTE: Both the `MANAGER` variable and `_checkFollowValidity()` function are exposed to inheriting
 * contracts.
 *
 * NOTE: This is only compatible with COLLECT & REFERENCE MODULES.
 */
abstract contract FollowValidationModuleBase is ModuleBase {
    /**
     * @notice Validates whether a given user is following a given SoulBoundTokenId.
     *
     * @dev It will revert if the user is not following the profile except the case when the user is the SoulBoundTokenId owner.
     *
     * @param soulBoundTokenId The ID of the SoulBoundToken that should be followed by the given user.
     * @param user The address of the user that should be following the given soulBoundTokenId.
     */
    function _checkFollowValidity(uint256 soulBoundTokenId, address user) internal view {
        address followModule = IManager(MANAGER).getFollowModule(soulBoundTokenId);
        bool isFollowing;

        if (followModule != address(0)) {
            isFollowing = IFollowModule(followModule).isFollowing(soulBoundTokenId, user, 0);
        } else {
            // address followNFT = IManager(MANAGER).getFollowNFT(soulBoundTokenId);
            // isFollowing = followNFT != address(0) && IERC3525(followNFT).balanceOf(user) != 0;
        }
        address soulBoundToken = IManager(MANAGER).getSoulBoundToken();
        if (!isFollowing && IERC3525(soulBoundToken).ownerOf(soulBoundTokenId) != user) {
            revert Errors.FollowInvalid(); 
        }
    }
}
