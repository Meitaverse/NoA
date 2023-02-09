// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import './Constants.sol';
import {IDerivativeNFT} from "../interfaces/IDerivativeNFT.sol";
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {IPublishModule} from '../interfaces/IPublishModule.sol';
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
        address creator,
        address wallet,
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

        emit Events.ProfileCreated(
            tokenId_,
            creator,
            wallet,    
            nickName,
            imageURI
        );
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

        emit Events.ProfileUpdated(
            soulBoundTokenId,
            nickName,
            imageURI
        );
    }


    function burnProcess(
        address caller,
        uint256 balance,
        uint256 soulBoundTokenId,
        mapping(uint256 => DataTypes.SoulBoundTokenDetail) storage _sbtDetails
    ) external {
        delete _sbtDetails[soulBoundTokenId];
        emit Events.BurnSBT(caller, soulBoundTokenId, balance, block.timestamp);
    }

}    