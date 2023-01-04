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
     * @notice Initializes the bank treasury, setting the manager as the privileged minter and storing the associated SoulBoundToken ID.
     * @param goverance The goverance contract
     * @param soulBoundTokenId The  soulBoundToken Id of BankTreasury contract
     * @param _owners The array Address of owner contract
     * @param _numConfirmationsRequired The number confirmation required
     */
    function initialize(
        address goverance,
        uint256 soulBoundTokenId,
        address[] memory _owners, 
        uint256 _numConfirmationsRequired
    ) external;

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
        uint256 voucherId,
        uint256 soulBoundTokenId      
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

    function getGovernance() external view returns(address);

    function getSoulBoundTokenId() external view returns (uint256);

    function getNDPT() external view returns(address);

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
