import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    FeesForCollect,
} from "../generated/FeeCollectModule/Events"

import {
    FeesForCollectHistory,
} from "../generated/schema"

export function handleFeesForCollect(event: FeesForCollect): void {
    log.info("handleFeesForCollect, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.collectorSoulBoundTokenId.toString() + "-" +  event.block.timestamp.toString()
    const history = FeesForCollectHistory.load(_idString) || new FeesForCollectHistory(_idString)

    if (history) {
        history.collectorSoulBoundTokenId = event.params.collectorSoulBoundTokenId
        history.publishId = event.params.publishId
        history.treasuryAmount = event.params.treasuryAmount
        history.genesisAmount = event.params.genesisAmount
        history.adjustedAmount = event.params.adjustedAmount
        history.timestamp = event.block.timestamp
        history.save()
        
    } 
}
