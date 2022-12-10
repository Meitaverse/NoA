// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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
        address to,
        uint256 amount, 
        bytes[] calldata datas
    ) external returns(uint256) {
       uint256 tokenId =  IDerivativeNFTV1(derivatveNFT).publish(slotDetail_, to, amount);

       emit Events.PublishDerivativeNFT(
            soulBoundTokenId,
            to,
            slotDetail_.eventId,
            tokenId,
            amount,
            block.timestamp
       );

        //TODO publishModule

       return tokenId;
    }

     function combo(
        DataTypes.SlotDetail memory slotDetail_,
        address derivatveNFT,
        uint256 soulBoundTokenId, 
        uint256[] memory fromTokenIds_,
        string memory eventMetadataURI_,
        bytes[] calldata datas
    ) external {
        address to_;


        //TODO comboModule

    }

}    