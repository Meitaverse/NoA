import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    DerivativeNFT,
    Transfer,
    TransferValue,
    SlotChanged,
    BurnToken,
    Approval,
    ApprovalForAll,
    ApprovalValue,
    DerivativeNFTImageURISet,
} from "../generated/DerivativeNFT/DerivativeNFT"

import {
    DerivativeNFTTransferHistory,
    DerivativeNFTAsset,
    DerivativeNFTTransferValueHistory,
    DerivativeNFTSlotChangedHistory,
    BurnDerivativeNFTHistory,
    BurnDerivativeNFTValueHistory,
    ApprovalRecord,
    ApprovalForAllRecord,
    ApprovalValueRecord,
    DerivativeNFTImageURI,
} from "../generated/schema"

export function handleTransfer(event: Transfer): void {
    log.info("handleTransfer, event.address: {}, _from: {}", [event.address.toHexString(), event.params._from.toHexString()])

    let _idString = event.params._from.toHexString() + "-" + event.params._to.toHexString()+ "-" + event.block.timestamp.toString()
    const history = DerivativeNFTTransferHistory.load(_idString) || new DerivativeNFTTransferHistory(_idString)

    if (history) {
        history.from = event.params._from
        history.to = event.params._to
        history.tokenId = event.params._tokenId
        history.timestamp = event.block.timestamp
        history.save()

        let _idStringAsset = event.params._tokenId.toString()
        const derivativeNFTAsset = DerivativeNFTAsset.load(_idStringAsset) || new DerivativeNFTAsset(_idStringAsset)

        if (derivativeNFTAsset) {
            const derivativeNFT = DerivativeNFT.bind(event.address) 
            const result = derivativeNFT.try_getPublishIdByTokenId(event.params._tokenId)
        
            if (result.reverted) {
                log.warning('try_getPublishIdByTokenId, result.reverted is true', [])
            } else {
                log.info("try_getPublishIdByTokenId, result.value: {}", [result.value.toString()])
                derivativeNFTAsset.publishId = result.value
            }

            derivativeNFTAsset.wallet = event.params._to
            derivativeNFTAsset.tokenId = event.params._tokenId
            if (event.params._from.toHexString() == '0x0000000000000000000000000000000000000000') {
                derivativeNFTAsset.value = BigInt.fromI32(0)
            } else {
                //no change
            }
            derivativeNFTAsset.timestamp = event.block.timestamp
            derivativeNFTAsset.save()
        }
    }
}

export function handleTransferValue(event: TransferValue): void {
    log.info("handleTransferValue, event.address: {}, _fromTokenId:{},_toTokenId:{}, _value:{} ", [
        event.address.toHexString(),
        event.params._fromTokenId.toString(),
        event.params._toTokenId.toString(),
        event.params._value.toString()
    ])

    let _idString = event.params._fromTokenId.toString() + "-" + event.params._toTokenId.toHexString()+ "-" + event.block.timestamp.toString()
    const history = DerivativeNFTTransferValueHistory.load(_idString) || new DerivativeNFTTransferValueHistory(_idString)

    if (history) {
        history.fromTokenId = event.params._fromTokenId
        history.toTokenId = event.params._toTokenId
        history.value = event.params._value
        history.timestamp = event.block.timestamp
        history.save()

        const derivativeNFT = DerivativeNFT.bind(event.address) 

        if (event.params._fromTokenId.isZero()){
             //mint value

        } else {

            let _idStringAssetFrom = event.params._fromTokenId.toString()
            const derivativeNFTAssetFrom = DerivativeNFTAsset.load(_idStringAssetFrom) 
    
            if (derivativeNFTAssetFrom) {
               
                const result = derivativeNFT.try_balanceOf1(event.params._fromTokenId)
        
                if (result.reverted) {
                    log.warning('try_balanceOf1, result.reverted is true', [])
                } else {
                    log.info("try_balanceOf1, result.value: {}", [result.value.toString()])
                    derivativeNFTAssetFrom.value = result.value
                }
                
                derivativeNFTAssetFrom.timestamp = event.block.timestamp
                derivativeNFTAssetFrom.save()
            }
        }

        if (event.params._toTokenId.isZero()){
            //burn

        } else {
            
            let _idStringAssetTo = event.params._toTokenId.toString()
            const derivativeNFTAssetTo = DerivativeNFTAsset.load(_idStringAssetTo) || new DerivativeNFTAsset(_idStringAssetTo)
    
            if (derivativeNFTAssetTo) {

                const result = derivativeNFT.try_balanceOf1(event.params._toTokenId)
        
                if (result.reverted) {
                    log.warning('try_balanceOf1, result.reverted is true', [])
                } else {
                    log.info("try_balanceOf1, result.value: {}", [result.value.toString()])
                    derivativeNFTAssetTo.value = result.value
                }
                             
                derivativeNFTAssetTo.timestamp = event.block.timestamp
                derivativeNFTAssetTo.save()
            }
        }
    
    } 
}

export function handleSlotChanged(event: SlotChanged): void {
    log.info("handleSlotChanged, event.address: {}", [event.address.toHexString()])

    let _idString = event.params._tokenId.toString() + "-" + event.block.timestamp.toString()
    const history = DerivativeNFTSlotChangedHistory.load(_idString) || new DerivativeNFTSlotChangedHistory(_idString)

    if (history) {
        history.tokenId = event.params._tokenId
        history.oldSlot = event.params._oldSlot
        history.newSlot = event.params._newSlot
        history.timestamp = event.block.timestamp
        history.save()
    } 
}


export function handleBurnToken(event: BurnToken): void {
    log.info("handleBurnToken, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.tokenId.toString() + "-" + event.block.timestamp.toString()
    const history = BurnDerivativeNFTHistory.load(_idString) || new BurnDerivativeNFTHistory(_idString)

    if (history) {
        history.projectId = event.params.projectId
        history.tokenId = event.params.tokenId
        history.owner = event.params.owner
        history.timestamp = event.block.timestamp
        history.save()
    } 
}


export function handleApproval(event: Approval): void {
    log.info("handleApproval, event.address: {}", [event.address.toHexString()])

    let _idString = event.params._owner.toHexString() + "-" +  event.params._approved.toHexString()
    const approvalRecord = ApprovalRecord.load(_idString) || new ApprovalRecord(_idString)

    if (approvalRecord) {
        approvalRecord.owner = event.params._owner
        approvalRecord.approved = event.params._approved
        approvalRecord.tokenId = event.params._tokenId
        approvalRecord.timestamp = event.block.timestamp
        approvalRecord.save()
    } 
}

export function handleApprovalForAll(event: ApprovalForAll): void {
    log.info("handleApprovalForAll, event.address: {}", [event.address.toHexString()])

    let _idString = event.params._owner.toHexString() + "-" + event.params._operator.toHexString() 
    const approvalForAllRecord = ApprovalForAllRecord.load(_idString) || new ApprovalForAllRecord(_idString)

    if (approvalForAllRecord) {
        approvalForAllRecord.owner = event.params._owner
        approvalForAllRecord.operator = event.params._operator
        approvalForAllRecord.approved = event.params._approved
        approvalForAllRecord.timestamp = event.block.timestamp
        approvalForAllRecord.save()
    
    } 
}

export function handleApprovalValue(event: ApprovalValue): void {
    log.info("handleApprovalValue, event.address: {}", [event.address.toHexString()])

    let _idString = event.params._tokenId.toString() + "-" + event.params._operator.toHexString() 
    const approvalValueRecord = ApprovalValueRecord.load(_idString) || new ApprovalValueRecord(_idString)

    if (approvalValueRecord) {
        approvalValueRecord.tokenId = event.params._tokenId
        approvalValueRecord.operator = event.params._operator
        approvalValueRecord.value = event.params._value
        approvalValueRecord.timestamp = event.block.timestamp
        approvalValueRecord.save()
    
    } 
}


export function handleDerivativeNFTImageURISet(event: DerivativeNFTImageURISet): void {
    log.info("handleDerivativeNFTImageURISet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.tokenId.toString()
    const derivativeNFTImageURI = DerivativeNFTImageURI.load(_idString) || new DerivativeNFTImageURI(_idString)

    if (derivativeNFTImageURI) {
        derivativeNFTImageURI.tokenId = event.params.tokenId
        derivativeNFTImageURI.imageURI = event.params.imageURI
        derivativeNFTImageURI.timestamp = event.block.timestamp
        derivativeNFTImageURI.save()
    
    } 
}

