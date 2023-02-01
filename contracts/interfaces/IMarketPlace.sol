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
     * @param governance_ The address of Governance.
     */
    function initialize(    
       address governance_
    ) external;
   
    function getGlobalModule() external view returns(address);

    function getMarketInfo(address derivativeNFT) external returns(DataTypes.Market memory);

    function removeMarket(
        address derivativeNFT_
    ) external;

}