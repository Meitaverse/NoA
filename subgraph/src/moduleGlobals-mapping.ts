import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    ProfileCreatorWhitelisted,
    HubCreatorWhitelisted,
    ModuleGlobalsTreasurySet,
    ModuleGlobalsVoucherSet,
    ModuleGlobalsManagerSet,
    ModuleGlobalsNDPTSet,
    ModuleGlobalsPublishRoyaltySet,
    ModuleGlobalsTreasuryFeeSet,
    ModuleGlobalsGovernanceSet,
    CollectModuleWhitelisted,
    PublishModuleWhitelisted,
    TemplateWhitelisted,
} from "../generated/ModuleGlobals/Events"

import {
    ProfileCreatorWhitelistedHistory,
    HubCreatorWhitelistedHistory,
    ModuleGlobalsTreasurySetHistory,
    ModuleGlobalsVoucherSetHistory,
    ModuleGlobalsManagerSetHistory,
    ModuleGlobalsNDPTSetHistory,
    ModuleGlobalsPublishRoyaltySetHistory,
    ModuleGlobalsTreasuryFeeSetHistory,
    ModuleGlobalsGovernanceSetHistory,
    CollectModuleWhitelistedHistory,
    PublishModuleWhitelistedHistory,
    TemplateWhitelistedHistory,
} from "../generated/schema"

export function handleProfileCreatorWhitelisted(event: ProfileCreatorWhitelisted): void {
    log.info("handleProfileCreatorWhitelisted, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.profileCreator.toHexString() + "-" +  event.params.timestamp.toString()
    const history = ProfileCreatorWhitelistedHistory.load(_idString) || new ProfileCreatorWhitelistedHistory(_idString)

    if (history) {
        history.profileCreator = event.params.profileCreator
        history.whitelisted = event.params.whitelisted
        history.timestamp = event.params.timestamp
        history.save()
        
    } 
}

export function handleHubCreatorWhitelisted(event: HubCreatorWhitelisted): void {
    log.info("handleHubCreatorWhitelisted, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" +  event.params.timestamp.toString()
    const history = HubCreatorWhitelistedHistory.load(_idString) || new HubCreatorWhitelistedHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.whitelisted = event.params.whitelisted
        history.timestamp = event.params.timestamp
        history.save()
        
    } 
}

export function handleModuleGlobalsTreasurySet(event: ModuleGlobalsTreasurySet): void {
    log.info("handleModuleGlobalsTreasurySet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.newTreasury.toHexString() + "-" +  event.params.timestamp.toString()
    const history = ModuleGlobalsTreasurySetHistory.load(_idString) || new ModuleGlobalsTreasurySetHistory(_idString)

    if (history) {
        history.prevTreasury = event.params.prevTreasury
        history.newTreasury = event.params.newTreasury
        history.timestamp = event.params.timestamp
        history.save()
        
    } 
}

export function handleModuleGlobalsVoucherSet(event: ModuleGlobalsVoucherSet): void {
    log.info("handleModuleGlobalsVoucherSet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.newVoucher.toHexString() + "-" +  event.params.timestamp.toString()
    const history = ModuleGlobalsVoucherSetHistory.load(_idString) || new ModuleGlobalsVoucherSetHistory(_idString)

    if (history) {
        history.prevVoucher = event.params.prevVoucher
        history.newVoucher = event.params.newVoucher
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handleModuleGlobalsManagerSet(event: ModuleGlobalsManagerSet): void {
    log.info("handleModuleGlobalsManagerSet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.newManager.toHexString() + "-" +  event.params.timestamp.toString()
    const history = ModuleGlobalsManagerSetHistory.load(_idString) || new ModuleGlobalsManagerSetHistory(_idString)

    if (history) {
        history.prevManager = event.params.prevManager
        history.newManager = event.params.newManager
        history.timestamp = event.params.timestamp
        history.save()
    } 
}
    

export function handleModuleGlobalsNDPTSet(event: ModuleGlobalsNDPTSet): void {
    log.info("handleModuleGlobalsNDPTSet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.newNDPT.toHexString() + "-" +  event.params.timestamp.toString()
    const history = ModuleGlobalsNDPTSetHistory.load(_idString) || new ModuleGlobalsNDPTSetHistory(_idString)

    if (history) {
        history.prevNDPT = event.params.prevNDPT
        history.newNDPT = event.params.newNDPT
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handleModuleGlobalsPublishRoyaltySet(event: ModuleGlobalsPublishRoyaltySet): void {
    log.info("handleModuleGlobalsPublishRoyaltySet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.newPublishRoyalty.toString() + "-" +  event.params.timestamp.toString()
    const history = ModuleGlobalsPublishRoyaltySetHistory.load(_idString) || new ModuleGlobalsPublishRoyaltySetHistory(_idString)

    if (history) {
        history.prevPublishRoyalty = event.params.prevPublishRoyalty
        history.newPublishRoyalty = event.params.newPublishRoyalty
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handleModuleGlobalsTreasuryFeeSet(event: ModuleGlobalsTreasuryFeeSet): void {
    log.info("handleModuleGlobalsTreasuryFeeSet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.newTreasuryFee.toString() + "-" +  event.params.timestamp.toString()
    const history = ModuleGlobalsTreasuryFeeSetHistory.load(_idString) || new ModuleGlobalsTreasuryFeeSetHistory(_idString)

    if (history) {
        history.prevTreasuryFee = event.params.prevTreasuryFee
        history.newTreasuryFee = event.params.newTreasuryFee
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handleModuleGlobalsGovernanceSet(event: ModuleGlobalsGovernanceSet): void {
    log.info("handleModuleGlobalsGovernanceSet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.newGovernance.toString() + "-" +  event.params.timestamp.toString()
    const history = ModuleGlobalsGovernanceSetHistory.load(_idString) || new ModuleGlobalsGovernanceSetHistory(_idString)

    if (history) {
        history.prevGovernance = event.params.prevGovernance
        history.newGovernance = event.params.newGovernance
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handleCollectModuleWhitelisted(event: CollectModuleWhitelisted): void {
    log.info("handleCollectModuleWhitelisted, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.collectModule.toString() + "-" +  event.params.timestamp.toString()
    const history = CollectModuleWhitelistedHistory.load(_idString) || new CollectModuleWhitelistedHistory(_idString)

    if (history) {
        history.collectModule = event.params.collectModule
        history.whitelisted = event.params.whitelisted
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handlePublishModuleWhitelisted(event: PublishModuleWhitelisted): void {
    log.info("handlePublishModuleWhitelisted, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.publishModule.toString() + "-" +  event.params.timestamp.toString()
    const history = PublishModuleWhitelistedHistory.load(_idString) || new PublishModuleWhitelistedHistory(_idString)

    if (history) {
        history.publishModule = event.params.publishModule
        history.whitelisted = event.params.whitelisted
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handleTemplateWhitelisted(event: TemplateWhitelisted): void {
    log.info("handleTemplateWhitelisted, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.template.toString() + "-" +  event.params.timestamp.toString()
    const history = TemplateWhitelistedHistory.load(_idString) || new TemplateWhitelistedHistory(_idString)

    if (history) {
        history.template = event.params.template
        history.whitelisted = event.params.whitelisted
        history.timestamp = event.params.timestamp
        history.save()
    } 
}