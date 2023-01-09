import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    FeesForCollect,
} from "../generated/FeeCollectModule/Events"

import {
    FeesForCollectHistory,
} from "../generated/schema"

export function handleFeesForCollect(event: FeesForCollect): void {
    log.info("handleFeesForCollect, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.collectFeeUsers.collectorSoulBoundTokenId.toString() + "-" +  event.block.timestamp.toString()
    const history = FeesForCollectHistory.load(_idString) || new FeesForCollectHistory(_idString)

    if (history) {
        history.ownershipSoulBoundTokenId = event.params.collectFeeUsers.ownershipSoulBoundTokenId
        history.collectorSoulBoundTokenId = event.params.collectFeeUsers.collectorSoulBoundTokenId
        history.genesisSoulBoundTokenId = event.params.collectFeeUsers.genesisSoulBoundTokenId
        history.previousSoulBoundTokenId = event.params.collectFeeUsers.previousSoulBoundTokenId
        history.publishId = event.params.publishId
        history.treasuryAmount = event.params.royaltyAmounts.treasuryAmount
        history.genesisAmount = event.params.royaltyAmounts.genesisAmount
        history.previousAmount = event.params.royaltyAmounts.previousAmount
        history.adjustedAmount = event.params.royaltyAmounts.adjustedAmount
        history.timestamp = event.block.timestamp
        history.save()
        
    } 
}
