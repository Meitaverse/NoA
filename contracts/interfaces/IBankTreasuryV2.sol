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
   

    function getGlobalModule() external view returns(address);

    function getManager() external view returns(address);

    function getGovernance() external view returns(address);

    function getSBT() external view returns(address);

    function getVoucher() external view returns(address);

    function balanceOf(address currency, uint256 soulBoundTokenId) external view returns (uint256 balance);

    function calculateAmountSBT(address currency, uint256 sbtValue) external view returns(uint256);
    
    function getExchangePrice(
        address currency
    ) external view returns(uint256, uint256);

    /**
     * @notice Deposit a ERC20 or SBT value to earnest funds
     *         and the avaliable currency tokens will be added.
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
    function withdraw(
        uint256 soulBoundTokenId,
        address currency,
        uint256 amount
    ) external;

    /**
     * @notice Deposit SBT Value by an unused voucher 
     * @param tokenId The tokenId of voucher.
     * @param soulBoundTokenId The soulBoundTokenId of caller.
     */
    function depositFromVoucher(
        uint256 tokenId,
        uint256 soulBoundTokenId      
    ) external;

    /**
     * @notice Buy SBT Value by Ether.
     *  The surplus funds provided are refunded.
     * @param soulBoundTokenId The soulBoundTokenId of caller.
     */
    function buySBT(
        uint256 soulBoundTokenId
    ) external payable;

    /**
     * @notice Exchange ERC20 tokens by SBT Value
     *      
     * @dev Currency only in whitelisted
     * @param soulBoundTokenId The soulBoundTokenId of account
     * @param currency The ERC20 currency of the token to be unlocked.
     * @param sbtValue The amount of SBT value.
     */
    function exchangeERC20BySBT(
        uint256 soulBoundTokenId,
        address currency,
        uint256 sbtValue
    ) external payable;

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


    /**
     * @notice Used by the market contract only:
     *      Use free earnest funs balance for pay 
     * @dev Used by the market when buy or placeBid
     * @param soulBoundTokenId The soulBoundTokenId of account
     * @param currency The ERC20 currency of the token to be unlocked.
     * @param amount The number of earnest funds to be locked up for the `lockupFor`'s account.
     */
    function useEarnestFundsForPay(
        uint256 soulBoundTokenId,
        address currency,
        uint256 amount
    ) external;


    /**
     * @notice Used by the market contract only:
     *      Refund orinigal escrow tokens to free balance
     * @dev Used by the placeBid 
     * @param soulBoundTokenId The soulBoundTokenId of account
     * @param currency The ERC20 currency of the token to be unlocked.
     * @param amount The number of earnest funds to be locked up for the `lockupFor`'s account.
     */
    function refundEarnestFunds(
        uint256 soulBoundTokenId,
        address currency,
        uint256 amount
    ) external;    

    /**
     * @notice Used by the market contract only:
     * Lockup an account's earnest funds for 24-25 hours.
     * @dev Used by the market when a new offer for an DNFT is made.
     * @param account The address
     * @param soulBoundTokenId The soulBoundTokenId of account
     * @param amount The number of earnest funds to be locked up for the `lockupFor`'s account.
     * @return expiration The expiration timestamp for the earnest funds  that were locked.
     */
    function marketLockupFor(
        address account,
        uint256 soulBoundTokenId, 
        address currency,
        uint256 amount
    ) external returns (uint256 expiration);


    /**
     * @notice Used by the market contract only:
     * Remove an account's lockup and then create a new lockup, potentially for a different account.
     * @dev Used by the market when an offer for an NFT is increased.
     * This may be for a single account (increasing their offer)
     * or two different accounts (outbidding someone elses offer).
     * @param unlockFromSoulBoundTokenId The SBT Id whose lockup is to be removed.
     * @param currency The ERC20 currency of the token to be unlocked.
     * @param unlockExpiration The original lockup expiration for the tokens to be unlocked.
     * This will revert if the lockup has already expired.
     * @param unlockAmount The number of tokens to be unlocked from `unlockFrom`'s account.
     * This will revert if the tokens were previously unlocked.
     * @param lockupForSoulBoundTokenId The SBT id to which the funds are to be deposited for and tokens locked up.
     * @param lockupAmount The number of tokens to be locked up for the `lockupFor`'s account.
     * `msg.value` must be <= `lockupAmount` and any delta will be taken from the account's available FETH balance.
     * @return expiration The expiration timestamp for the FETH tokens that were locked.
     */
    function marketChangeLockup(
        uint256 unlockFromSoulBoundTokenId,
         address currency,
        uint256 unlockExpiration,
        uint256 unlockAmount,
        uint256 lockupForSoulBoundTokenId,
        uint256 lockupAmount
    ) external returns (uint256 expiration);

    /**
     * @notice Used by the market contract only:
     * Remove an account's lockup, making the earnest funds tokens available for transfer or withdrawal.
     * @dev Used by the market when an offer is invalidated, which occurs when an auction for the same dNFT
     * receives its first bid or the buyer purchased the dNFT another way, such as with `buy`.
     * @param account The account whose lockup is to be unlocked.
     * @param expiration The original lockup expiration for the tokens to be unlocked.
     * This will revert if the lockup has already expired.
     * @param amount The number of tokens to be unlocked from `account`.
     * This will revert if the tokens were previously unlocked.
     */
    function marketUnlockFor(
        address account,
        uint256 soulBoundTokenId,
        uint256 expiration,
        address currency,
        uint256 amount
    ) external;

    /**
     * @notice Used by the market contract only:
     * Removes a lockup from the user's account and then add balance to the owner.
     * @dev Used by the market to extract unexpired funds to distribute for
     * a sale when the user's offer is accepted.
     * @param account The account whose lockup is to be removed.
     * @param soulBoundTokenIdBuyer The SBT Id whose lockup is to be removed.
     * @param owner The owner of offer
     * @param soulBoundTokenIdOwner The SBT Id of owner
     * @param expiration The original lockup expiration for the tokens to be unlocked.
     * This will revert if the lockup has already expired.
     * @param currency The ERC20 currency
     * @param totalAmount The number of tokens to be unlocked and add to owner free balance .
     */
    function marketTransferLocked(
        address account,
        uint256 soulBoundTokenIdBuyer,
        address owner,
        uint256 soulBoundTokenIdOwner,
        uint256 expiration,
        address currency,
        uint256 totalAmount
    ) external;
}
