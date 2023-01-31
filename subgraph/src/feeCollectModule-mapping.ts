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
    FeesForCollectHistory, Publication,
} from "../generated/schema"
import { loadOrCreateAccount } from "./shared/accounts";
import { loadOrCreatePublish } from "./shared/publish";
import { loadOrCreateSoulBoundToken } from "./shared/soulBoundToken";
import { ZERO_ADDRESS } from "../../test/helpers/constants";

export function handleFeesForCollect(event: FeesForCollect): void {
    log.info("handleFeesForCollect, event.address: {}", [event.address.toHexString()])

    let owner : Address = Address.zero();
    let collector : Address = Address.zero();
    let genesisCreator : Address = Address.zero();
    let previousCreator : Address = Address.zero();

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

    let _idString = event.params.collectFeeUsers.collectorSoulBoundTokenId.toString() + "-" +  event.block.timestamp.toString()
    const history = FeesForCollectHistory.load(_idString) || new FeesForCollectHistory(_idString)

    if (history) {
        history.owner = loadOrCreateAccount(owner).id
        history.collector = loadOrCreateAccount(collector).id
        history.genesisCreator = loadOrCreateAccount(genesisCreator).id
        history.previousCreator = loadOrCreateAccount(previousCreator).id
        history.publish = loadOrCreatePublish(event.params.publishId).id
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
