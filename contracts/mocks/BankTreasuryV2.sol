// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {IERC1155CreatorCore} from "../creatorCore/IERC1155CreatorCore.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../libraries/Constants.sol'; 
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {DataTypes} from '../libraries/DataTypes.sol';
import {IBankTreasuryV2} from '../interfaces/IBankTreasuryV2.sol';
import {IManager} from "../interfaces/IManager.sol";
import "../storage/BankTreasuryStorage.sol";
import {INFTDerivativeProtocolTokenV1} from "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import {IModuleGlobals} from "../interfaces/IModuleGlobals.sol";
import {AdminRoleEnumerable} from "../treasury/AdminRoleEnumerable.sol";
import {FeeModuleRoleEnumerable} from "../treasury/FeeModuleRoleEnumerable.sol";

import "../libraries/LockedBalance.sol";
import "hardhat/console.sol";

/**
 *  @title Bank TreasuryV2
 *  @author bitsoul Protocol
 * 
 *  Holds the fee, and set currencies whitelist
 */
contract BankTreasuryV2 is 
    Initializable,
    ReentrancyGuardUpgradeable,
    IBankTreasuryV2,
    BankTreasuryStorage,
    IERC165,
    IERC3525Receiver,
    PausableUpgradeable,
    AdminRoleEnumerable,
    FeeModuleRoleEnumerable,
    UUPSUpgradeable
{
    using Address for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using LockedBalance for LockedBalance.Lockups;
    using Math for uint256;

    string public name;

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    modifier onlySigner() {
        _validateCallerIsSigner();
        _;
    }

    modifier txExists(uint256 _txIndex) {
        _validateTxExists(_txIndex);
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        _validateNotExecuted(_txIndex);
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        _validateNotConfirmed(_txIndex);
        _;
    }

    /// @dev Allows the Foundation market permission to manage lockups for a user.
    modifier onlyFoundationMarket() {
        if (msg.sender != _foundationMarket) {
            revert Errors.Only_BITSOUL_Market_Allowed();
        }
        _;
    }

    /**
     * @notice Make any arbitrary calls.
     * @dev This should not be necessary, but here just in case you need to recover other assets.
     */
    function proxyCall(
        address payable target, 
        bytes memory callData, 
        uint256 value
    )
        external 
        nonReentrant
    {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert Errors.Unauthorized();
        target.functionCallWithValue(callData, value);
    }

    function setGlobalModules(address moduleGlobals) external onlyGov {
        if (moduleGlobals == address(0)) revert Errors.InitParamsInvalid();
        MODULE_GLOBALS = moduleGlobals;
    }

    function setFoundationMarket(address payable newFoundationMarket) external onlyGov {
        if (newFoundationMarket == address(0)) revert Errors.InitParamsInvalid();
        _setFoundationMarket(newFoundationMarket);
    }

    function getGlobalModule() external view returns (address) {
        return MODULE_GLOBALS;
    }

    function getManager() external view returns (address) {
        return IModuleGlobals(MODULE_GLOBALS).getManager();
    }

    function getGovernance() external view returns (address) {
        return _governance;
    }

    function getVoucher() external view returns (address) {
        address _voucher = IModuleGlobals(MODULE_GLOBALS).getVoucher();
        return _voucher;
    }

    function getSBT() external view returns (address) {
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        return _sbt;
    }

    function getLockupDuration() external view returns(uint256) {
        return lockupDuration;
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    //receive matic from opensea or other nft market place when msg.data is empty
    receive() external payable {
        emit Events.DepositEther(msg.sender, msg.value, address(this), address(this).balance);
    }

    //receive matic from opensea or other nft market place when msg.data is NOT empty
    fallback() external payable {
        emit Events.DepositByFallback(msg.sender, msg.value, msg.data, address(this), address(this).balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC3525Receiver).interfaceId;
    }

    function onERC3525Received(
        address operator,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        //console.log('BankTreasury onERC3525Received, msg.sender:', msg.sender);
        if (msg.sender != address(IModuleGlobals(MODULE_GLOBALS).getSBT())) {
            revert Errors.BankTreasury_Only_Can_Transfer_SBT();
        }
        if (value == 0) {
            revert Errors.Must_Deposit_Non_Zero_Amount();
        }

        emit Events.SBTValueReceived(
            msg.sender, 
            operator, 
            fromTokenId, 
            toTokenId, 
            value, 
            data, 
            gasleft()
        );

        return 0x009ce20b;
    }

    function deposit(
        uint256 soulBoundTokenId, 
        address currency, 
        uint256 amount
    )
        external 
        whenNotPaused
        nonReentrant
    {
        if (soulBoundTokenId == 0 || 
            soulBoundTokenId == BANK_TREASURY_SOUL_BOUND_TOKENID || 
            currency == address(0) || 
            amount == 0) 
            revert Errors.InvalidParameter();
        
        if (!IModuleGlobals(MODULE_GLOBALS).isCurrencyWhitelisted(currency))
            revert Errors.CurrencyNotInWhitelisted(currency);

        _validateCallerIsSoulBoundTokenOwner(soulBoundTokenId);

        //deposit currency value to account's fee balance
        DataTypes.AccountInfo storage accountInfo = accountToInfo[soulBoundTokenId][currency];
        _addBalanceTo(accountInfo, amount);
        
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        if ( currency == address(_sbt) ) {
            //deposit SBT Value
            INFTDerivativeProtocolTokenV1(_sbt).transferValue(
                soulBoundTokenId,
                BANK_TREASURY_SOUL_BOUND_TOKENID,
                amount
            );
        } else {
            // Before this you should have approved the amount 
            // This will transfer the amount of currency from caller to contract
            IERC20Upgradeable(currency).safeTransferFrom(msg.sender, address(this), amount);

        }
        emit Events.Deposit(
            msg.sender,
            soulBoundTokenId, 
            currency, 
            amount
        );
    }

    function submitTransaction(
        address _currency,
        DataTypes.CurrencyType _currencyType,
        address _to,
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value,
        bytes memory _data
    ) public whenNotPaused nonReentrant onlySigner {
        uint256 txIndex = _transactions.length;

        _transactions.push(
            DataTypes.Transaction({
                currency: _currency,
                currencyType: _currencyType,
                to: _to,
                fromTokenId: _fromTokenId,
                toTokenId: _toTokenId,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit Events.SubmitTransaction(
            msg.sender, 
            txIndex, 
            _to, 
            _currency,
            _value, 
            _data
        );
    }

    function confirmTransaction(
        uint256 _txIndex
    ) public whenNotPaused nonReentrant onlySigner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        DataTypes.Transaction storage transaction = _transactions[_txIndex];
        transaction.numConfirmations += 1;
        _isConfirmed[_txIndex][msg.sender] = true;

        emit Events.ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(
        uint256 _txIndex
    ) public whenNotPaused nonReentrant onlySigner txExists(_txIndex) notExecuted(_txIndex) {
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        DataTypes.Transaction storage transaction = _transactions[_txIndex];

        if (transaction.numConfirmations < _numConfirmationsRequired) revert Errors.CannotExecuteTx();

        transaction.executed = true;

        if (transaction.currencyType == DataTypes.CurrencyType.ETHER) {
            //withdraw ether
            (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
            if (!success) revert Errors.TxFailed();
        } else if (transaction.currencyType == DataTypes.CurrencyType.ERC20) {
            //withdraw ERC20
            IERC20Upgradeable(transaction.currency).safeTransfer(transaction.to, transaction.value);
            
            emit Events.ExecuteTransaction(
                msg.sender, 
                _txIndex, 
                transaction.to, 
                transaction.currency, 
                transaction.value
            );

        } else if (transaction.currencyType == DataTypes.CurrencyType.ERC3525) {
            //withdraw SBT Value
            INFTDerivativeProtocolTokenV1(_sbt).transferValue(
                transaction.fromTokenId,
                transaction.toTokenId,
                transaction.value
            );
            emit Events.ExecuteTransactionERC3525(
                msg.sender,
                _txIndex,
                transaction.fromTokenId,
                transaction.toTokenId,
                transaction.value
            );
        }
    }

    function revokeConfirmation(
        uint256 _txIndex
    ) public whenNotPaused nonReentrant onlySigner txExists(_txIndex) notExecuted(_txIndex) {
        DataTypes.Transaction storage transaction = _transactions[_txIndex];

        if (!_isConfirmed[_txIndex][msg.sender]) revert Errors.TxNotConfirmed();

        transaction.numConfirmations -= 1;
        _isConfirmed[_txIndex][msg.sender] = false;

        emit Events.RevokeConfirmation(msg.sender, _txIndex);
    }

    function getSigners() external view returns (address[] memory) {
        return _signers;
    }

    function getTransactionCount() external view returns (uint256) {
        return _transactions.length;
    }

    function getTransaction(
        uint256 _txIndex
    )
        public
        view
        returns (
            address currency,
            address to,
            uint256 fromTokenId,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        DataTypes.Transaction storage transaction = _transactions[_txIndex];

        return (
            transaction.currency,
            transaction.to,
            transaction.fromTokenId,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    /**
     * @notice Returns the balance of an account which is available to transfer or withdraw.
     * @dev This will automatically increase as soon as locked tokens reach their expiry date.
     * @param soulBoundTokenId The soulBoundTokenId to query the available balance of.
     * @return balance The available balance of the account.
     */
    function balanceOf(address currency, uint256 soulBoundTokenId) external view returns (uint256 balance) {
        DataTypes.AccountInfo storage accountInfo = accountToInfo[soulBoundTokenId][currency];
        balance = accountInfo.freedBalance;

        // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits.
        unchecked {
            // Add expired lockups
            for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
                LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
                if (escrow.expiration == 0 || escrow.expiration >= block.timestamp) {
                break;
                }
                balance += escrow.totalAmount;
            }
        }
    }

    /**
     * @notice Returns the balance and each outstanding (unexpired) lockup bucket for an account, grouped by expiry.
     * @dev `expires.length` == `amounts.length`
     * and `amounts[i]` is the number of tokens which will expire at `expires[i]`.
     * The results returned are sorted by expiry, with the earliest expiry date first.
     * @param soulBoundTokenId The soulBoundTokenId to query the locked balance of.
     * @return expiries The time at which each outstanding lockup bucket expires.
     * @return amounts The number of earnest funds which will expire for each outstanding lockup bucket.
     */
    function getLockups(address currency, uint256 soulBoundTokenId) 
        external 
        view 
        returns (uint256[] memory expiries, uint256[] memory amounts) 
    {
        DataTypes.AccountInfo storage accountInfo = accountToInfo[soulBoundTokenId][currency];

        // Count lockups
        uint256 lockedCount;
        // The number of buckets is always < 256 bits.
        unchecked {
            for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
                LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
                if (escrow.expiration == 0) {
                    break;
                }
                if (escrow.expiration >= block.timestamp && escrow.totalAmount != 0) {
                    // Lockup count will never overflow 256 bits.
                    ++lockedCount;
                }
            }
        }

        // Allocate arrays
        expiries = new uint256[](lockedCount);
        amounts = new uint256[](lockedCount);

        // Populate results
        uint256 i;
        // The number of buckets is always < 256 bits.
        unchecked {
            for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
                LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
                if (escrow.expiration == 0) {
                    break;
                }
                if (escrow.expiration >= block.timestamp && escrow.totalAmount != 0) {
                    expiries[i] = escrow.expiration;
                    amounts[i] = escrow.totalAmount;
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Returns specific currency the total balance of an account, including locked earnest funds.
     * @dev Use `totalBalanceOf` to get the number of tokens available for transfer or withdrawal.
     * @param soulBoundTokenId The soulBoundTokenId to query the total balance of.
     * @return balance The total earnest funds balance tracked for this account.
     */
    function totalBalanceOf(address currency, uint256 soulBoundTokenId) external view returns (uint256 balance) {
        DataTypes.AccountInfo storage accountInfo = accountToInfo[soulBoundTokenId][currency];
        balance = accountInfo.freedBalance;

        // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits.
        unchecked {
        // Add all lockups
        for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
            LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
            if (escrow.expiration == 0) {
                break;
            }
            balance += escrow.totalAmount;
        }
        }
    }

    function escrowBalanceOf(address currency, uint256 soulBoundTokenId) external view returns (uint256 balance) {
        DataTypes.AccountInfo storage accountInfo = accountToInfo[soulBoundTokenId][currency];

        // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits.
        unchecked {
            // Add all lockups
            for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
                LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
                if (escrow.expiration == 0) {
                    break;
                }
                balance += escrow.totalAmount;
            }
        }
    }

    /**
     * @notice Returns the total amount of ETH locked in this contract.
     * @return supply The total amount of ETH locked in this contract.
     * @dev It is possible for this to diverge from the total token count by transferring ETH on self destruct
     * but this is on-par with the WETH implementation and done for gas savings.
     */
    function totalSupply() external view returns (uint256 supply) {
        return address(this).balance;
    }
    
    function withdraw(
        uint256 soulBoundTokenId, 
        address currency, 
        uint256 amount
    ) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        _validateCallerIsSoulBoundTokenOwner(soulBoundTokenId);

        if (amount == 0) revert Errors.AmountIsZero();
        
        if (!IModuleGlobals(MODULE_GLOBALS).isCurrencyWhitelisted(currency))
            revert Errors.CurrencyNotInWhitelisted(currency);

        DataTypes.AccountInfo storage accountInfo = _freeFromEscrow(currency, soulBoundTokenId);
        _deductBalanceFrom(accountInfo, amount);

        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        if (_sbt == currency) {
            INFTDerivativeProtocolTokenV1(_sbt).transferValue(
                BANK_TREASURY_SOUL_BOUND_TOKENID, 
                soulBoundTokenId, 
                amount
            );
        } else {
            IERC20Upgradeable(currency).safeTransfer(msg.sender, amount);
        }

        emit Events.WithdrawnEarnestFunds(
            soulBoundTokenId, 
            msg.sender,
            currency,
            amount
        );
    }

   function calculateAmountSBT(address currency, uint256 amount) external view returns (uint256) {
        if (_exchangePrice[currency].sbtAmount == 0) revert Errors.ExchangePriceIsZero();
        return amount.mul(_exchangePrice[currency].currencyAmount).div(_exchangePrice[currency].sbtAmount);
    }

    function buySBT(
        uint256 soulBoundTokenId
    ) external payable whenNotPaused nonReentrant {
        // only called by owner of soulBoundTokenId
        _validateCallerIsSoulBoundTokenOwner(soulBoundTokenId);

        address currency = IModuleGlobals(MODULE_GLOBALS).getSBT();

        if (_exchangePrice[currency].currencyAmount == 0) revert Errors.ExchangePriceIsZero();
        if (msg.value == 0) revert Errors.PaymentError();
        
        address exchangeWallet = payable(msg.sender);
       
        uint256 sbtValue = _exchangePrice[currency].sbtAmount.mul(msg.value).div(_exchangePrice[currency].currencyAmount);

        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        INFTDerivativeProtocolTokenV1(_sbt).transferValue(
            BANK_TREASURY_SOUL_BOUND_TOKENID, 
            soulBoundTokenId, 
            sbtValue
        );

        emit Events.BuySBTByEth(
            soulBoundTokenId, 
            exchangeWallet, 
            msg.value, 
            sbtValue
        );
    }

    function buySBTByERC20(
        uint256 soulBoundTokenId,
        address currency,
        uint256 amount
    ) external whenNotPaused nonReentrant {
        // only called by owner of soulBoundTokenId
        _validateCallerIsSoulBoundTokenOwner(soulBoundTokenId);

        if (!IModuleGlobals(MODULE_GLOBALS).isCurrencyWhitelisted(currency))
            revert Errors.CurrencyNotInWhitelisted(currency);

        if (_exchangePrice[currency].currencyAmount == 0) revert Errors.ExchangePriceIsZero();
        if (amount == 0) revert Errors.AmountIsZero();

        address exchangeWallet = msg.sender;
        uint256 sbtValue = _exchangePrice[currency].sbtAmount.mul(amount).div(_exchangePrice[currency].currencyAmount);
        
        IERC20Upgradeable(currency).safeTransferFrom(exchangeWallet, address(this), amount);

        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        INFTDerivativeProtocolTokenV1(_sbt).transferValue(
            BANK_TREASURY_SOUL_BOUND_TOKENID, 
            soulBoundTokenId, 
            sbtValue
        );

        emit Events.BuySBTByERC20(
            soulBoundTokenId, 
            exchangeWallet, 
            currency,
            amount, 
            sbtValue
        );
    }

    function exchangeERC20BySBT(
        uint256 soulBoundTokenId,
        address currency,
        uint256 amountOfSBT
    ) external payable whenNotPaused nonReentrant {
        // only called by owner of soulBoundTokenId
        _validateCallerIsSoulBoundTokenOwner(soulBoundTokenId);
        if (_exchangePrice[currency].sbtAmount == 0) revert Errors.ExchangePriceIsZero();
        if (amountOfSBT == 0) revert Errors.AmountIsZero();
        if (soulBoundTokenId == 0) revert Errors.SoulBoundTokenIdNotExists();
        if (!IModuleGlobals(MODULE_GLOBALS).isCurrencyWhitelisted(currency))
            revert Errors.CurrencyNotInWhitelisted(currency);

        address payable _to = payable(msg.sender);
       
        INFTDerivativeProtocolTokenV1(currency).transferValue(
            soulBoundTokenId, 
            BANK_TREASURY_SOUL_BOUND_TOKENID, 
            amountOfSBT
        );

        //transfer ERC20 to msg.sender
        uint256 erc20Amount = amountOfSBT.mul(_exchangePrice[currency].currencyAmount).div(_exchangePrice[currency].sbtAmount);

        if (erc20Amount > 0 ) {
            IERC20Upgradeable(currency).safeTransfer(_to, erc20Amount);
        }

        emit Events.ExchangeERC20BySBT(
            soulBoundTokenId, 
            currency, 
            erc20Amount,
            amountOfSBT
        );
    }
       
    function depositFromVoucher(
        uint256 tokenId, 
        uint256 soulBoundTokenId
    ) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        _validateCallerIsSoulBoundTokenOwner(soulBoundTokenId);

        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();

        address _voucher = IModuleGlobals(MODULE_GLOBALS).getVoucher();
   
        uint256 sbtValue = IERC1155Upgradeable(_voucher).balanceOf(msg.sender, tokenId);
        if ( sbtValue == 0) {
            revert Errors.VoucherIsZeroAmount();
        }

        INFTDerivativeProtocolTokenV1(_sbt).transferValue(
            BANK_TREASURY_SOUL_BOUND_TOKENID, 
            soulBoundTokenId, 
            sbtValue
        );
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        tokenIds[0] = tokenId;
        amounts[0] = sbtValue;
         //need approved first
        IERC1155CreatorCore(_voucher).burn(msg.sender, tokenIds, amounts);
 
        emit Events.VoucherDeposited(soulBoundTokenId, msg.sender, tokenId, sbtValue);
    }


    function setExchangePrice(
        address currency,
        uint256 currencyAmount,
        uint256 sbtAmount
    ) 
        external 
        nonReentrant
        onlyGov
    {
       if (!IModuleGlobals(MODULE_GLOBALS).isCurrencyWhitelisted(currency))
            revert Errors.CurrencyNotInWhitelisted(currency);
        if (currencyAmount == 0 || sbtAmount == 0) {
            delete _exchangePrice[currency];
        }else {
            _exchangePrice[currency] = DataTypes.ExchangePrice(
                currencyAmount, 
                sbtAmount
            );
        }

        //Emits
        emit Events.ExchangePriceSet(
            currency, 
            currencyAmount, 
            sbtAmount
        );
    }

    function getExchangePrice(
        address currency
    ) 
        external 
        view
        returns(DataTypes.ExchangePrice memory)
    {
        return  _exchangePrice[currency];
    
    }

    function distributeFundsToUserRevenue(
        uint256 publishId,
        address currency,
        uint96 payValue,
        DataTypes.CollectFeeUsers memory collectFeeUsers,
        DataTypes.RoyaltyAmounts memory royaltyAmounts
    ) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        // valid caller is only have fee module grant role 

        if (!isFeeModule(msg.sender)) {
            revert Errors.Only_Fee_Modules_Allowed();
        }

        unchecked {
            if (payValue != royaltyAmounts.treasuryAmount + 
                            royaltyAmounts.genesisAmount +
                            royaltyAmounts.previousAmount + 
                            royaltyAmounts.referrerAmount +
                            royaltyAmounts.adjustedAmount
                            ) 
            {
                revert Errors.InvalidRoyalties();
            }

            _addBalanceTo(_freeFromEscrow(currency, BANK_TREASURY_SOUL_BOUND_TOKENID), royaltyAmounts.treasuryAmount);
            _addBalanceTo(_freeFromEscrow(currency, collectFeeUsers.genesisSoulBoundTokenId), royaltyAmounts.genesisAmount);
            _addBalanceTo(_freeFromEscrow(currency, collectFeeUsers.previousSoulBoundTokenId), royaltyAmounts.previousAmount);
            _addBalanceTo(_freeFromEscrow(currency, collectFeeUsers.referrerSoulBoundTokenId), royaltyAmounts.referrerAmount);
            //owner or seller
            _addBalanceTo(_freeFromEscrow(currency, collectFeeUsers.ownershipSoulBoundTokenId), royaltyAmounts.adjustedAmount);

             emit Events.Distribute(
                    publishId,
                    currency,
                    uint96(payValue),
                    collectFeeUsers,
                    royaltyAmounts
            );
        }
    }

    function refundEarnestFunds(
        uint256 soulBoundTokenId,
        address currency,
        uint256 amount
    ) 
        external 
        whenNotPaused 
        nonReentrant 
        onlyFoundationMarket 
    {
        _addBalanceTo(_freeFromEscrow(currency, soulBoundTokenId), amount);
    }
 
    function useEarnestFundsForPay(
        uint256 soulBoundTokenId,
        address currency,
        uint256 amount
    ) 
        external 
        whenNotPaused 
        nonReentrant  
        onlyFoundationMarket
    {    
        DataTypes.AccountInfo storage accountInfo = accountToInfo[soulBoundTokenId][currency];
        _deductBalanceFrom(accountInfo, amount);
    }

    function marketLockupFor(
        address account,
        uint256 soulBoundTokenId,
        address currency,
        uint256 amount
    ) external whenNotPaused nonReentrant onlyFoundationMarket returns (uint256 expiration) {

        return _marketLockupFor(account, soulBoundTokenId, currency, amount);
    }
 
    function marketChangeLockup(
        uint256 unlockFromSoulBoundTokenId,
        address currency,
        uint256 unlockExpiration,
        uint256 unlockAmount,
        uint256 lockupForSoulBoundTokenId,
        uint256 lockupAmount
    ) external whenNotPaused nonReentrant onlyFoundationMarket returns (uint256 expiration) {

        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        address unlockFrom = IERC3525(_sbt).ownerOf(unlockFromSoulBoundTokenId);
        address lockupFor = IERC3525(_sbt).ownerOf(lockupForSoulBoundTokenId);
        _marketUnlockFor(unlockFrom, unlockFromSoulBoundTokenId, unlockExpiration, currency, unlockAmount);

        return _marketLockupFor(lockupFor, lockupForSoulBoundTokenId, currency, lockupAmount);
    }


    function marketTransferLocked(
        address account,
        uint256 soulBoundTokenIdBuyer,
        address owner,
        uint256 soulBoundTokenIdOwner,
        uint256 expiration,
        address currency,
        uint256 totalAmount
    ) external whenNotPaused nonReentrant onlyFoundationMarket {
        _removeFromLockedBalance(account, soulBoundTokenIdBuyer, expiration, currency, totalAmount);
        
        emit Events.OfferTransfered(
            account, 
            soulBoundTokenIdBuyer, 
            owner, 
            soulBoundTokenIdOwner, 
            currency,
            totalAmount
        );
    }

    function marketUnlockFor(
        address account,
        uint256 soulBoundTokenId,
        uint256 expiration,
        address currency,
        uint256 amount
    ) external whenNotPaused nonReentrant onlyFoundationMarket {
        _marketUnlockFor(account, soulBoundTokenId, expiration, currency, amount);
    }

    //--- internal  ---//
    function _setGovernance(address newGovernance) internal {
        _governance = newGovernance;
    }

    function _setFoundationMarket(address payable newFoundationMarket) internal {
        _foundationMarket = newFoundationMarket;
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }

    function _validateCallerIsSigner() internal view {
        if (!_isSigner[msg.sender]) revert Errors.NotSinger();
    }

    function _validateTxExists(uint256 _txIndex) internal view {
        if (_txIndex >= _transactions.length) revert Errors.TxNotExists();
    }

    function _validateNotExecuted(uint256 _txIndex) internal view {
        if (_transactions[_txIndex].executed) revert Errors.TxAlreadyExecuted();
    }

    function _validateNotConfirmed(uint256 _txIndex) internal view {
        if (_isConfirmed[_txIndex][msg.sender]) revert Errors.TxAlreadyConfirmed();
    }

    //-- orverride -- //
    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert Errors.Unauthorized();
    }

    /**
     * @notice Lockup an account's earnest funds for 24-25 hours.
     */
    /* solhint-disable-next-line code-complexity */
    function _marketLockupFor(address account, uint256 soulBoundTokenId, address currency, uint256 amount) private returns (uint256 expiration) {
        if (soulBoundTokenId == 0) {
            revert Errors.Cannot_Deposit_For_Lockup_With_SoulBoundTokenId_Zero();
        }
        if (amount == 0) {
            revert Errors.Must_Lockup_Non_Zero_Amount();
        }

        // Block timestamp in seconds is small enough to never overflow
        unchecked {
            // Lockup expires after 24 hours, rounded up to the next hour for a total of [24-25) hours
            expiration = lockupDuration + block.timestamp.ceilDiv(lockupInterval) * lockupInterval;
        }

        // Update available escrow
        // Always free from escrow to ensure the max bucket count is <= 25
        DataTypes.AccountInfo storage accountInfo = _freeFromEscrow(currency, soulBoundTokenId);

        // Add to locked escrow
        unchecked {
            // The number of buckets is always < 256 bits.
            for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
                LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
                if (escrow.expiration == 0) {
                    if (expiration > type(uint32).max) {
                        revert Errors.Expiration_Too_Far_In_Future();
                    }

                    // Amount of currency will always be < 96 bits.
                    accountInfo.lockups.set(escrowIndex, expiration, amount);
                    break;
                }
                if (escrow.expiration == expiration) {
                    // Total currency value will always be < 96 bits.
                    accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount + amount);
                    break;
                }
            }

            //deduct earnest funds 
            _deductBalanceFrom(_freeFromEscrow(currency, soulBoundTokenId), amount);


        }

        emit Events.BalanceLocked(
            account, 
            soulBoundTokenId, 
            expiration, 
            currency,
            amount
        );
    }

    /**
     * @dev Removes an amount from the account's available earnest funds.
     */
    function _deductBalanceFrom(DataTypes.AccountInfo storage accountInfo, uint256 amount) private {
        uint96 freedBalance = accountInfo.freedBalance;
        // Free from escrow in order to consider any expired escrow balance
        if (freedBalance < amount) {
            revert Errors.Insufficient_Available_Funds(freedBalance);
        }
        // The check above ensures balance cannot underflow.
        unchecked {
            accountInfo.freedBalance = freedBalance - uint96(amount);
        }
    }

    /**
     * @dev Add an amount to the account's available earnest funds.
     */
    function _addBalanceTo(DataTypes.AccountInfo storage accountInfo, uint256 amount) private {
        unchecked {
            accountInfo.freedBalance += uint96(amount);
        }
    }

    /**
     * @dev Moves expired escrow to the available balance.
     * Sets the next bucket that hasn't expired as the new start index.
     */
    function _freeFromEscrow(address currency, uint256 soulBoundTokenId) private returns (DataTypes.AccountInfo storage) {
        DataTypes.AccountInfo storage accountInfo = accountToInfo[soulBoundTokenId][currency];
        uint256 escrowIndex = accountInfo.lockupStartIndex;
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);

        // If the first bucket (the oldest) is empty or not yet expired, no change to escrowStartIndex is required
        if (escrow.expiration == 0 || escrow.expiration >= block.timestamp) {
            return accountInfo;
        }

        while (true) {
            // Total value cannot realistically overflow 96 bits.
            unchecked {
                accountInfo.freedBalance += escrow.totalAmount;
                accountInfo.lockups.del(escrowIndex);
                // Escrow index cannot overflow 32 bits.
                escrow = accountInfo.lockups.get(escrowIndex + 1);
            }

            // If the next bucket is empty, the start index is set to the previous bucket
            if (escrow.expiration == 0) {
                break;
            }

            // Escrow index cannot overflow 32 bits.
            unchecked {
                // Increment the escrow start index if the next bucket is not empty
                ++escrowIndex;
            }

            // If the next bucket is expired, that's the new start index
            if (escrow.expiration >= block.timestamp) {
                break;
            }
        }

        // Escrow index cannot overflow 32 bits.
        unchecked {
            accountInfo.lockupStartIndex = uint32(escrowIndex);
        }
        return accountInfo;
    }

    /**
     * @notice Remove an soulBoundTokenId's lockup, making the earnest funds available for transfer or withdrawal.
     */
    function _marketUnlockFor(address account, uint256 soulBoundTokenId, uint256 expiration, address currency, uint256 amount) private {
        DataTypes.AccountInfo storage accountInfo = _removeFromLockedBalance(account, soulBoundTokenId, expiration, currency, amount);
        // Total value cannot realistically overflow 96 bits.
        unchecked {
            accountInfo.freedBalance += uint96(amount);
        }
    }

    /**
     * @dev Removes the specified amount from locked escrow, potentially before its expiration.
     */
    /* solhint-disable-next-line code-complexity */
    function _removeFromLockedBalance(
        address account,
        uint256 soulBoundTokenId,
        uint256 expiration,
        address currency,
        uint256 amount
    ) private returns (DataTypes.AccountInfo storage) {
        if (expiration < block.timestamp) {
            revert Errors.Escrow_Expired();
        }

        DataTypes.AccountInfo storage accountInfo = accountToInfo[soulBoundTokenId][currency];
        uint256 escrowIndex = accountInfo.lockupStartIndex;
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);

        if (escrow.expiration == expiration) {
            // If removing from the first bucket, we may be able to delete it
            if (escrow.totalAmount == amount) {
                accountInfo.lockups.del(escrowIndex);

                // Bump the escrow start index unless it's the last one
                unchecked {
                    if (accountInfo.lockups.get(escrowIndex + 1).expiration != 0) {
                        // The number of escrow buckets will never overflow 32 bits.
                        ++accountInfo.lockupStartIndex;
                    }
                }
            } else {
                if (escrow.totalAmount < amount) {
                    revert Errors.Insufficient_Escrow(escrow.totalAmount);
                }
                // The require above ensures balance will not underflow.
                unchecked {
                    accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount - amount);
                }
            }
        } else {
            // Removing from the 2nd+ bucket
            while (true) {
                // The number of escrow buckets will never overflow 32 bits.
                unchecked {
                    ++escrowIndex;
                }
                escrow = accountInfo.lockups.get(escrowIndex);
                if (escrow.expiration == expiration) {
                    if (amount > escrow.totalAmount) {
                        revert Errors.Insufficient_Escrow(escrow.totalAmount);
                    }
                    // The require above ensures balance will not underflow.
                    unchecked {
                        accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount - amount);
                    }
                    // We may have an entry with 0 totalAmount but expiration will be set
                    break;
                }
                if (escrow.expiration == 0) {
                    revert Errors.Escrow_Not_Found();
                }
            }
        }

        emit Events.BalanceUnlocked(
            account, 
            soulBoundTokenId, 
            expiration, 
            currency,
            amount
        );

        return accountInfo;
    }

    function _validateCallerIsSoulBoundTokenOwner(uint256 soulBoundTokenId_) internal view {
        if (MODULE_GLOBALS == address(0)) revert Errors.ModuleGlobasNotSet();
        
         address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();

         if (IERC3525(_sbt).ownerOf(soulBoundTokenId_) == msg.sender) {
            return;
         }

         revert Errors.NotProfileOwner();
    }

}
  