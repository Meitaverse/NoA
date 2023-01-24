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

    // function getGovernance() external view returns(address);

    // function publishSale(
    //     DataTypes.SaleParam memory saleParam
    // ) external;

    //function fixedPriceSet(uint24 saleId, uint128 newSalePrice) external;

    //function removeSale(uint24 saleId) external;

    function addMarket(
        address derivativeNFT_,
        DataTypes.FeePayType feePayType_,
        DataTypes.FeeShareType feeShareType_,
        uint16 royaltyBasisPoints_
    ) external;

    function getMarketInfo(address derivativeNFT) external returns(DataTypes.Market memory);

    function removeMarket(
        address derivativeNFT_
    ) external;

/*
    function buyUnits(
        uint256 buyerSoulBoundTokenId,
        uint24 saleId, 
        uint128 units
    )  external payable;

    function purchasedUnits(
        uint24 saleId_, 
        address buyer_
    ) external view returns(uint128);

    function saleIdOfDerivativeNFTByIndex(
        address derivativeNFT_, 
        uint256 index_
    )
        external
        view
        returns (uint256);

    function getSaleData( uint24 saleId) external view returns(DataTypes.Sale memory);
*/
}