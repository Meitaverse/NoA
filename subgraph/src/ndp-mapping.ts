import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    // Manager,
    ProfileCreated,
} from "../generated/NDP/NDP"

import {
    MintNDPTValue,
} from "../generated/NDP/Events"

import {
    Profile,
    MintNDPValueHistory,
} from "../generated/schema"

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
