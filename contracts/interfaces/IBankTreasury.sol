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
     * @param admin The admin address
     * @param goverance The goverance contract
     * @param soulBoundTokenId The  soulBoundToken Id of BankTreasury contract
     * @param _owners The array Address of owner contract
     * @param _numConfirmationsRequired The number confirmation required
     * @param _lockupDuration The lock duration in seconds
     */
    function initialize(
        address admin,
        address goverance,
        uint256 soulBoundTokenId,
        address[] memory _owners, 
        uint256 _numConfirmationsRequired,
        uint256 _lockupDuration
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
    function WithdrawEarnestMoney(
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

    function getGlobalModule() external view returns(address);
    
    function getSigners() external view returns (address[] memory);

    function getTransactionCount() external view returns (uint256);

    function getManager() external view returns(address);

    function getGovernance() external view returns(address);

    function getSBT() external view returns(address);

    function getVoucher() external view returns(address);

    function balanceOf(uint256 soulBoundTokenId) external view returns (uint256 balance);

    function calculateAmountEther(uint256 ethAmount) external view returns(uint256);

    function calculateAmountSBT(uint256 sbtValue) external view returns(uint256);


    /**
     * @notice Returns the domain separator for this NFT contract.
     *
     * @return bytes32 The domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @notice Save funds to mapping revenues, user can withdraw it if reach a limit amount
     *
     */
    function saveFundsToUserRevenue(
        uint256 fromSoulBoundTokenId,
        uint256 payValue,
        DataTypes.CollectFeeUsers memory collectFeeUsers,
        DataTypes.RoyaltyAmounts memory royaltyAmounts
    ) external;

    function useEarnestMoneyForPay(
        uint256 soulBoundTokenId,
        uint256 amount
    ) external;

    function refundEarnestMoney(
        uint256 soulBoundTokenId,
        uint256 amount
    ) external;

    function marketLockupFor(
        address account,
        uint256 soulBoundTokenId, 
        uint256 amount
    ) external returns (uint256 expiration);

    function marketChangeLockup(
        uint256 unlockFromSoulBoundTokenId,
        uint256 unlockExpiration,
        uint256 unlockAmount,
        uint256 lockupForSoulBoundTokenId,
        uint256 lockupAmount
    ) external returns (uint256 expiration);

    function marketUnlockFor(
        address account,
        uint256 soulBoundTokenId,
        uint256 expiration,
        uint256 amount
    ) external;

    function marketWithdrawLocked(
        address account,
        uint256 soulBoundTokenIdBuyer,
        address owner,
        uint256 soulBoundTokenIdOwner,
        uint256 expiration,
        uint256 amount
    ) external;

    
}
