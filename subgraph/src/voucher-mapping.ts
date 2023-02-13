import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";


import {
    Voucher,
    UserAmountLimitSet,
    GenerateVoucher,
    TransferBatch,
    TransferSingle,
} from "../generated/Voucher/Voucher"

import {
    UserAmountLimitSetHistory,
    VoucherRecord,
    VoucherAsset,
} from "../generated/schema"
import { loadOrCreateAccount } from "./shared/accounts";
import { getLogId } from "./shared/ids";
import { loadOrCreateSoulBoundToken } from "./shared/soulBoundToken";


export function handleUserAmountLimitSet(event: UserAmountLimitSet): void {
    log.info("handleUserAmountLimitSet, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = UserAmountLimitSetHistory.load(_idString) || new UserAmountLimitSetHistory(_idString)

    if (history) {
        history.preUserAmountLimit = event.params.preUserAmountLimit
        history.userAmountLimit = event.params.userAmountLimit
        history.timestamp = event.block.timestamp
        history.save()
    } 
}

export function handleGenerateVoucher(event: GenerateVoucher): void {
    log.info("handleGenerateVoucher, event.address: {}", [event.address.toHexString()])
    const sbtCreator = loadOrCreateSoulBoundToken(event.params.soulBoundTokenId)
    if (sbtCreator) {
        let _idString = getLogId(event)
        const voucherRecord = VoucherRecord.load(_idString) || new VoucherRecord(_idString)
    
        if (voucherRecord) {
            voucherRecord.creator = loadOrCreateAccount(Address.fromBytes(sbtCreator.wallet)).id
            voucherRecord.totalAmount = event.params.totalAmount

            let targets: Array<Bytes> = [];
            for (let index = 0; index <  event.params.to.length; index++) {
                targets.push(event.params.to[index])
            }
            voucherRecord.to  = targets
            voucherRecord.amounts = event.params.amounts
            voucherRecord.generateTimestamp = event.block.timestamp
            voucherRecord.save()
        } 
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
