import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    ProfileCreated,
    MintNDPTValue,
    BankTreasurySet,
    ApprovalForSlot,
    BurnNDPT,
    BurnNDPTValue,
    ProfileImageURISet
} from "../generated/NDP/Events"

import {
    Profile,
    MintNDPValueHistory,
    ApprovalForSlotHistory,
    BankTreasurySetHistory,
    BurnNDPTHistory,
    BurnNDPTValueHistory,
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

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const profile = Profile.load(_idString) || new Profile(_idString)

    if (profile) {
        profile.soulBoundTokenId = event.params.soulBoundTokenId
        profile.creator = event.params.creator
        profile.wallet = event.params.wallet
        profile.nickName = event.params.nickName
        profile.imageURI = event.params.imageURI
        profile.timestamp = event.params.timestamp
        profile.save()
        
    } 
}

export function handleMintNDPTValue(event: MintNDPTValue): void {
    log.info("handleMintNDPTValue, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = MintNDPValueHistory.load(_idString) || new MintNDPValueHistory(_idString)

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


export function handleBurnNDPT(event: BurnNDPT): void {
    log.info("handleBurnNDPT, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = BurnNDPTHistory.load(_idString) || new BurnNDPTHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.timestamp = event.params.timestamp
        history.save()
        
    } 
}

export function handleBurnNDPTValue(event: BurnNDPTValue): void {
    log.info("handleBurnNDPTValue, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = BurnNDPTValueHistory.load(_idString) || new BurnNDPTValueHistory(_idString)

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

