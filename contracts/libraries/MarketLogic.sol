// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {ERC3525Upgradeable} from "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import './Constants.sol';

/**
 * @title MarketLogic
 * @author bitsoul
 *
 * @notice This is the library that contains the logic for market place. 
 
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood.
 */
library MarketLogic {
    function addMarket(
       address derivativeNFT_,
        DataTypes.FeePayType feePayType_,
        DataTypes.FeeShareType feeShareType_,
        uint16 royaltyBasisPoints_,
        mapping(address => DataTypes.Market) storage markets
    ) external {
        if (derivativeNFT_ == address(0x0)) revert Errors.InvalidParameter();

        markets[derivativeNFT_].isOpen = true;
        markets[derivativeNFT_].feePayType = DataTypes.FeePayType(feePayType_);
        markets[derivativeNFT_].feeShareType = DataTypes.FeeShareType(feeShareType_);
        markets[derivativeNFT_].royaltyBasisPoints = royaltyBasisPoints_;

        emit Events.AddMarket(
            derivativeNFT_,
            feePayType_,
            feeShareType_,
            royaltyBasisPoints_
        );
    }


}    