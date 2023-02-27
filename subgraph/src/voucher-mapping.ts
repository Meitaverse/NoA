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
import { ZERO_ADDRESS_STRING, ZERO_BIG_INT } from "./shared/constants";


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
            voucherRecord.generatedTimestamp = event.block.timestamp
            voucherRecord.save()
        } 
    }
}

export function handleTransferBatch(event: TransferBatch): void {
    
    /*
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
        );
        
        */
    
    log.info("handleTransferSingle, operator: {}, from: {}, to: {}", [
        event.params.operator.toHexString(),
        event.params.from.toHexString(),
        event.params.to.toHexString(),
    ])

    if (event.params.from.toHexString() == ZERO_ADDRESS_STRING) {
        
        //mint batch
        
        for (let index = 0; index <  event.params.ids.length; index++) {
            let _idString = event.params.to.toHexString() + "-" + event.params.ids[index].toString()

            const voucherAssetTo = VoucherAsset.load(_idString) || new VoucherAsset(_idString)

            if (voucherAssetTo) {
                voucherAssetTo.wallet = event.params.to
                voucherAssetTo.tokenId = event.params.ids[index]
                voucherAssetTo.value = event.params.values[index]
                voucherAssetTo.timestamp = event.block.timestamp
                voucherAssetTo.save()
            } 
        }
    } 
    if (event.params.to.toHexString() == ZERO_ADDRESS_STRING) {
        //burn batch
        for (let index = 0; index <  event.params.ids.length; index++) {
            let _idString = event.params.from.toHexString() + "-" + event.params.ids[index].toString()
            const voucherAssetFrom = VoucherAsset.load(_idString)
            if (voucherAssetFrom) {
                store.remove("VoucherAsset", _idString);
            } 
        }

    }

    if (event.params.from.toHexString() != ZERO_ADDRESS_STRING && event.params.to.toHexString() != ZERO_ADDRESS_STRING) {
        for (let index = 0; index <  event.params.ids.length; index++) {

            let to_idString = event.params.to.toHexString() + "-" + event.params.ids[index].toString()
            const voucherAssetTo = VoucherAsset.load(to_idString) || new VoucherAsset(to_idString)
    
            if (voucherAssetTo) {
                voucherAssetTo.wallet = event.params.to
                voucherAssetTo.tokenId = event.params.ids[index]
                if (voucherAssetTo.value) {
                    voucherAssetTo.value = voucherAssetTo.value.plus(event.params.values[index])
                }
                
                voucherAssetTo.timestamp = event.block.timestamp
                voucherAssetTo.save()
            } 
            let from_idString = event.params.from.toHexString() + "-" + event.params.ids[index].toString()
            const voucherAssetfrom = VoucherAsset.load(from_idString)
    
            if (voucherAssetfrom) {
                voucherAssetfrom.wallet = event.params.to
                voucherAssetfrom.tokenId = event.params.ids[index]
                if (voucherAssetfrom.value) {
                    voucherAssetfrom.value = voucherAssetfrom.value.minus(event.params.values[index])
                }
                
                voucherAssetfrom.timestamp = event.block.timestamp

                if (voucherAssetfrom.value.isZero()) {
                    store.remove("VoucherAsset", from_idString);
                } else {
                    voucherAssetfrom.save()
                }
            } 
        }
        
    }
}

export function handleTransferSingle(event: TransferSingle): void {

    //event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    log.info("handleTransferSingle, operator: {}, from: {}, to: {}, id: {}, value:{}", [
        event.params.operator.toHexString(),
        event.params.from.toHexString(),
        event.params.to.toHexString(),
        event.params.id.toString(),
        event.params.value.toString(),
    ])
    
    if (event.params.from.toHexString() == ZERO_ADDRESS_STRING) {
        
        //mint 
        let _idString = event.params.to.toHexString() + "-" + event.params.id.toString()
        const voucherAssetTo = new VoucherAsset(_idString)

        if (voucherAssetTo) {
            voucherAssetTo.wallet = event.params.to
            voucherAssetTo.tokenId = event.params.id
            voucherAssetTo.value = event.params.value
            voucherAssetTo.timestamp = event.block.timestamp
            voucherAssetTo.save()
        } 
    
    }

    if (event.params.to.toHexString() == ZERO_ADDRESS_STRING) {
        //burn 
        let _idString = event.params.from.toHexString() + "-" + event.params.id.toString()
        const voucherAssetFrom = VoucherAsset.load(_idString)
        if (voucherAssetFrom) {
            store.remove("VoucherAsset", _idString);
        } 
    }
    
    if (event.params.from.toHexString() != ZERO_ADDRESS_STRING && event.params.to.toHexString() != ZERO_ADDRESS_STRING) {
        let to_idString = event.params.to.toHexString() + "-" + event.params.id.toString()
        const voucherAssetTo = VoucherAsset.load(to_idString)

        if (voucherAssetTo) {
            voucherAssetTo.wallet = event.params.to
            voucherAssetTo.tokenId = event.params.id
            if (voucherAssetTo.value) {
                voucherAssetTo.value = voucherAssetTo.value.plus(event.params.value)
            }
            
            voucherAssetTo.timestamp = event.block.timestamp
            voucherAssetTo.save()
        } 
        let from_idString = event.params.from.toHexString() + "-" + event.params.id.toString()
        const voucherAssetfrom = new VoucherAsset(from_idString)

        if (voucherAssetfrom) {
            voucherAssetfrom.wallet = event.params.to
            voucherAssetfrom.tokenId = event.params.id
            if (voucherAssetfrom.value) {
                voucherAssetfrom.value = voucherAssetfrom.value.minus(event.params.value)
            }
            
            voucherAssetfrom.timestamp = event.block.timestamp
            voucherAssetfrom.save()
        } 
        
    }
        
  

    
}
