import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    TransferDerivativeNFT,
} from "../generated/Manager/Events"

import {
    DerivativeNFTTransferHistory,
} from "../generated/schema"

export function handleTransferDerivativeNFT(event: TransferDerivativeNFT): void {
    log.info("handleTransferDerivativeNFT, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.tokenId.toString() + "-" +  event.params.timestamp.toString()
    const history = DerivativeNFTTransferHistory.load(_idString) || new DerivativeNFTTransferHistory(_idString)
    if (history) {
        history.fromSoulBoundTokenId = event.params.fromSoulBoundTokenId
        history.toSoulBoundTokenId = event.params.toSoulBoundTokenId
        history.projectId = event.params.projectId
        history.tokenId = event.params.tokenId
        history.timestamp = event.block.timestamp
        history.save()
    } 
}
