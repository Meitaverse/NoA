import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    ProfileCreatorWhitelisted,
} from "../generated/ModuleGlobals/Events"

import {
    ProfileCreatorWhitelistedHistory,
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
