// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import './Constants.sol';

/**
 * @title SBTLogic
 * @author bitsoul Protocol
 *
 * @notice This is the library that contains the logic for create profile & burn process. 
 
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood.
 */
library SBTLogic {

    function createProfile(
        uint256 tokenId_,
        string memory nickName,
        string memory imageURI,
        mapping(uint256 => DataTypes.SoulBoundTokenDetail) storage _sbtDetails
    ) external {
        if (tokenId_ == 0) revert Errors.TokenIdIsZero();
        
        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: nickName,
            imageURI: imageURI,
            locked: true
        });
    }

    function updateProfile(
        uint256 soulBoundTokenId,
        string calldata nickName,
        string calldata imageURI,
        mapping(uint256 => DataTypes.SoulBoundTokenDetail) storage _sbtDetails
    ) external {
        if (soulBoundTokenId == 0) revert Errors.TokenIdIsZero();
        
        _sbtDetails[soulBoundTokenId] = DataTypes.SoulBoundTokenDetail({
            nickName: nickName,
            imageURI: imageURI,
            locked: true
        });

    }

    function burnProcess(
        address sbt,
        uint256 soulBoundTokenId,
        mapping(uint256 => DataTypes.SoulBoundTokenDetail) storage _sbtDetails
    ) external {
        uint256 balance = IERC3525(sbt).balanceOf(soulBoundTokenId);

        if (balance > 0 ) {
            INFTDerivativeProtocolTokenV1(sbt).transferValue(soulBoundTokenId, BANK_TREASURY_SOUL_BOUND_TOKENID, balance);
        }
        
        delete _sbtDetails[soulBoundTokenId];
        
    }


}    