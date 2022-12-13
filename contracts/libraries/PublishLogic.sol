// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {Constants} from './Constants.sol';
import {IIncubator} from '../interfaces/IIncubator.sol';
import {IDerivativeNFTV1} from "../interfaces/IDerivativeNFTV1.sol";


/**
 * @title PublishLogic
 * @author bitsoul.xyz
 *
 * @notice This is the library that contains the logic for public & send to market place. 
 
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood.
 */
library PublishLogic {

    function publish(
        uint256 projectId,
        DataTypes.Publication memory publication,
        address derivatveNFT,
        uint256 soulBoundTokenId, 
        uint256 amount,
        bytes calldata publishModuleData
    ) external returns(uint256) {
       uint256 newTokenId =  IDerivativeNFTV1(derivatveNFT).publish(
            soulBoundTokenId, 
            publication, 
            amount
        );
       
        emit Events.PublishDerivativeNFT(
            soulBoundTokenId,
            projectId,
            newTokenId,
            amount,
            block.timestamp
        ); 

        //TODO publishModule
        publishModuleData;

       return newTokenId;
    }

    function split(
        address derivatveNFT,
        uint256 fromSoulBoundTokenId, 
        uint256 toSoulBoundTokenId, 
        uint256 tokenId, 
        uint256 amount, 
        bytes calldata splitModuleData
    ) external returns(uint256){
         uint256 originalValue = IERC3525(derivatveNFT).balanceOf(tokenId);
         if (originalValue <= amount) revert Errors.InsufficientFund();

         uint256 newTokenId = IDerivativeNFTV1(derivatveNFT).split(
            toSoulBoundTokenId,
            tokenId,
            amount
         );
         
         //TODO
         splitModuleData;

         emit Events.SplitDerivativeNFT(
            fromSoulBoundTokenId,
            toSoulBoundTokenId,
            tokenId,
            originalValue,
            newTokenId,
            amount,
            block.timestamp
         );

         return newTokenId;

    }
}    