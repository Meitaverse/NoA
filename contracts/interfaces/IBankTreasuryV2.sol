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
    function WithdrawEarnestFunds(
        uint256 toSoulBoundTokenId,
        address currency,
        uint256 amount
    ) external;

    function exchangeVoucher(
        uint256 tokenId,
        uint256 soulBoundTokenId      
    ) external;
    

    function buySBTByEth(
        uint256 soulBoundTokenId, 
        address currency,
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

    function balanceOf(address currency, uint256 soulBoundTokenId) external view returns (uint256 balance);

    function calculateAmountCurrency(address currency, uint256 ethAmount) external view returns(uint256);

    function calculateAmountSBT(address currency, uint256 sbtValue) external view returns(uint256);


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
    function distributeFundsToUserRevenue(
        uint256 publishId,
        address currency,
        uint256 payValue,
        DataTypes.CollectFeeUsers memory collectFeeUsers,
        DataTypes.RoyaltyAmounts memory royaltyAmounts
    ) external;

    function useEarnestFundsForPay(
        uint256 soulBoundTokenId,
        address currency,
        uint256 amount
    ) external;

    function refundEarnestFunds(
        uint256 soulBoundTokenId,
        address currency,
        uint256 amount
    ) external;

    function marketLockupFor(
        address account,
        uint256 soulBoundTokenId, 
        address currency,
        uint256 amount
    ) external returns (uint256 expiration);

    function marketChangeLockup(
        uint256 unlockFromSoulBoundTokenId,
         address currency,
        uint256 unlockExpiration,
        uint256 unlockAmount,
        uint256 lockupForSoulBoundTokenId,
        uint256 lockupAmount
    ) external returns (uint256 expiration);

    function marketUnlockFor(
        address account,
        uint256 soulBoundTokenId,
        uint256 expiration,
         address currency,
        uint256 amount
    ) external;

    function marketTransferLocked(
        address account,
        uint256 soulBoundTokenIdBuyer,
        address owner,
        uint256 soulBoundTokenIdOwner,
        uint256 expiration,
         address currency,
        uint256 amount
    ) external;


}
