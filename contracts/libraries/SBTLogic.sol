// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {ERC3525Upgradeable} from "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {Constants} from './Constants.sol';
import {IDerivativeNFTV1} from "../interfaces/IDerivativeNFTV1.sol";
import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {IPublishModule} from '../interfaces/IPublishModule.sol';
/**
 * @title SBTLogic
 * @author bitsoul
 *
 * @notice This is the library that contains the logic for public & send to market place. 
 
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
            imageURI,
            block.timestamp
        );
    }

    function contractWhitelistedSet(
        address contract_, bool toWhitelist_,
        mapping(address => bool) storage _contractWhitelisted
    ) external {
        if (contract_ == address(0)) revert Errors.InitParamsInvalid();

        bool prevWhitelisted = _contractWhitelisted[contract_];

        _contractWhitelisted[contract_] = toWhitelist_;

        emit Events.SetContractWhitelisted(
            contract_,
            prevWhitelisted,
            toWhitelist_,
            block.timestamp
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