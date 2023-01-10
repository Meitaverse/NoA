import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    ProfileCreated,
    MintSBTValue,
    BankTreasurySet,
    ApprovalForSlot,
    BurnSBT,
    BurnSBTValue,
    ProfileImageURISet
} from "../generated/SBT/Events"

import {
    Profile,
    MintSBTValueHistory,
    ApprovalForSlotHistory,
    BankTreasurySetHistory,
    BurnSBTHistory,
    BurnSBTValueHistory,
    ProfileImageURISetHistory,
} from "../generated/schema"

export function handleBankTreasurySet(event: BankTreasurySet): void {
    log.info("handleBankTreasurySet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = BankTreasurySetHistory.load(_idString) || new BankTreasurySetHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.bankTrerasury = event.params.bankTrerasury
        history.initialSupply = event.params.initialSupply
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handleProfileCreated(event: ProfileCreated): void {
    log.info("handleProfileCreated, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString()
    const profile = Profile.load(_idString) || new Profile(_idString)

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
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.value = event.params.value
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handleApprovalForSlot(event: ApprovalForSlot): void {
    log.info("handleApprovalForSlot, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.owner.toHexString() + "-" + event.block.timestamp.toString()
    const history = ApprovalForSlotHistory.load(_idString) || new ApprovalForSlotHistory(_idString)

    if (history) {
        history.owner = event.params.owner
        history.slot = event.params.slot
        history.operator = event.params.operator
        history.approved = event.params.approved
        history.save()
        
    } 
}


export function handleBurnSBT(event: BurnSBT): void {
    log.info("handleBurnSBT, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = BurnSBTHistory.load(_idString) || new BurnSBTHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
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

export function handleBurnSBTValue(event: BurnSBTValue): void {
    log.info("handleBurnSBTValue, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = BurnSBTValueHistory.load(_idString) || new BurnSBTValueHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.value = event.params.value
        history.timestamp = event.params.timestamp
        history.save()
        
    } 
}

export function handleProfileImageURISet(event: ProfileImageURISet): void {
    log.info("handleProfileImageURISet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = ProfileImageURISetHistory.load(_idString) || new ProfileImageURISetHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.imageURI = event.params.imageURI
        history.timestamp = event.params.timestamp
        history.save()
        
    } 
}

