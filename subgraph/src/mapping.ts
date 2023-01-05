import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    // Manager,
    ProfileCreated,
} from "../generated/bitsoul/Events"

import {
    Profile,
} from "../generated/schema"

export function handleProfileCreated(event: ProfileCreated): void {
    log.info("handleProfileCreated, event.address: {}", [event.address.toHexString()])
    /*
    let manager = Manager.bind(event.address)
   

    // let noaContract = NoAV1.bind(Address.fromString("0x0165878A594ca255338adfa4d48449f69242Eb8F"));

    let name = manager.name()
    let symbol = manager.symbol()
    log.info(
        "handleEventToken, name:{},  symbol: {}",
        [
            name,
            symbol
        ]
    )
    */

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.wallet.toString()
    const profile = Profile.load(_idString) || new Profile(_idString)
    // let tokenURI = ""
    // let slotURI = ""
    // let tokenURI = noaContract.tokenURI(event.params.tokenId)
    // let slotURI = noaContract.slotURI(event.params.projectId)
    // log.info(
    //     "handleEventToken, tokenURI: {}, slotURI: {}",
    //     [
    //         tokenURI,
    //         slotURI
    //     ]
    //   )

    if (profile) {
        profile.soulBoundTokenId = event.params.soulBoundTokenId
        profile.creator = event.params.creator
        profile.wallet = event.params.wallet
        profile.nickName = event.params.nickName
        profile.imageURI = event.params.imageURI
        profile.timestamp = event.block.timestamp
        profile.save()
        
    } 
}


// export function handleOrganizerAdded(event: OrganizerAdded): void {
//     let organizerString = event.params.organizer.toHexString()
//     const organizer = Organizer.load(organizerString) || new Organizer(organizerString)

//     if (organizer) {
//         organizer.organizer = event.params.organizer
//         organizer.mainnetWallet = event.params.mainnetWallet
//         organizer.name = event.params.name
//         organizer.cTokenId = event.params.cTokenId
//         organizer.save()
//     }
// }

// export function handleOrganizerRemoved(event: OrganizerRemoved): void {
//     store.remove("Organizer", event.params.organizer.toHexString())
// }
/*
export function handleEventAdded(event: ProjectAdded): void {
    let eventIdString = event.params.projectId.toString()
    const eventItem = EventItem.load(eventIdString) || new EventItem(eventIdString)
    if (eventItem) {
        eventItem.organizer =  event.params.organizer.toHexString()
        eventItem.projectId = event.params.projectId
        eventItem.name = event.params.name
        eventItem.description = event.params.description
        eventItem.image = event.params.image
        eventItem.mintMax = event.params.mintMax
        eventItem.save()
    }
    let organizerString = event.params.organizer.toHexString()
    const organizer = Organizer.load(organizerString) || new Organizer(organizerString)

    if (organizer) {
        organizer.organizer = event.params.organizer
        // organizer.mainnetWallet = event.params.mainnetWallet
        // organizer.name = event.params.name
        // organizer.cTokenId = event.params.cTokenId
        organizer.save()
    }
    
}

export function handleEventToken(event: ProjectToken): void {
    log.info("handleEventToken, event.address: {}", [event.address.toHexString()])
    let noaContract = NoAV1.bind(event.address)
   

    // let noaContract = NoAV1.bind(Address.fromString("0x0165878A594ca255338adfa4d48449f69242Eb8F"));

    let name = noaContract.name()
    let symbol = noaContract.symbol()
    log.info(
        "handleEventToken, name:{},  symbol: {}",
        [
            name,
            symbol
        ]
    )

    let _idString = event.params.projectId.toString() + "-" + event.params.tokenId.toString()
    const token = Token.load(_idString) || new Token(_idString)
    // let tokenURI = ""
    // let slotURI = ""
    let tokenURI = noaContract.tokenURI(event.params.tokenId)
    let slotURI = noaContract.slotURI(event.params.projectId)
    log.info(
        "handleEventToken, tokenURI: {}, slotURI: {}",
        [
            tokenURI,
            slotURI
        ]
      )

    if (token) {
        token.projectId = event.params.projectId
        token.tokenId = event.params.tokenId
        token.tokenURI = tokenURI
        token.slotURI = slotURI
        token.organizer = event.params.organizer.toHexString()
        token.owner = event.params.owner.toHexString()
        token.createdAtTimestamp = event.block.timestamp
        token.save()

        let user_idString = event.params.owner.toHexString()
        const user = User.load(user_idString) || new User(user_idString)
        if (user) {
            user.localWallet = event.params.owner
            user.save()
        } 

        const history = History.load(_idString) || new History(_idString) 
        if (history) {
            history.projectId = event.params.projectId
            history.token = _idString
            history.organizer = event.params.organizer.toHexString()
            history.owner = user_idString
            history.createdAtTimestamp = event.block.timestamp
            history.save()
        }
    } 
}

export function handleBurnToken(event: BurnToken): void { 
    let _idString = event.params.projectId.toString() + "-" + event.params.tokenId.toString()
    store.remove("Token", _idString)
    store.remove("History", _idString)
}
*/

// export function handleSetOrganizerMainnetWallet(event: SetOrganizerMainnetWallet): void {
//     let _idString =  event.params.organizer.toHexString()
//     const organizer = Organizer.load(_idString) || new Organizer(_idString) 
//     if (organizer) {
//         organizer.mainnetWallet = event.params.mainnetWallet
//         organizer.name = event.params.name
//         organizer.cTokenId = event.params.cTokenId
//         organizer.save()
//     } 
// }

// export function handleSetUserMainnetWallet(event: SetUserMainnetWallet): void {
//     let _idString =  event.params.user.toHexString()
//     const user = User.load(_idString) || new User(_idString) 
//     if (user) {
//         user.localWallet = event.params.user
//         user.mainnetWallet = event.params.mainnetWallet
//         user.name = event.params.name
//         user.sbTokenId = event.params.sbTokenId
//         user.save()
//     }
// }
  
