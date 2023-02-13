// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title IVoucherMarket
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the Voucher Market contract
 */
interface IVoucherMarket {
    /**
     * @notice Initializes the Voucher Market, setting the initial governance address
     *
     * @param admin The address of admin.
     */
    function initialize(    
       address admin
    ) external;
   
}