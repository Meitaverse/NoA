import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    ReceiverReceived,
} from "../generated/Receiver/Events"

import {
    ReceiverReceivedHistory,
} from "../generated/schema"
import { getLogId } from "./shared/ids";

export function handleReceiverReceived(event: ReceiverReceived): void {
    log.info("handleReceiverReceived, event.address: {}", [event.address.toHexString()])

    let _idString =  getLogId(event)
    const history = ReceiverReceivedHistory.load(_idString) || new ReceiverReceivedHistory(_idString)

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
