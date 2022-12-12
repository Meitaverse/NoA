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
        DataTypes.SlotDetail memory slotDetail_,
        address derivatveNFT,
        uint256 soulBoundTokenId, 
        address incubator,
        uint256 amount, 
        bytes[] calldata datas
    ) external returns(uint256) {
       uint256 newTokenId =  IDerivativeNFTV1(derivatveNFT).publish(slotDetail_, incubator, amount);
       
       emit Events.PublishDerivativeNFT(
            soulBoundTokenId,
            incubator,
            slotDetail_.eventId,
            newTokenId,
            amount,
            block.timestamp
       );

        //TODO publishModule
        emit Events.PublishDerivativeNFT(
            soulBoundTokenId,
            incubator,
            slotDetail_.eventId,
            newTokenId,
            amount,
            block.timestamp
         );

       return newTokenId;
    }

     function combo(
        DataTypes.SlotDetail memory slotDetail_,
        address derivatveNFT,
        uint256 soulBoundTokenId, 
        uint256[] memory fromTokenIds_,
        bytes[] calldata datas,
        mapping(uint256 => address) storage _incubatorBySoulBoundTokenId
    ) external returns(uint256) {
        address toIncubator = _incubatorBySoulBoundTokenId[soulBoundTokenId];
        uint256 newTokenId =  IDerivativeNFTV1(derivatveNFT).combo(slotDetail_, fromTokenIds_, toIncubator);

        //TODO comboModule
        emit Events.ComboDerivativeNFT(
            soulBoundTokenId,
            toIncubator,
            slotDetail_.eventId,
            fromTokenIds_,
            newTokenId,
            block.timestamp
        );
        return newTokenId;
    }

    function split(
        address derivatveNFT,
        address incubator,
        uint256 soulBoundTokenId, 
        uint256 tokenId, 
        uint256 amount, 
        bytes[] calldata datas
    ) external returns(uint256){
        //TODO
        uint256 originalValue = IERC3525(derivatveNFT).balanceOf(tokenId);
        if (originalValue <= amount) revert Errors.InsufficientFund();

         uint256 newTokenId =  IDerivativeNFTV1(derivatveNFT).split(
            tokenId,
            incubator,
            amount
         );
         
         emit Events.SplitDerivativeNFT(
            soulBoundTokenId,
            incubator,
            tokenId,
            originalValue,
            newTokenId,
            amount,
            block.timestamp
         );

         return newTokenId;

    }
}    