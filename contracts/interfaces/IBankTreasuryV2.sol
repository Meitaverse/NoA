// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';

/**
 * @title IBankTreasuryV2
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the BankTreasuryBase contract, from which the BankTreasury inherit.
 */
interface IBankTreasuryV2 {

    /**
     * @notice Implementation of an EIP-712 permit-style function for token burning. Allows anyone to burn
     * a token on behalf of the owner with a signature.
     *
     * @param currency The ERC3525 contract token address.
     * @param fromTokenId  the token ID from.
     * @param toTokenId token ID to.
     * @param value The value of the token ID.
     */
    //  * @param nonce nonce of sig.
    //  * @param sig The EIP712 signature struct.
    function withdrawERC3525(
        address currency, 
        uint256 fromTokenId, 
        uint256 toTokenId, 
        uint256 value
        // uint256 nonce, 
        // DataTypes.EIP712Signature calldata sig
    ) external;


    function exchangeNDPT(       
        address currency, 
        uint256 fromTokenId, 
        uint256 toTokenId, 
        uint256 value
        // uint256 nonce, 
        // DataTypes.EIP712Signature calldata sig
    )  external payable;


    //TODO
    // function stake() external;
    // function redeem() external;

    function getOwners() external view returns (address[] memory);

    function getTransactionCount() external view returns (uint256);

    function getManager() external returns(address);

    function setGovernance(address newGovernance) external;

    function getGovernance() external returns(address);

}
