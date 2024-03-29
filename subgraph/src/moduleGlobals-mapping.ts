import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import { getLogId } from "./shared/ids";

import {
    ProfileCreatorWhitelisted,
    HubCreatorWhitelisted,
    ModuleGlobalsTreasurySet,
    ModuleGlobalsVoucherSet,
    ModuleGlobalsManagerSet,
    ModuleGlobalsSBTSet,
    ModuleGlobalsPublishRoyaltySet,
    ModuleGlobalsTreasuryFeeSet,
    ModuleGlobalsGovernanceSet,
    CollectModuleWhitelisted,
    PublishModuleWhitelisted,
    TemplateWhitelisted,
    ModuleGlobalsCurrencyWhitelisted,
} from "../generated/ModuleGlobals/Events"

import {
    ProtocolContract,
    ProfileCreatorWhitelistedRecord,
    HubCreatorWhitelistedRecord,
    ModuleGlobalsTreasurySetHistory,
    ModuleGlobalsVoucherSetHistory,
    ModuleGlobalsManagerSetHistory,
    ModuleGlobalsSBTSetHistory,
    PublishRoyaltyRecord,
    TreasuryFeeRecord,
    ModuleGlobalsGovernanceSetHistory,
    CollectModuleWhitelistedRecord,
    PublishModuleWhitelistedRecord,
    TemplateWhitelistedRecord,
    CurrencyWhitelist,
} from "../generated/schema"

import {
    ModuleGlobals
} from "../generated/ModuleGlobals/ModuleGlobals"


import { saveTransactionHashHistory } from "./dnft";

export function handleProfileCreatorWhitelisted(event: ProfileCreatorWhitelisted): void {
    log.info("handleProfileCreatorWhitelisted, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.profileCreator.toHexString()
    const record = ProfileCreatorWhitelistedRecord.load(_idString) || new ProfileCreatorWhitelistedRecord(_idString)

    if (record) {
        record.profileCreator = event.params.profileCreator
        record.whitelisted = event.params.whitelisted
        record.caller = event.params.caller
        record.timestamp = event.params.timestamp
        record.save()
        
    } 

    saveTransactionHashHistory("ProfileCreatorWhitelisted", event);
}

export function handleHubCreatorWhitelisted(event: HubCreatorWhitelisted): void {
    log.info("handleHubCreatorWhitelisted, event.address: {}", [event.address.toHexString()])

    let _idStringRecord = event.params.soulBoundTokenId.toString()
    const record = HubCreatorWhitelistedRecord.load(_idStringRecord) || new HubCreatorWhitelistedRecord(_idStringRecord)

    if (record) {
        record.soulBoundTokenId = event.params.soulBoundTokenId
        record.whitelisted = event.params.whitelisted
        record.timestamp = event.params.timestamp
        record.save()
    } 

    saveTransactionHashHistory("HubCreatorWhitelisted", event);

}

export function handleModuleGlobalsTreasurySet(event: ModuleGlobalsTreasurySet): void {
    log.info("handleModuleGlobalsTreasurySet, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event) 
    const history = ModuleGlobalsTreasurySetHistory.load(_idString) || new ModuleGlobalsTreasurySetHistory(_idString)

    if (history) {
        history.prevTreasury = event.params.prevTreasury
        history.newTreasury = event.params.newTreasury
        history.timestamp = event.params.timestamp
        history.save()

        let _id = "Treaury"
        const protocolContract = ProtocolContract.load(_id) || new ProtocolContract(_id)
        if (protocolContract) {

            protocolContract.contract = event.params.newTreasury
            protocolContract.save()
        }

    } 

    saveTransactionHashHistory("ModuleGlobalsTreasurySet", event);
}

export function handleModuleGlobalsVoucherSet(event: ModuleGlobalsVoucherSet): void {
    log.info("handleModuleGlobalsVoucherSet, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = ModuleGlobalsVoucherSetHistory.load(_idString) || new ModuleGlobalsVoucherSetHistory(_idString)

    if (history) {
        history.prevVoucher = event.params.prevVoucher
        history.newVoucher = event.params.newVoucher
        history.timestamp = event.params.timestamp
        history.save()

        let _id = "Voucher"
        const protocolContract = ProtocolContract.load(_id) || new ProtocolContract(_id)
        if (protocolContract) {
            protocolContract.contract = event.params.newVoucher
            protocolContract.save()
        }
    } 

    saveTransactionHashHistory("ModuleGlobalsVoucherSet", event);
}

export function handleModuleGlobalsManagerSet(event: ModuleGlobalsManagerSet): void {
    log.info("handleModuleGlobalsManagerSet, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = ModuleGlobalsManagerSetHistory.load(_idString) || new ModuleGlobalsManagerSetHistory(_idString)

    if (history) {
        history.prevManager = event.params.prevManager
        history.newManager = event.params.newManager
        history.timestamp = event.params.timestamp
        history.save()

        let _id = "Manager"
        const protocolContract = ProtocolContract.load(_id) || new ProtocolContract(_id)
        if (protocolContract) {
            protocolContract.contract = event.params.newManager
            protocolContract.save()
        }
    } 

    saveTransactionHashHistory("ModuleGlobalsManagerSet", event);
}
    

export function handleModuleGlobalsSBTSet(event: ModuleGlobalsSBTSet): void {
    log.info("handleModuleGlobalsSBTSet, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = ModuleGlobalsSBTSetHistory.load(_idString) || new ModuleGlobalsSBTSetHistory(_idString)

    if (history) {
        history.prevSBT = event.params.prevSBT
        history.newSBT = event.params.newSBT
        history.timestamp = event.params.timestamp
        history.save()

        let _id = "SBT"
        const protocolContract = ProtocolContract.load(_id) || new ProtocolContract(_id)
        if (protocolContract) {
            protocolContract.contract = event.params.newSBT
            protocolContract.save()    
        }    

        //save to CurrencyWhitelist
        let _idString2 = event.params.newSBT.toHexString()
        const cwl = CurrencyWhitelist.load(_idString2) || new CurrencyWhitelist(_idString2)

        if (cwl) {
            cwl.currencyName = "NFT Derivative Protocol Token";
            cwl.currencySymbol = "SBT";
            cwl.currencyDecimals = 18;
            
            cwl.currency = event.params.newSBT
            cwl.whitelisted = true
            cwl.timestamp = event.params.timestamp
            cwl.save()
        } 
    } 

    saveTransactionHashHistory("ModuleGlobalsSBTSet", event);
}

export function handleModuleGlobalsPublishRoyaltySet(event: ModuleGlobalsPublishRoyaltySet): void {
    log.info("handleModuleGlobalsPublishRoyaltySet, event.address: {}", [event.address.toHexString()])

    let _idStringPublishRoyalty = 'PublishRoyaltySetting';
    const publishRoyalty = PublishRoyaltyRecord.load(_idStringPublishRoyalty) || new PublishRoyaltyRecord(_idStringPublishRoyalty)
    
    if (publishRoyalty) {
        publishRoyalty.prevPublishRoyalty = event.params.prevPublishRoyalty
        publishRoyalty.newPublishRoyalty = event.params.newPublishRoyalty
        publishRoyalty.timestamp = event.block.timestamp
        publishRoyalty.save()
    }
    saveTransactionHashHistory("ModuleGlobalsPublishRoyaltySet", event);
}

export function handleModuleGlobalsTreasuryFeeSet(event: ModuleGlobalsTreasuryFeeSet): void {
    log.info("handleModuleGlobalsTreasuryFeeSet, event.address: {}", [event.address.toHexString()])

    let _idStringTreasuryFee = 'TreasuryFeeSetting';
    const treasuryFeeSetting = TreasuryFeeRecord.load(_idStringTreasuryFee) || new TreasuryFeeRecord(_idStringTreasuryFee)
    
    if (treasuryFeeSetting) {
        treasuryFeeSetting.prevTreasuryFee = event.params.prevTreasuryFee
        treasuryFeeSetting.newTreasuryFee = event.params.newTreasuryFee
        treasuryFeeSetting.timestamp = event.block.timestamp
        treasuryFeeSetting.save()
    }
    saveTransactionHashHistory("ModuleGlobalsTreasuryFeeSet", event);
}

export function handleModuleGlobalsGovernanceSet(event: ModuleGlobalsGovernanceSet): void {
    log.info("handleModuleGlobalsGovernanceSet, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = ModuleGlobalsGovernanceSetHistory.load(_idString) || new ModuleGlobalsGovernanceSetHistory(_idString)

    if (history) {
        history.prevGovernance = event.params.prevGovernance
        history.newGovernance = event.params.newGovernance
        history.timestamp = event.params.timestamp
        history.save()
    } 
    saveTransactionHashHistory("ModuleGlobalsGovernanceSet", event);
}

export function handleCollectModuleWhitelisted(event: CollectModuleWhitelisted): void {
    log.info("handleCollectModuleWhitelisted, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.collectModule.toHex()
    const record = CollectModuleWhitelistedRecord.load(_idString) || new CollectModuleWhitelistedRecord(_idString)

    if (record) {
        record.collectModule = event.params.collectModule
        record.whitelisted = event.params.whitelisted
        record.timestamp = event.params.timestamp
        record.save()
    } 
    saveTransactionHashHistory("CollectModuleWhitelisted", event);
}

export function handlePublishModuleWhitelisted(event: PublishModuleWhitelisted): void {
    log.info("handlePublishModuleWhitelisted, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.publishModule.toHex()
    const record = PublishModuleWhitelistedRecord.load(_idString) || new PublishModuleWhitelistedRecord(_idString)

    if (record) {
        record.publishModule = event.params.publishModule
        record.whitelisted = event.params.whitelisted
        record.timestamp = event.params.timestamp
        record.save()
    } 
    saveTransactionHashHistory("PublishModuleWhitelisted", event);
}

export function handleTemplateWhitelisted(event: TemplateWhitelisted): void {
    log.info("handleTemplateWhitelisted, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.template.toHexString()
    const record = TemplateWhitelistedRecord.load(_idString) || new TemplateWhitelistedRecord(_idString)

    if (record) {
        record.template = event.params.template
        record.whitelisted = event.params.whitelisted
        record.timestamp = event.params.timestamp
        record.save()
    } 
    saveTransactionHashHistory("TemplateWhitelisted", event);
}

export function handleModuleGlobalsCurrencyWhitelisted(event: ModuleGlobalsCurrencyWhitelisted): void {
    log.info("handleModuleGlobalsCurrencyWhitelisted, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.currency.toHexString()
    const cwl = CurrencyWhitelist.load(_idString) || new CurrencyWhitelist(_idString)

    if (cwl) {
        const moduleGlobals = ModuleGlobals.bind(event.address)
        const result = moduleGlobals.try_getCurrencyInfo(event.params.currency)
        if (result.reverted) {
            log.info("try_getCurrencyInfo, result.reverted, currency:{}", [event.params.currency.toHex()])
            return 
        } 

        cwl.currencyName = result.value.currencyName;
        cwl.currencySymbol = result.value.currencySymbol;
        cwl.currencyDecimals = result.value.currencyDecimals;
        
        cwl.currency = event.params.currency
        cwl.whitelisted = event.params.newWhitelisted
        cwl.timestamp = event.params.timestamp
        cwl.save()
    } 
    saveTransactionHashHistory("ModuleGlobalsCurrencyWhitelisted", event);
}