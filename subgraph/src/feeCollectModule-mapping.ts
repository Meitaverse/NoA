import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    Distribute,
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
    DistributeHistory, Publication,
} from "../generated/schema"
import { loadOrCreateAccount } from "./shared/accounts";
import { loadOrCreatePublish } from "./shared/publish";
import { loadOrCreateSoulBoundToken } from "./shared/soulBoundToken";
import { ZERO_ADDRESS } from "../../test/helpers/constants";
import { getLogId } from "./shared/ids";

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
        history.tokenId = event.params.tokenId
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
