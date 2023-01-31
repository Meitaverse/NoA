import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    Deposit,
    DepositByFallback,
    ERC3525Received,
    ExchangeSBTByEth,
    ExchangeEthBySBT,
    ExchangeVoucher,
    SubmitTransaction,
    ConfirmTransaction,
    ExecuteTransaction,
    ExecuteTransactionERC3525,
    RevokeConfirmation,
    BalanceLocked,
    BalanceUnlocked,
    OfferWithdrawn,
    WithdrawnEarnestMoney
} from "../generated/BankTreasury/Events"

import {
    SBT
} from "../generated/BankTreasury/SBT"

import {
    BankTreasury
} from "../generated/BankTreasury/BankTreasury"

import {
    DepositHistory,
    ERC3525ReceivedHistory,
    ExchangeSBTByEthHistory,
    ExchangeEthBySBTHistory,
    Transaction,
    ExecuteTransactionHistory,
    ExecuteTransactionERC3525History,
    ExchangeVoucherHistory,
} from "../generated/schema"

export function handleDeposit(event: Deposit): void {
    log.info("handleDeposit, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.sender.toHexString()+ "-" + event.block.timestamp.toString()
    const history = DepositHistory.load(_idString) || new DepositHistory(_idString)
    if (history) {
        history.sender = event.params.sender
        history.amount = event.params.amount
        history.receiver = event.params.receiver
        history.balance = event.params.balance
        history.timestamp = event.block.timestamp
        history.save()
    } 
}
import { loadOrCreateAccount } from "./shared/accounts";
import { toETH } from "./shared/conversions";
import { BASIS_POINTS, ONE_BIG_INT, ZERO_ADDRESS_STRING, ZERO_BIG_DECIMAL, ZERO_BIG_INT } from "./shared/constants"; 
import { loadOrCreateFsbt, loadOrCreateFsbtEscrow } from "./shared/fsbt";
import { loadOrCreateSBTAsset } from "./shared/sbtAsset";
import { loadOrCreateSoulBoundToken } from "./shared/soulBoundToken";
import { ZERO_ADDRESS } from "../../test/helpers/constants";

export function handleDepositByFallback(event: DepositByFallback): void {
    log.info("handleDepositByFallback, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.sender.toHexString()+ "-" + event.block.timestamp.toString()
    const history = DepositHistory.load(_idString) || new DepositHistory(_idString)
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

export function handleERC3525Received(event: ERC3525Received): void {
    log.info("handleERC3525Received, event.address: {}", [event.address.toHexString()])

    const sbtFrom = loadOrCreateSoulBoundToken(event.params.fromTokenId)
    const sbtTo = loadOrCreateSoulBoundToken(event.params.fromTokenId)

    if (sbtFrom.wallet.toHex() != ZERO_ADDRESS &&  
        sbtTo.wallet.toHex() != ZERO_ADDRESS
        ) {
        let _idString = event.params.operator.toHexString()+ "-" + event.params.fromTokenId.toString() + "-" + event.block.timestamp.toString()
        const history = ERC3525ReceivedHistory.load(_idString) || new ERC3525ReceivedHistory(_idString)
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
        } 
    }
}

export function handleExchangeSBTByEth(event: ExchangeSBTByEth): void {
    log.info("handleExchangeSBTByEth, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString()+ "-" + event.params.exchangeWallet.toHexString() + "-" + event.params.timestamp.toString()
    const history = ExchangeSBTByEthHistory.load(_idString) || new ExchangeSBTByEthHistory(_idString)
    if (history) {
        const sbtAccount = loadOrCreateSoulBoundToken(event.params.soulBoundTokenId)
    
        if (sbtAccount.wallet.toHex() != ZERO_ADDRESS ) {
            history.account = loadOrCreateAccount(Address.fromBytes(sbtAccount.wallet)).id
            history.exchangeWallet = event.params.exchangeWallet
            history.sbtValue       = event.params.sbtValue
            history.timestamp      = event.params.timestamp
            history.save()
        }
    } 
}

export function handleExchangeEthBySBT(event: ExchangeEthBySBT): void {
    log.info("handleExchangeEthBySBT, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString()+ "-" + event.params.toWallet.toHexString() + "-" + event.params.timestamp.toString()
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

export function handleExchangeVoucher(event: ExchangeVoucher): void {
    log.info("handleExchangeVoucher, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString()+ "-" + event.params.operator.toHexString() + "-" + event.params.timestamp.toString()
    const history = ExchangeVoucherHistory.load(_idString) || new ExchangeVoucherHistory(_idString)
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
    let fsbtTo = loadOrCreateFsbt(to, event.block);
    fsbtTo.balanceInSBTValue = fsbtTo.balanceInSBTValue.plus(toETH(event.params.valueDeposited));
    fsbtTo.dateLastUpdated = event.block.timestamp;
    fsbtTo.save();
    let escrow = loadOrCreateFsbtEscrow(event, to);
    if (escrow.dateRemoved) {
      escrow.amountInSBTValue = toETH(event.params.amount);
      escrow.dateRemoved = null;
      escrow.transactionHashRemoved = null;
    } else {
      escrow.amountInSBTValue = escrow.amountInSBTValue.plus(toETH(event.params.amount));
    }
  
    escrow.dateExpiry = event.params.expiration;
    escrow.transactionHashCreated = event.transaction.hash;
    escrow.save();
  }
  
  export function handleBalanceUnlocked(event: BalanceUnlocked): void {
    log.info("handleBalanceUnlocked, event.address: {}", [event.address.toHexString()])
    let from = loadOrCreateAccount(event.params.account);
    let escrow = loadOrCreateFsbtEscrow(event, from);
    escrow.amountInSBTValue = escrow.amountInSBTValue.minus(toETH(event.params.amount));
    if (escrow.amountInSBTValue.equals(ZERO_BIG_DECIMAL)) {
      escrow.transactionHashRemoved = event.transaction.hash;
      escrow.dateRemoved = event.block.timestamp;
    }
    escrow.save();
  }

  export function handleOfferWithdrawn(event: OfferWithdrawn): void {
    log.info("handleOfferWithdrawn, event.address: {}", [event.address.toHexString()])
   
    let from = loadOrCreateAccount(event.params.owner);
    let fsbtFrom = loadOrCreateFsbt(from, event.block);
    fsbtFrom.balanceInSBTValue = fsbtFrom.balanceInSBTValue.minus(toETH(event.params.amount));
    fsbtFrom.dateLastUpdated = event.block.timestamp;
    fsbtFrom.save();

    let buyer = loadOrCreateAccount(event.params.buyer);
    let fsbtBuyer = loadOrCreateFsbt(buyer, event.block);
    fsbtBuyer.balanceInSBTValue = fsbtBuyer.balanceInSBTValue.plus(toETH(event.params.amount));
    fsbtBuyer.dateLastUpdated = event.block.timestamp;
    fsbtBuyer.save();
  }
  
  export function handleWithdrawnEarnestMoney(event: WithdrawnEarnestMoney): void {
    log.info("handleWithdrawnEarnestMoney, event.address: {}", [event.address.toHexString()])
    
    const sbtAsset_withdrawer = loadOrCreateSBTAsset(event.params.to);
    sbtAsset_withdrawer.balance = sbtAsset_withdrawer.balance.plus(event.params.value);
    sbtAsset_withdrawer.save();
  }
