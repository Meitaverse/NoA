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

} from "../generated/BankTreasury/Events"

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

    let _idString = event.params.operator.toHexString()+ "-" + event.params.fromTokenId.toString() + "-" + event.block.timestamp.toString()
    const history = ERC3525ReceivedHistory.load(_idString) || new ERC3525ReceivedHistory(_idString)
    if (history) {
        history.operator = event.params.operator
        history.fromTokenId = event.params.fromTokenId
        history.toTokenId = event.params.toTokenId
        history.value = event.params.value
        history.data = event.params.data
        history.gas = event.params.gas
        history.timestamp = event.block.timestamp
        history.save()
    } 
}

export function handleExchangeSBTByEth(event: ExchangeSBTByEth): void {
    log.info("handleExchangeSBTByEth, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString()+ "-" + event.params.exchangeWallet.toHexString() + "-" + event.params.timestamp.toString()
    const history = ExchangeSBTByEthHistory.load(_idString) || new ExchangeSBTByEthHistory(_idString)
    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.exchangeWallet = event.params.exchangeWallet
        history.sbtValue       = event.params.sbtValue
        history.timestamp      = event.params.timestamp
        history.save()
    } 
}


export function handleExchangeEthBySBT(event: ExchangeEthBySBT): void {
    log.info("handleExchangeEthBySBT, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString()+ "-" + event.params.toWallet.toHexString() + "-" + event.params.timestamp.toString()
    const history = ExchangeEthBySBTHistory.load(_idString) || new ExchangeEthBySBTHistory(_idString)
    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.toWallet = event.params.toWallet
        history.sbtValue = event.params.sbtValue
        history.exchangePrice = event.params.exchangePrice
        history.ethAmount = event.params.ethAmount
        history.timestamp = event.params.timestamp
        history.save()
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
