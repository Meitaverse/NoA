// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';

/**
 * @title IMarketPlace
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the MarketPlace contract
 */
interface IMarketPlace {
    /**
     * @notice Initializes the MarketPlace, setting the initial governance address
     *
     * @param admin The address of admin.
     */
    function initialize(    
       address admin
    ) external;


}