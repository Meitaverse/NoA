import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    FeesForCollect,
} from "../generated/FeeCollectModule/Events"

import {
    FeeCollectModule,
} from "../generated/FeeCollectModule/FeeCollectModule"

import {
    ModuleGlobals
} from "../generated/FeeCollectModule/ModuleGlobals"

import {
    SBT
} from "../generated/FeeCollectModule/SBT"

import {
    FeesForCollectHistory,
} from "../generated/schema"
import { loadOrCreateAccount } from "./shared/accounts";
import { loadOrCreatePublication } from "./shared/publication";

export function handleFeesForCollect(event: FeesForCollect): void {
    log.info("handleFeesForCollect, event.address: {}", [event.address.toHexString()])

    //TODO try_MODULE_GLOBALS

    let feeCollectModule = FeeCollectModule.bind(event.address) 
    const result = feeCollectModule.try_MODULE_GLOBALS()
    if (!result.reverted) {
        let moduleGlobals = ModuleGlobals.bind(result.value)
        const result2 = moduleGlobals.try_getSBT()
        if (!result2.reverted) {
            const sbt = SBT.bind(result2.value) 
            const resultOwner = sbt.try_ownerOf( event.params.collectFeeUsers.ownershipSoulBoundTokenId )
            const resultCollector = sbt.try_ownerOf( event.params.collectFeeUsers.collectorSoulBoundTokenId )
            const resultGenesisCreator = sbt.try_ownerOf( event.params.collectFeeUsers.genesisSoulBoundTokenId )
            const resultPreviousCreator = sbt.try_ownerOf( event.params.collectFeeUsers.previousSoulBoundTokenId )
            if (!resultOwner.reverted && 
                !resultCollector.reverted &&
                !resultGenesisCreator.reverted &&
                !resultPreviousCreator.reverted
                ) {
                    let _idString = event.params.collectFeeUsers.collectorSoulBoundTokenId.toString() + "-" +  event.block.timestamp.toString()
                    const history = FeesForCollectHistory.load(_idString) || new FeesForCollectHistory(_idString)
                    
                    let publication = loadOrCreatePublication(event.params.publishId)

                    if (history) {
                        history.owner = loadOrCreateAccount(resultOwner.value).id
                        history.collector = loadOrCreateAccount(resultCollector.value).id
                        history.genesisCreator = loadOrCreateAccount(resultGenesisCreator.value).id
                        history.previousCreator = loadOrCreateAccount(resultPreviousCreator.value).id
                        history.publish = publication.id
                        history.tokenId = event.params.tokenId
                        history.collectUnits = event.params.collectUnits
                        history.treasuryAmount = event.params.royaltyAmounts.treasuryAmount
                        history.genesisAmount = event.params.royaltyAmounts.genesisAmount
                        history.previousAmount = event.params.royaltyAmounts.previousAmount
                        history.adjustedAmount = event.params.royaltyAmounts.adjustedAmount
                        history.timestamp = event.block.timestamp
                        history.save()
                    } 
            }
        }
    }

  
}
