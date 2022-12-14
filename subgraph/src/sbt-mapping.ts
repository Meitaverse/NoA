import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    ProfileCreated,
    MintSBTValue,
    BankTreasurySet,
    ApprovalForSlot,
    BurnSBT,
    BurnSBTValue,
    ProfileImageURISet,
} from "../generated/SBT/Events"

import {
    SBT,
    Transfer,
    TransferValue,
    SlotChanged,
    Approval,
    ApprovalForAll,
    ApprovalValue,
} from "../generated/SBTERC3525/SBT"

import {
    Profile,
    MintSBTValueHistory,
    ApprovalForSlotHistory,
    BankTreasurySetHistory,
    BurnSBTHistory,
    BurnSBTValueHistory,
    ProfileImageURISetHistory,
    SBTTransferHistory,
    SBTAsset,
    SBTTransferValueHistory,
    SBTSlotChangedHistory,
    ApprovalRecord,
    ApprovalForAllRecord,
    ApprovalValueRecord,
} from "../generated/schema"

export function handleBankTreasurySet(event: BankTreasurySet): void {
    log.info("handleBankTreasurySet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = BankTreasurySetHistory.load(_idString) || new BankTreasurySetHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.bankTrerasury = event.params.bankTrerasury
        history.initialSupply = event.params.initialSupply
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handleProfileCreated(event: ProfileCreated): void {
    log.info("handleProfileCreated, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString()
    const profile = Profile.load(_idString) || new Profile(_idString)

    if (profile) {
        profile.soulBoundTokenId = event.params.soulBoundTokenId
        profile.creator = event.params.creator
        profile.wallet = event.params.wallet
        profile.nickName = event.params.nickName
        profile.imageURI = event.params.imageURI
        profile.isRemove = false
        profile.timestamp = event.params.timestamp
        profile.save()
        
    } 
}

export function handleMintSBTValue(event: MintSBTValue): void {
    log.info("handleMintSBTValue, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = MintSBTValueHistory.load(_idString) || new MintSBTValueHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.value = event.params.value
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handleApprovalForSlot(event: ApprovalForSlot): void {
    log.info("handleApprovalForSlot, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.owner.toHexString() + "-" + event.block.timestamp.toString()
    const history = ApprovalForSlotHistory.load(_idString) || new ApprovalForSlotHistory(_idString)

    if (history) {
        history.owner = event.params.owner
        history.slot = event.params.slot
        history.operator = event.params.operator
        history.approved = event.params.approved
        history.save()
        
    } 
}


export function handleBurnSBT(event: BurnSBT): void {
    log.info("handleBurnSBT, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = BurnSBTHistory.load(_idString) || new BurnSBTHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.timestamp = event.params.timestamp
        history.save()
        
    } 

    let _idStringProfile = event.params.soulBoundTokenId.toString()
    const profile = Profile.load(_idStringProfile)

    if (profile) {
        profile.soulBoundTokenId = event.params.soulBoundTokenId
        profile.isRemove = true
        profile.timestamp = event.params.timestamp
        profile.save()
        
    } 
}

export function handleBurnSBTValue(event: BurnSBTValue): void {
    log.info("handleBurnSBTValue, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = BurnSBTValueHistory.load(_idString) || new BurnSBTValueHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.value = event.params.value
        history.timestamp = event.params.timestamp
        history.save()
        
    } 
}

export function handleProfileImageURISet(event: ProfileImageURISet): void {
    log.info("handleProfileImageURISet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = ProfileImageURISetHistory.load(_idString) || new ProfileImageURISetHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.imageURI = event.params.imageURI
        history.timestamp = event.params.timestamp
        history.save()
        
    } 
}

export function handleSBTTransfer(event: Transfer): void {
    log.info("handleSBTTransfer, event.address: {}, _from: {}", [event.address.toHexString(), event.params._from.toHexString()])

    let _idString = event.params._from.toHexString() + "-" + event.params._to.toHexString()+ "-" + event.block.timestamp.toString()
    const history = SBTTransferHistory.load(_idString) || new SBTTransferHistory(_idString)

    if (history) {
        history.from = event.params._from
        history.to = event.params._to
        history.tokenId = event.params._tokenId
        history.timestamp = event.block.timestamp
        history.save()

        let _idStringSBTAsset = event.params._tokenId.toString()
        const sbtAsset = SBTAsset.load(_idStringSBTAsset) || new SBTAsset(_idStringSBTAsset)

        if (sbtAsset) {
            sbtAsset.wallet = event.params._to
            sbtAsset.soulBoundTokenId = event.params._tokenId
            if (event.params._from.toHexString() == '0x0000000000000000000000000000000000000000') {
                sbtAsset.value = BigInt.fromI32(0)
            } else {
                //no change
            }
            sbtAsset.timestamp = event.block.timestamp
            sbtAsset.save()
        }
    }
}

export function handleSBTTransferValue(event: TransferValue): void {
    log.info("handleSBTTransferValue, event.address: {}, _fromTokenId:{},_toTokenId:{}, _value:{} ", [
        event.address.toHexString(),
        event.params._fromTokenId.toString(),
        event.params._toTokenId.toString(),
        event.params._value.toString()
    ])

    let _idString = event.params._fromTokenId.toHexString() + "-" + event.params._toTokenId.toHexString()+ "-" + event.block.timestamp.toString()
    const history = SBTTransferValueHistory.load(_idString) || new SBTTransferValueHistory(_idString)

    if (history) {
        history.fromSoulBoundTokenId = event.params._fromTokenId
        history.toSoulBoundTokenId = event.params._toTokenId
        history.value = event.params._value
        history.timestamp = event.block.timestamp
        history.save()

        const sbt = SBT.bind(event.address) 

        if (event.params._fromTokenId.isZero()){
             //mint value

        } else {

            let _idStringSBTAssetFrom = event.params._fromTokenId.toString()
            const sbtAssetFrom = SBTAsset.load(_idStringSBTAssetFrom) //|| new SBTAsset(_idStringSBTAssetFrom)
    
            if (sbtAssetFrom) {
               
                const result = sbt.try_balanceOf1(event.params._fromTokenId)
        
                if (result.reverted) {
                    log.warning('try_balanceOf1, result.reverted is true', [])
                } else {
                    log.info("try_balanceOf1, result.value: {}", [result.value.toString()])
                    sbtAssetFrom.value = result.value
                }
                
                sbtAssetFrom.timestamp = event.block.timestamp
                sbtAssetFrom.save()
            }
        }

        if (event.params._toTokenId.isZero()){
            //burn

        } else {
            
            let _idStringSBTAssetTo = event.params._toTokenId.toString()
            const sbtAssetTo = SBTAsset.load(_idStringSBTAssetTo) || new SBTAsset(_idStringSBTAssetTo)
    
            if (sbtAssetTo) {

                const result = sbt.try_balanceOf1(event.params._toTokenId)
        
                if (result.reverted) {
                    log.warning('try_balanceOf1, result.reverted is true', [])
                } else {
                    log.info("try_balanceOf1, result.value: {}", [result.value.toString()])
                    sbtAssetTo.value = result.value
                }
                             
                sbtAssetTo.timestamp = event.block.timestamp
                sbtAssetTo.save()
            }

        }
    
    } 
}


export function handleSBTSlotChanged(event: SlotChanged): void {
    log.info("handleSBTSlotChanged, event.address: {}", [event.address.toHexString()])

    let _idString = event.params._tokenId.toHexString() + "-" + event.block.timestamp.toString()
    const history = SBTSlotChangedHistory.load(_idString) || new SBTSlotChangedHistory(_idString)

    if (history) {
        history.soulBoundTokenId = event.params._tokenId
        history.oldSlot = event.params._oldSlot
        history.newSlot = event.params._newSlot
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
