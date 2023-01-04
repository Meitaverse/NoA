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
     * @param toSoulBoundTokenId token ID to.
     * @param amount The value of the token ID.
     */
    //  * @param nonce nonce of sig.
    //  * @param sig The EIP712 signature struct.
    function withdrawERC3525(
        uint256 toSoulBoundTokenId,
        uint256 amount
    ) external;


      function exchangeNDPTByEth(
        uint256 soulBoundTokenId, 
        uint256 amount,
        DataTypes.EIP712Signature calldata sign
    ) external payable ;


     function exchangeEthByNDPT(
        uint256 soulBoundTokenId,
        uint256 ndptAmount,
        DataTypes.EIP712Signature calldata sign        
    ) external payable;


    //TODO
    // function stake() external;
    // function redeem() external;

    function getSigners() external view returns (address[] memory);

    function getTransactionCount() external view returns (uint256);

    function getManager() external view returns(address);
    function getGovernance() external returns(address);

    function getSoulBoundTokenId() external returns (uint256);

    function getNDPT() external returns(address);

    function getVoucher() external view returns(address);

     function calculateAmountEther(uint256 ethAmount) external view returns(uint256);

    function calculateAmountNDPT(uint256 ndptAmount) external view returns(uint256);


    /**
     * @notice Returns the domain separator for this NFT contract.
     *
     * @return bytes32 The domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);
}
