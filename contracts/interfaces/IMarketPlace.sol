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
   
    function getGlobalModule() external returns(address);

    function getGovernance() external returns(address);


    function publishFixedPrice(
        DataTypes.Sale memory sale
    ) external;


    function removeSale(uint256 soulBoundTokenId, address seller, uint24 saleId) external;

    function addMarket(
        address derivativeNFT_,
        uint64 precision_,
        uint8 feePayType_,
        uint8 feeType_,
        uint128 feeAmount_,
        uint16 feeRate_
    ) external;

    function removeMarket(
        address derivativeNFT_
    ) external;

    function buyUnits(
        uint256 soulBoundTokenId,
        address buyer,
        uint24 saleId, 
        uint128 units
    )  external payable returns (uint256 amount, uint128 fee);
    
    function purchasedUnits(
        uint24 saleId_, 
        address buyer_
    ) external view returns(uint128);
   
}