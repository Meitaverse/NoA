// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';

/**
 * @title IBankTreasury
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the BankTreasuryBase contract, from which the BankTreasury inherit.
 */
interface IBankTreasuryV2 {
    /**
     * @notice Implementation of an EIP-712 permit-style function for token burning. Allows anyone to burn
     * a token on behalf of the owner with a signature.
     *
     * @param toSoulBoundTokenId token ID to.
     * @param amount The value of the token ID.
     */
    //  * @param nonce nonce of sig.
    //  * @param sig The EIP712 signature struct.
    function withdrawERC3525(
        uint256 toSoulBoundTokenId,
        uint256 amount
    ) external;

    function exchangeVoucher(
        uint256 tokenId,
        uint256 soulBoundTokenId      
    ) external;
    

    function exchangeSBTByEth(
        uint256 soulBoundTokenId, 
        uint256 amount,
        DataTypes.EIP712Signature calldata sign
    ) external payable ;

     function exchangeEthBySBT(
        uint256 soulBoundTokenId,
        uint256 sbtValue,
        DataTypes.EIP712Signature calldata sign        
    ) external payable;

    function getSigners() external view returns (address[] memory);

    function getTransactionCount() external view returns (uint256);

    function getManager() external view returns(address);

    function getGovernance() external view returns(address);

    function getSBT() external view returns(address);

    function getVoucher() external view returns(address);

     function calculateAmountEther(uint256 ethAmount) external view returns(uint256);

    function calculateAmountSBT(uint256 sbtValue) external view returns(uint256);


    /**
     * @notice Returns the domain separator for this NFT contract.
     *
     * @return bytes32 The domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);
}
