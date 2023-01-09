import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    ERC3525Received,
    ExchangeSBTByEth,
    ExchangeEthBySBT
} from "../generated/BankTreasury/Events"

import {
    ERC3525ReceivedHistory,
    ExchangeSBTByEthHistory,
    ExchangeEthBySBTHistory,
} from "../generated/schema"

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


  