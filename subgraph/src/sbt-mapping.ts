import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    ProfileCreated,
    MintSBTValue,
    BurnSBT,
} from "../generated/SBT/Events"

import {
    SBT,
    Transfer,
    TransferValue,
    SlotChanged,
    Approval,
    ApprovalForAll,
    ApprovalValue,
} from "../generated/SBTERC3525/SBT"

import {
    Profile,
    MintSBTValueHistory,
    BurnSBTHistory,
    SBTTransferHistory,
    SBTAsset,
    SBTTransferValueHistory,
    SBTSlotChangedHistory,
    ApprovalRecord,
    ApprovalForAllRecord,
    ApprovalValueRecord,
} from "../generated/schema"

import { BASIS_POINTS, ONE_BIG_INT, ZERO_ADDRESS_STRING, ZERO_BIG_DECIMAL, ZERO_BIG_INT } from "./shared/constants"; 
import { loadOrCreateProfile } from "./shared/profile";
import { loadOrCreateSBTAsset } from "./shared/sbtAsset";

export function handleProfileCreated(event: ProfileCreated): void {
    log.info("handleProfileCreated, event.address: {}", [event.address.toHexString()])

    const profile = loadOrCreateProfile(event.params.wallet);
    if (profile) {
        profile.soulBoundTokenId = event.params.soulBoundTokenId
        profile.creator = event.params.creator
        profile.wallet = event.params.wallet
        profile.nickName = event.params.nickName
        profile.imageURI = event.params.imageURI
        profile.isRemove = false
        profile.timestamp = event.params.timestamp
        profile.save()
        
    } 
}

export function handleMintSBTValue(event: MintSBTValue): void {
    log.info("handleMintSBTValue, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = MintSBTValueHistory.load(_idString) || new MintSBTValueHistory(_idString)

    if (history) {
        history.caller = event.params.caller
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.value = event.params.value
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handleBurnSBT(event: BurnSBT): void {
    log.info("handleBurnSBT, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = BurnSBTHistory.load(_idString) || new BurnSBTHistory(_idString)

    if (history) {
        history.caller = event.params.caller
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.balance = event.params.balance
        history.timestamp = event.params.timestamp
        history.save()
        
    } 

    let _idStringProfile = event.params.soulBoundTokenId.toString()
    const profile = Profile.load(_idStringProfile)

    if (profile) {
        profile.soulBoundTokenId = event.params.soulBoundTokenId
        profile.isRemove = true
        profile.timestamp = event.params.timestamp
        profile.save()
    } 
}

export function handleSBTTransfer(event: Transfer): void {
    log.info("handleSBTTransfer, event.address: {}, _from: {}", [event.address.toHexString(), event.params._from.toHexString()])

    let _idString = event.params._from.toHexString() + "-" + event.params._to.toHexString()+ "-" + event.block.timestamp.toString()
    const history = SBTTransferHistory.load(_idString) || new SBTTransferHistory(_idString)
    
    let from = loadOrCreateProfile(event.params._from)
    let to = loadOrCreateProfile(event.params._to)

    if (history) {
        history.from = from.id
        history.to = to.id
        history.tokenId = event.params._tokenId
        history.timestamp = event.block.timestamp
        history.save()
        
        if (event.params._from.toHexString() == ZERO_ADDRESS_STRING) {
            const profile_to = loadOrCreateProfile(event.params._to)
            const sbtAsset_to = loadOrCreateSBTAsset(profile_to)
            sbtAsset_to.balance = BigInt.fromI32(0)
            sbtAsset_to.timestamp = event.block.timestamp
            sbtAsset_to.save()
        
        }

        //burn
        if (event.params._to.toHexString() == ZERO_ADDRESS_STRING) {
            const profile_from = loadOrCreateProfile(event.params._from)
            //remove 
            store.remove("Profile", event.params._from.toHex());
            store.remove("SBTAsset", event.params._from.toHex());
        
        }
    }
}

export function handleSBTTransferValue(event: TransferValue): void {
    log.info("handleSBTTransferValue, event.address: {}, _fromTokenId:{},_toTokenId:{}, _value:{} ", [
        event.address.toHexString(),
        event.params._fromTokenId.toString(),
        event.params._toTokenId.toString(),
        event.params._value.toString()
    ])

    let _idString = event.params._fromTokenId.toHexString() + "-" + event.params._toTokenId.toHexString()+ "-" + event.block.timestamp.toString()
    const history = SBTTransferValueHistory.load(_idString) || new SBTTransferValueHistory(_idString)

    if (history) {
        history.fromSoulBoundTokenId = event.params._fromTokenId
        history.toSoulBoundTokenId = event.params._toTokenId
        history.value = event.params._value
        history.timestamp = event.block.timestamp
        history.save()

        const sbt = SBT.bind(event.address) 

        if (!event.params._fromTokenId.isZero()) {
            const result = sbt.try_ownerOf(event.params._fromTokenId)
            if (result.reverted) {
                log.warning('try_ownerOf, result.reverted is true', [])
            } else {
                log.info("try_ownerOf, result.value: {}", [result.value.toHex()])

                const profile_from = loadOrCreateProfile(result.value)
                const sbtAsset_from = loadOrCreateSBTAsset(profile_from)
        
                const result2 = sbt.try_balanceOf1(event.params._fromTokenId)
        
                if (result2.reverted) {
                    log.warning('try_balanceOf1, result2.reverted is true', [])
                    sbtAsset_from.balance = sbtAsset_from.balance.minus(event.params._value)
                } else {
                    log.info("try_balanceOf1, result2.value: {}", [result2.value.toString()])
                    sbtAsset_from.balance = result2.value
                }
                sbtAsset_from.timestamp = event.block.timestamp
                sbtAsset_from.save()

                
            }
        }

        if (!event.params._toTokenId.isZero()){
            const result = sbt.try_ownerOf(event.params._toTokenId)
            if (result.reverted) {
                log.warning('try_ownerOf, result.reverted is true', [])
            } else {
                log.info("try_ownerOf, result.value: {}", [result.value.toHex()])

                const profile_to = loadOrCreateProfile(result.value)
                const sbtAsset_to = loadOrCreateSBTAsset(profile_to)
                    
                const result2 = sbt.try_balanceOf1(event.params._toTokenId)
        
                if (result2.reverted) {
                    log.warning('try_balanceOf1, result2.reverted is true', [])
                    sbtAsset_to.balance = sbtAsset_to.balance.plus(event.params._value)
                } else {
                    log.info("try_balanceOf1, result2.value: {}", [result2.value.toString()])
                    sbtAsset_to.balance = result2.value
                }
                sbtAsset_to.timestamp = event.block.timestamp
                sbtAsset_to.save()
            
            }
            
        }
    } 
}


export function handleSBTSlotChanged(event: SlotChanged): void {
    log.info("handleSBTSlotChanged, event.address: {}", [event.address.toHexString()])

    let _idString = event.params._tokenId.toHexString() + "-" + event.block.timestamp.toString()
    const history = SBTSlotChangedHistory.load(_idString) || new SBTSlotChangedHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params._tokenId
        history.oldSlot = event.params._oldSlot
        history.newSlot = event.params._newSlot
        history.timestamp = event.block.timestamp
        history.save()
    } 
}

export function handleApproval(event: Approval): void {
    log.info("handleApproval, event.address: {}", [event.address.toHexString()])

    let _idString = event.params._owner.toHexString() + "-" +  event.params._approved.toHexString()
    const approvalRecord = ApprovalRecord.load(_idString) || new ApprovalRecord(_idString)

    if (approvalRecord) {
        approvalRecord.owner = event.params._owner
        approvalRecord.approved = event.params._approved
        approvalRecord.tokenId = event.params._tokenId
        approvalRecord.timestamp = event.block.timestamp
        approvalRecord.save()
    } 
}

export function handleApprovalForAll(event: ApprovalForAll): void {
    log.info("handleApprovalForAll, event.address: {}", [event.address.toHexString()])

    let _idString = event.params._owner.toHexString() + "-" + event.params._operator.toHexString() 
    const approvalForAllRecord = ApprovalForAllRecord.load(_idString) || new ApprovalForAllRecord(_idString)

    if (approvalForAllRecord) {
        approvalForAllRecord.owner = event.params._owner
        approvalForAllRecord.operator = event.params._operator
        approvalForAllRecord.approved = event.params._approved
        approvalForAllRecord.timestamp = event.block.timestamp
        approvalForAllRecord.save()
    } 
}

export function handleApprovalValue(event: ApprovalValue): void {
    log.info("handleApprovalValue, event.address: {}", [event.address.toHexString()])

    let _idString = event.params._tokenId.toString() + "-" + event.params._operator.toHexString() 
    const approvalValueRecord = ApprovalValueRecord.load(_idString) || new ApprovalValueRecord(_idString)

    if (approvalValueRecord) {
        approvalValueRecord.tokenId = event.params._tokenId
        approvalValueRecord.operator = event.params._operator
        approvalValueRecord.value = event.params._value
        approvalValueRecord.timestamp = event.block.timestamp
        approvalValueRecord.save()
    } 
}
