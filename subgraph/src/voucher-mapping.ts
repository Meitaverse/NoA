import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    MintNFTVoucher,
    UserAmountLimitSet,
    GenerateVoucher,
} from "../generated/Voucher/Events"

import {
    Voucher,
    TransferBatch,
    TransferSingle,
} from "../generated/VoucherERC1155/Voucher"

import {
    NFTVoucherHistory,
    UserAmountLimitSetHistory,
    VoucherRecord,
    VoucherAsset,
} from "../generated/schema"
import { loadOrCreateAccount } from "./shared/accounts";

export function handleMintNFTVoucher(event: MintNFTVoucher): void {
    log.info("handleMintNFTVoucher, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" +  event.params.generateTimestamp.toString()
    const history = NFTVoucherHistory.load(_idString) || new NFTVoucherHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.account = loadOrCreateAccount(event.params.account).id
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

export function handleTransferBatch(event: TransferBatch): void {
    log.info("handleTransferBatch, event.address: {}", [event.address.toHexString()])
   
    for (let index = 0; index <  event.params.ids.length; index++) {
        let _idString = event.params.ids[index].toString()

        const voucherAssetFrom = VoucherAsset.load(_idString) || new VoucherAsset(_idString)

        if (voucherAssetFrom) {
            voucherAssetFrom.wallet = event.params.from
            voucherAssetFrom.tokenId = event.params.ids[index]
            voucherAssetFrom.value = voucherAssetFrom.value.minus(event.params.values[index])
            voucherAssetFrom.timestamp = event.block.timestamp
            voucherAssetFrom.save()
        } 

        const voucherAssetTo = VoucherAsset.load(_idString) || new VoucherAsset(_idString)

        if (voucherAssetTo) {
            voucherAssetTo.wallet = event.params.to
            voucherAssetTo.tokenId = event.params.ids[index]
            voucherAssetTo.value = voucherAssetTo.value.plus(event.params.values[index])
            voucherAssetTo.timestamp = event.block.timestamp
            voucherAssetTo.save()
        } 
    }
}

export function handleTransferSingle(event: TransferSingle): void {
    log.info("handleTransferBatch, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.id.toString()
    const voucherAssetFrom = VoucherAsset.load(_idString) || new VoucherAsset(_idString)

    if (voucherAssetFrom) {
        voucherAssetFrom.wallet = event.params.to
        voucherAssetFrom.tokenId = event.params.id
        voucherAssetFrom.value = voucherAssetFrom.value.plus(event.params.value)
        voucherAssetFrom.timestamp = event.block.timestamp
        voucherAssetFrom.save()
    } 

    const voucherAssetTo = VoucherAsset.load(_idString) || new VoucherAsset(_idString)

    if (voucherAssetTo) {
        voucherAssetTo.wallet = event.params.to
        voucherAssetTo.tokenId = event.params.id
        voucherAssetTo.value = voucherAssetTo.value.plus(event.params.value)
        voucherAssetTo.timestamp = event.block.timestamp
        voucherAssetTo.save()
    } 

}
