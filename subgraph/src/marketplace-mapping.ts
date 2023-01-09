import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    AddMarket,
} from "../generated/MarketPlace/Events"

import {
    Market,
} from "../generated/schema"

export function handleAddMarket(event: AddMarket): void {
    log.info("handleAddMarket, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.derivativeNFT.toHexString() + "-" +  event.block.timestamp.toString()
    const market = Market.load(_idString) || new Market(_idString)

    if (market) {
        market.derivativeNFT = event.params.derivativeNFT
        market.feePayType = event.params.feePayType
        market.feeShareType = event.params.feeShareType
        market.royaltyBasisPoints = event.params.royaltyBasisPoints
        market.timestamp = event.block.timestamp
        market.save()
        
    } 
}
