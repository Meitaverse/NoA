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
     * @param manager The  Address of Manager contract
     * @param goverance The  Address of Goverance contract
     * @param ndpt The  Address of NDPT contract
     * @param voucher The  Address of voucher contract
     * @param soulBoundTokenId The  soulBoundToken Id of BankTreasury contract
     * @param _owners The array Address of owner contract
     * @param _numConfirmationsRequired The number confirmation required
     */
    function initialize(
        address manager,
        address goverance,
        address ndpt,
        address voucher,
        uint256 soulBoundTokenId,
        address[] memory _owners, 
        uint256 _numConfirmationsRequired
        // uint16 treasuryFee,
        // uint256 publishFee
    ) external;

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
    
    function createVoucher(
        address account, 
        uint256 id, 
        uint256 amount, 
        bytes memory data 
    ) external payable;

    function createBatchVoucher(
        address account, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data 
    ) external payable;

    //TODO
    // function stake() external;
    // function redeem() external;

    function getOwners() external view returns (address[] memory);

    function getTransactionCount() external view returns (uint256);

    function setManager(address newManager) external;
    function getManager() external returns(address);

    function setGovernance(address newGovernance) external;
    function getGovernance() external returns(address);

    function getSoulBoundTokenId() external returns (uint256);

    function setNDPT(address newNDPT) external;
    function getNDPT() external returns(address);

    function setVoucher(address newVoucher) external;
    function getVoucher() external view returns(address);

}
