// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';

/**
 * @title IBankTreasury
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the BankTreasuryBase contract, from which the BankTreasury inherit.
 */
interface IBankTreasury {
    /**
     * @notice Initializes the Incubator, setting the manager as the privileged minter and storing the associated SoulBoundToken ID.
     * @param goverance Address of goverance contract
     */
    function initialize(address goverance) external;

    /**
     * @notice Burns an NDPT, removing it from circulation and essentially destroying it. This function can only
     * be called by the NDPT to burn's owner.
     *
     * @param tokenId The token ID of the token to burn.
     * @param value The value of the token ID to burn.
     */
    function burnValue(uint256 tokenId, uint256 value) external;

    /**
     * @notice Implementation of an EIP-712 permit-style function for token burning. Allows anyone to burn
     * a token on behalf of the owner with a signature.
     *
     * @param tokenId The token ID of the token to burn.
     * @param value The value of the token ID to burn.
     * @param sig The EIP712 signature struct.
     */
    function burnValueWithSig(uint256 tokenId, uint256 value, DataTypes.EIP712Signature calldata sig) external;

}
