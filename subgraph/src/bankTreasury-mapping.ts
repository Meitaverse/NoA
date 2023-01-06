import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    ERC3525Received,
} from "../generated/BankTreasury/Events"

import {
    ERC3525ReceivedHistory,
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

  