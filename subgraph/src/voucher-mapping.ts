import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    MintNFTVoucher,
} from "../generated/Voucher/Events"

import {
    NFTVoucherHistory,
} from "../generated/schema"

export function handleMintNFTVoucher(event: MintNFTVoucher): void {
    log.info("handleMintNFTVoucher, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" +  event.params.generateTimestamp.toString()
    const history = NFTVoucherHistory.load(_idString) || new NFTVoucherHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.account = event.params.account
        history.vouchType = event.params.vouchType
        history.tokenId = event.params.tokenId
        history.ndptValue = event.params.ndptValue
        history.generateTimestamp = event.params.generateTimestamp
        history.save()
        
    } 
}
