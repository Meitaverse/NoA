import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    DepositEther,
    DepositByFallback,
    SBTValueReceived,
    Deposit,
    BuySBTByEth,
    BuySBTByERC20,
    // ExchangeEthBySBT,
    VoucherDeposited,
    SubmitTransaction,
    ConfirmTransaction,
    ExecuteTransaction,
    ExecuteTransactionERC3525,
    RevokeConfirmation,
    BalanceLocked,
    BalanceUnlocked,
    OfferTransfered,
    WithdrawnEarnestFunds,
    Distribute
} from "../generated/BankTreasury/Events"

import {
    SBT
} from "../generated/BankTreasury/SBT"

import {
    BankTreasury
} from "../generated/BankTreasury/BankTreasury"

import {
    DepositEtherHistory,
    SBTValueReceivedHistory,
    DepositHistory,
    BuySBTByEthHistory,
    BuySBTByERC20History,
    ExchangeEthBySBTHistory,
    Transaction,
    ExecuteTransactionHistory,
    ExecuteTransactionERC3525History,
    VoucherDepositedHistory,
    ProtocolContract,
    DistributeHistory,
} from "../generated/schema"

import { loadOrCreateAccount } from "./shared/accounts";
import { toETH } from "./shared/conversions";
import { BASIS_POINTS, ONE_BIG_INT, ZERO_ADDRESS_STRING, ZERO_BIG_INT } from "./shared/constants"; 
import { loadOrCreateCurrencyEarnestFunds, loadOrCreateFsbtEscrow } from "./shared/currencyEarnestFunds";
import { loadOrCreateSoulBoundToken } from "./shared/soulBoundToken";
import { ZERO_ADDRESS } from "../../test/helpers/constants";
import { getLogId } from "./shared/ids";
import { loadOrCreatePublish } from "./shared/publish";


export function handleDepositEther(event: DepositEther): void {
    log.info("handleDepositEther, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = DepositEtherHistory.load(_idString) || new DepositEtherHistory(_idString)
    if (history) {
        history.sender = event.params.account
        history.amount = event.params.amount
        history.receiver = event.params.receiver
        history.balance = event.params.balance
        history.timestamp = event.block.timestamp
        history.save()
    }
}

export function handleDepositByFallback(event: DepositByFallback): void {
    log.info("handleDepositByFallback, event.address: {}", [event.address.toHexString()])

    let _idString =  getLogId(event)
    const history = DepositEtherHistory.load(_idString) || new DepositEtherHistory(_idString)
    if (history) {
        history.sender = event.params.sender
        history.amount = event.params.amount
        history.receiver = event.params.receiver
        history.balance = event.params.balance
        history.data = event.params.data
        history.timestamp = event.block.timestamp
        history.save()
    } 
}

export function handleSBTValueReceived(event: SBTValueReceived): void {
    log.info("handleSBTValueReceived, event.address: {}", [event.address.toHexString()])

    const sbtFrom = loadOrCreateSoulBoundToken(event.params.fromTokenId)
    const sbtTo = loadOrCreateSoulBoundToken(event.params.toTokenId)

    if (sbtFrom.wallet.toHex() != ZERO_ADDRESS &&  
            sbtTo.wallet.toHex() != ZERO_ADDRESS
        ) {
        let _idString =  getLogId(event)
        const history = SBTValueReceivedHistory.load(_idString) || new SBTValueReceivedHistory(_idString)
        if (history) {
            history.sender = event.params.sender
            history.operator = event.params.operator
            history.from = loadOrCreateAccount(Address.fromBytes(sbtFrom.wallet)).id
            history.to = loadOrCreateAccount(Address.fromBytes(sbtTo.wallet)).id
            history.value = event.params.value
            history.data = event.params.data
            history.gas = event.params.gas
            history.timestamp = event.block.timestamp
            history.save()

            let _id = "SBT"
            const protocolContract = ProtocolContract.load(_id)
            if (protocolContract) {
                let user = loadOrCreateAccount(Address.fromBytes(sbtFrom.wallet))
                let earnestFunds = loadOrCreateCurrencyEarnestFunds(Address.fromBytes(protocolContract.contract), user, event.block)
                if (earnestFunds) {
                    earnestFunds.user = user.id
                    earnestFunds.currency = Address.fromBytes(protocolContract.contract)
                    earnestFunds.balance = earnestFunds.balance.plus(event.params.value)
                    earnestFunds.dateLastUpdated = event.block.timestamp;
                }
            }
        } 
    }
}

export function handleDeposit(event: Deposit): void {
    log.info("handleDeposit, event.address: {}", [event.address.toHexString()])

    let _idString =  getLogId(event)
    const history = DepositHistory.load(_idString) || new DepositHistory(_idString)
    if (history) {
        history.account = loadOrCreateAccount(event.params.account).id
        history.currency = event.params.currency
        history.amount = event.params.amount
        history.timestamp = event.block.timestamp
        history.save()
       
        let account = loadOrCreateAccount(event.params.account)
        let earnestFunds = loadOrCreateCurrencyEarnestFunds(event.params.currency, account, event.block)
        if (earnestFunds) {
            earnestFunds.user = account.id
            earnestFunds.currency = event.params.currency
            earnestFunds.balance = earnestFunds.balance.plus(event.params.amount)
            earnestFunds.dateLastUpdated = event.block.timestamp;
        }
    } 
}

export function handleBuySBTByEth(event: BuySBTByEth): void {
    log.info("handleBuySBTByEth, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = BuySBTByEthHistory.load(_idString) || new BuySBTByEthHistory(_idString)
    if (history) {
        const sbtAccount = loadOrCreateSoulBoundToken(event.params.soulBoundTokenId)
    
        if (sbtAccount.wallet.toHex() != ZERO_ADDRESS ) {
            history.account = loadOrCreateAccount(Address.fromBytes(sbtAccount.wallet)).id
            history.exchangeWallet = event.params.exchangeWallet
            history.sbtValue       = event.params.sbtValue
            history.timestamp      = event.block.timestamp
            history.save()
        }
    } 
}

export function handleBuySBTByERC20(event: BuySBTByERC20): void {
    log.info("handleBuySBTByERC20, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = BuySBTByERC20History.load(_idString) || new BuySBTByERC20History(_idString)
    if (history) {
        const sbtAccount = loadOrCreateSoulBoundToken(event.params.soulBoundTokenId)
    
        if (sbtAccount.wallet.toHex() != ZERO_ADDRESS ) {
            history.account = loadOrCreateAccount(Address.fromBytes(sbtAccount.wallet)).id
            history.exchangeWallet = event.params.exchangeWallet
            history.sbtValue       = event.params.sbtValue
            history.timestamp      = event.block.timestamp
            history.save()
        }
    } 
}

/*
export function handleExchangeEthBySBT(event: ExchangeEthBySBT): void {
    log.info("handleExchangeEthBySBT, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = ExchangeEthBySBTHistory.load(_idString) || new ExchangeEthBySBTHistory(_idString)
    if (history) {

        const sbtAccount = loadOrCreateSoulBoundToken(event.params.soulBoundTokenId)

        if (sbtAccount.wallet.toHex() != ZERO_ADDRESS ) {
            history.account =  loadOrCreateAccount(Address.fromBytes(sbtAccount.wallet)).id
            history.toWallet = event.params.toWallet
            history.sbtValue = event.params.sbtValue
            history.exchangePrice = event.params.exchangePrice
            history.ethAmount = event.params.ethAmount
            history.timestamp = event.params.timestamp
            history.save()
        }
    } 
}
*/

export function handleVoucherDeposited(event: VoucherDeposited): void {
    log.info("handleVoucherDeposited, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = VoucherDepositedHistory.load(_idString) || new VoucherDepositedHistory(_idString)
    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.operator = event.params.operator
        history.tokenId = event.params.tokenId
        history.sbtValue = event.params.sbtValue
        history.timestamp = event.params.timestamp
        history.save()
    } 
}


export function handleSubmitTransaction(event: SubmitTransaction): void {
    log.info("handleSubmitTransaction, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.owner.toHexString()+ "-" + event.params.txIndex.toString()
    const transaction = Transaction.load(_idString) || new Transaction(_idString)
    if (transaction) {
        transaction.owner = event.params.owner
        transaction.txIndex = event.params.txIndex
        transaction.to = event.params.to
        transaction.value = event.params.value
        transaction.data = event.params.data
        transaction.isConfirmed = true
        transaction.timestamp = event.block.timestamp
        transaction.save()
    } 
}

export function handleConfirmTransaction(event: ConfirmTransaction): void {
    log.info("handleConfirmTransaction, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.owner.toHexString()+ "-" + event.params.txIndex.toString()
    const transaction = Transaction.load(_idString) || new Transaction(_idString)
    if (transaction) {
        transaction.owner = event.params.owner
        transaction.txIndex = event.params.txIndex
        transaction.isConfirmed = true
        transaction.timestamp = event.block.timestamp
        transaction.save()
    } 
}

export function handleRevokeConfirmation(event: RevokeConfirmation): void {
    log.info("handleRevokeConfirmation, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.owner.toHexString()+ "-" + event.params.txIndex.toString()
    const transaction = Transaction.load(_idString)
    if (transaction) {
        transaction.isConfirmed = false
        transaction.timestamp = event.block.timestamp
        transaction.save()
    }
}

export function handleExecuteTransaction(event: ExecuteTransaction): void {
    log.info("handleExecuteTransaction, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.owner.toHexString()+ "-" + event.params.txIndex.toString()
    const history = ExecuteTransactionHistory.load(_idString) || new ExecuteTransactionHistory(_idString)
    if (history) {
        history.owner = event.params.owner
        history.txIndex = event.params.txIndex
        history.to = event.params.to
        history.value = event.params.value
        history.timestamp = event.block.timestamp
        history.save()
    } 
}

export function handleExecuteTransactionERC3525(event: ExecuteTransactionERC3525): void {
    log.info("handleExecuteTransactionERC3525, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.owner.toHexString()+ "-" + event.params.txIndex.toString()
    const history = ExecuteTransactionERC3525History.load(_idString) || new ExecuteTransactionERC3525History(_idString)
    if (history) {
        history.owner = event.params.owner
        history.txIndex = event.params.txIndex
        history.fromTokenId = event.params.fromTokenId
        history.toTokenId = event.params.toTokenId
        history.value = event.params.value
        history.timestamp = event.block.timestamp
        history.save()
    } 
}

export function handleBalanceLocked(event: BalanceLocked): void {
    log.info("handleBalanceLocked, event.address: {}", [event.address.toHexString()])

    let to = loadOrCreateAccount(event.params.account);
    let earnestFundsTo = loadOrCreateCurrencyEarnestFunds(event.params.currency, to, event.block);
    
    earnestFundsTo.balance = earnestFundsTo.balance.plus(event.params.amount);
    earnestFundsTo.dateLastUpdated = event.block.timestamp;
    earnestFundsTo.save();

    let escrow = loadOrCreateFsbtEscrow(event, event.params.currency, to);
    if (escrow.dateRemoved) {
      escrow.amount = event.params.amount;
      escrow.dateRemoved = null;
      escrow.transactionHashRemoved = null;
    } else {
      escrow.amount = escrow.amount.plus(event.params.amount);
    }
  
    escrow.dateExpiry = event.params.expiration;
    escrow.transactionHashCreated = event.transaction.hash;
    escrow.save();
  }
  
  export function handleBalanceUnlocked(event: BalanceUnlocked): void {
    log.info("handleBalanceUnlocked, event.address: {}", [event.address.toHexString()])
    let from = loadOrCreateAccount(event.params.account);
    let escrow = loadOrCreateFsbtEscrow(event, event.params.currency, from);
    escrow.amount = escrow.amount.minus(event.params.amount);
    if (escrow.amount.equals(ZERO_BIG_INT)) {
      escrow.transactionHashRemoved = event.transaction.hash;
      escrow.dateRemoved = event.block.timestamp;
    }
    escrow.save();
  }

  export function handleOfferTransfered(event: OfferTransfered): void {
    log.info("handleOfferTransfered, event.address: {}", [event.address.toHexString()])
   
    let from = loadOrCreateAccount(event.params.owner);
    let earnestFundsFrom = loadOrCreateCurrencyEarnestFunds(event.params.currency, from, event.block);
    earnestFundsFrom.balance = earnestFundsFrom.balance.minus(event.params.amount);
    earnestFundsFrom.dateLastUpdated = event.block.timestamp;
    earnestFundsFrom.save();

    let buyer = loadOrCreateAccount(event.params.buyer);
    let currencyEarnestFundsBuyer = loadOrCreateCurrencyEarnestFunds(event.params.currency, buyer, event.block);
    currencyEarnestFundsBuyer.balance = currencyEarnestFundsBuyer.balance.plus(event.params.amount);
    currencyEarnestFundsBuyer.dateLastUpdated = event.block.timestamp;
    currencyEarnestFundsBuyer.save();
  }
  
  export function handleWithdrawnEarnestFunds(event: WithdrawnEarnestFunds): void {
    log.info("handleWithdrawnEarnestFunds, event.address: {}", [event.address.toHexString()])

    let to = loadOrCreateAccount(event.params.to);
    let earnestFundsFrom = loadOrCreateCurrencyEarnestFunds(event.params.currency, to, event.block);
    earnestFundsFrom.balance = earnestFundsFrom.balance.minus(event.params.amount);
    earnestFundsFrom.dateLastUpdated = event.block.timestamp;
    earnestFundsFrom.save();


  }


export function handleDistribute(event: Distribute): void {
    log.info("handleDistribute, event.address: {}", [event.address.toHexString()])

    let owner : Address = Address.zero();
    let collector : Address = Address.zero();
    let genesisCreator : Address = Address.zero();
    let previousCreator : Address = Address.zero();
    let referrer : Address = Address.zero();

    if (!event.params.collectFeeUsers.ownershipSoulBoundTokenId.isZero()) {
        const sbtOwner = loadOrCreateSoulBoundToken(event.params.collectFeeUsers.ownershipSoulBoundTokenId)
        if (sbtOwner.wallet.toHex() != ZERO_ADDRESS ) {
            owner = Address.fromBytes(sbtOwner.wallet)
        }
    }
   
    if (!event.params.collectFeeUsers.collectorSoulBoundTokenId.isZero()) {
        const sbtCollector = loadOrCreateSoulBoundToken(event.params.collectFeeUsers.collectorSoulBoundTokenId)
        if (sbtCollector.wallet.toHex() != ZERO_ADDRESS ) {
            collector = Address.fromBytes(sbtCollector.wallet)
        }
    }
   
    if (!event.params.collectFeeUsers.genesisSoulBoundTokenId.isZero()) {
        const sbtGenesisCreator = loadOrCreateSoulBoundToken(event.params.collectFeeUsers.genesisSoulBoundTokenId)
        if (sbtGenesisCreator.wallet.toHex() != ZERO_ADDRESS ) {
            genesisCreator = Address.fromBytes(sbtGenesisCreator.wallet)
        }
    }

    if (!event.params.collectFeeUsers.previousSoulBoundTokenId.isZero()) {
        const sbtPreviousCreator = loadOrCreateSoulBoundToken(event.params.collectFeeUsers.previousSoulBoundTokenId)
        if (sbtPreviousCreator.wallet.toHex() != ZERO_ADDRESS ) {
            previousCreator = Address.fromBytes(sbtPreviousCreator.wallet)
        }
    }

    if (!event.params.collectFeeUsers.referrerSoulBoundTokenId.isZero()) {
        const sbtReferrer = loadOrCreateSoulBoundToken(event.params.collectFeeUsers.referrerSoulBoundTokenId)
        if (sbtReferrer.wallet.toHex() != ZERO_ADDRESS ) {
            referrer = Address.fromBytes(sbtReferrer.wallet)
        }
    }

    let _idString =  getLogId(event)
    const history = DistributeHistory.load(_idString) || new DistributeHistory(_idString)

    if (history) {
        history.owner = loadOrCreateAccount(owner).id
        history.publish = loadOrCreatePublish(event.params.publishId).id
        history.payValue = event.params.payValue
        history.collector = loadOrCreateAccount(collector).id
        history.genesisCreator = loadOrCreateAccount(genesisCreator).id
        history.previousCreator = loadOrCreateAccount(previousCreator).id
        history.referrer = loadOrCreateAccount(referrer).id
        history.treasuryAmount = event.params.royaltyAmounts.treasuryAmount
        history.genesisAmount = event.params.royaltyAmounts.genesisAmount
        history.previousAmount = event.params.royaltyAmounts.previousAmount
        history.referrerAmount = event.params.royaltyAmounts.referrerAmount
        history.adjustedAmount = event.params.royaltyAmounts.adjustedAmount
        history.timestamp = event.block.timestamp
        history.save()
    }
  
}
