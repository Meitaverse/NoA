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
     * @notice Deposit a ERC20 or SBT value to earnest funds
     *         after staked, the currency of avaliable tokens will be added.
     *
     * @param soulBoundTokenId The SBT token Id 
     * @param currency The ERC20 currency
     * @param amount The value of the token ID.
     */
    function deposit(
        uint256 soulBoundTokenId, 
        address currency, 
        uint256 amount
    ) external;

    /**
     * @notice Withdraw avaliable currency balance to msg.sender wallet
     * @param soulBoundTokenId The soulBoundTokenId of caller.
     * @param currency The currency of avaliable tokens.
     * @param amount The total amount of balance, not include locked.
     */
    function withdrawEarnestFunds(
        uint256 soulBoundTokenId,
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
        uint256 amount
        // DataTypes.EIP712Signature calldata sign
    ) external payable ;

     function exchangeEthBySBT(
        uint256 soulBoundTokenId,
        uint256 sbtValue
        // DataTypes.EIP712Signature calldata sign        
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
    
    //function getDomainSeparator() external view returns (bytes32);

    /**
     * @notice Save funds to mapping revenues, user can withdraw it if reach a limit amount
     *
     */
    function distributeFundsToUserRevenue(
        uint256 fromSoulBoundTokenId,
        address currency,
        uint256 payValue,
        DataTypes.CollectFeeUsers memory collectFeeUsers,
        DataTypes.RoyaltyAmounts memory royaltyAmounts
    ) external;


    function refundEarnestFunds(
        uint256 soulBoundTokenId,
        address currency,
        uint256 amount
    ) external;

    function useEarnestFundsForPay(
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
