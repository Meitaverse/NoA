import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    MintNFTVoucher,
    UserAmountLimitSet,
    GenerateVoucher,
} from "../generated/Voucher/Events"

import {
    NFTVoucherHistory,
    UserAmountLimitSetHistory,
    VoucherRecord,
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
        history.sbtValue = event.params.sbtValue
        history.generateTimestamp = event.params.generateTimestamp
        history.save()
        
    } 
}

export function handleUserAmountLimitSet(event: UserAmountLimitSet): void {
    log.info("handleUserAmountLimitSet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.timestamp.toString()
    const history = UserAmountLimitSetHistory.load(_idString) || new UserAmountLimitSetHistory(_idString)

    if (history) {
        history.preUserAmountLimit = event.params.preUserAmountLimit
        history.userAmountLimit = event.params.userAmountLimit
        history.timestamp = event.params.timestamp
        history.save()
        
    } 
}
export function handleGenerateVoucher(event: GenerateVoucher): void {
    log.info("handleGenerateVoucher, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.tokenId.toString()
    const voucherRecord = VoucherRecord.load(_idString) || new VoucherRecord(_idString)

    if (voucherRecord) {
        voucherRecord.vouchType = event.params.vouchType
        voucherRecord.tokenId = event.params.tokenId
        voucherRecord.etherValue = event.params.etherValue
        voucherRecord.sbtValue = event.params.sbtValue
        voucherRecord.generateTimestamp = event.params.generateTimestamp
        voucherRecord.endTimestamp = event.params.endTimestamp
        voucherRecord.save()
        
    } 
}
