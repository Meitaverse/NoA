import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    SBT,
    ProfileCreated,
    ProfileUpdated,
    Transfer,
    TransferValue,
    SlotChanged,
    Approval,
    ApprovalForAll,
    ApprovalValue,
} from "../generated/SBT/SBT"

import {
    SBTTransferHistory,
    SBTAsset,
    SBTTransferValueHistory,
    SBTSlotChangedHistory,
    SBTAccountApproval,
    SBTApprovalValue,
} from "../generated/schema"

import { BASIS_POINTS, ONE_BIG_INT, ZERO_ADDRESS_STRING, ZERO_BIG_INT } from "./shared/constants"; 
import { loadOrCreateProfile } from "./shared/profile";
import { loadOrCreateSBTAsset } from "./shared/sbtAsset";
import { loadOrCreateAccount } from "./shared/accounts";
import { loadOrCreateSoulBoundToken } from "./shared/soulBoundToken";
import { getLogId } from "./shared/ids";

export function handleProfileCreated(event: ProfileCreated): void {
    log.info("handleProfileCreated, event.address: {}, soulBoundTokenId:{}, wallet: {},nickName: {} ", [
        event.address.toHexString(),
        event.params.soulBoundTokenId.toString(),
        event.params.wallet.toHexString(),
        event.params.nickName,
    ])

    const profile = loadOrCreateProfile(event.params.wallet);
    if (profile) {
        profile.soulBoundTokenId = event.params.soulBoundTokenId
        profile.creator = event.params.creator
        profile.wallet = event.params.wallet
        profile.nickName = event.params.nickName
        profile.imageURI = event.params.imageURI
        profile.timestamp = event.block.timestamp
        profile.save()

        const sbt = loadOrCreateSoulBoundToken(event.params.soulBoundTokenId)
        if (sbt) {
            sbt.wallet = event.params.wallet
            sbt.save()
        }
        
    } 
}

export function handleProfileUpdated(event: ProfileUpdated): void {
    log.info("handleProfileUpdated, event.address: {}", [event.address.toHexString()])
    const sbt = loadOrCreateSoulBoundToken(event.params.soulBoundTokenId)
    if (sbt) {
        const profile = loadOrCreateProfile(Address.fromBytes(sbt.wallet));
        if (profile) {
            profile.nickName = event.params.nickName
            profile.imageURI = event.params.imageURI
            profile.timestamp = event.block.timestamp
            profile.save()
        }   
    } 
}


export function handleSBTTransfer(event: Transfer): void {
    log.info("handleSBTTransfer, event.address: {}, _from: {}, _to: {}", [
        event.address.toHexString(), 
        event.params._from.toHexString(),
        event.params._to.toHexString()
    ])

    let _idString = getLogId(event)
    const history = SBTTransferHistory.load(_idString) || new SBTTransferHistory(_idString)
    
    let from = loadOrCreateProfile(event.params._from)
    let to = loadOrCreateProfile(event.params._to)

    if (history) {
        history.sbtAsset = loadOrCreateSBTAsset(event.params._to).id
        history.from = from.id
        history.to = to.id
        history.tokenId = event.params._tokenId
        history.timestamp = event.block.timestamp
        history.save()
        
        if (event.params._from.toHexString() == ZERO_ADDRESS_STRING) {
            const sbtAsset_to = loadOrCreateSBTAsset(event.params._to)
            sbtAsset_to.balance = BigInt.fromI32(0)
            sbtAsset_to.timestamp = event.block.timestamp
            sbtAsset_to.save()
        
        }

        //burn
        if (event.params._to.toHexString() == ZERO_ADDRESS_STRING) {
            //remove 
            store.remove("Profile", event.params._from.toHex());
            store.remove("SBTAsset", event.params._from.toHex());
        
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

    const sbt = SBT.bind(event.address)
    let from = Address.zero()
    let to = Address.zero()

    if (!event.params._fromTokenId.isZero()) {
        //
        const sbtFrom = loadOrCreateSoulBoundToken(event.params._fromTokenId)
        if (sbtFrom) { 
            from = Address.fromBytes(sbtFrom.wallet) 
            log.info("loadOrCreateSoulBoundToken, from: {} ", [
                from.toHexString()
            ])

            
            const sbtAsset_from = loadOrCreateSBTAsset(from)
            const result2 = sbt.try_balanceOf1(event.params._fromTokenId)
            if (!result2.reverted) {
                log.info("try_balanceOf1, result2.value: {}", [result2.value.toString()])
                sbtAsset_from.balance = result2.value
            }
            sbtAsset_from.timestamp = event.block.timestamp
            sbtAsset_from.save()
        }
    }

    if (!event.params._toTokenId.isZero()){
        const sbtTo = loadOrCreateSoulBoundToken(event.params._toTokenId)
        if (sbtTo) {
            to = Address.fromBytes(sbtTo.wallet) 
            log.info("loadOrCreateSoulBoundToken, to: {} ", [
                to.toHexString()
            ])
            const sbtAsset_to = loadOrCreateSBTAsset(to)
                
            const result2 = sbt.try_balanceOf1(event.params._toTokenId)
    
            if (!result2.reverted) {
                log.info("try_balanceOf1, result2.value: {}", [result2.value.toString()])
                sbtAsset_to.balance = result2.value
            }
            sbtAsset_to.timestamp = event.block.timestamp
            sbtAsset_to.save()
        }
    }

    let _idStringFrom = getLogId(event) + "-" + from.toHex()
    const historyFrom = SBTTransferValueHistory.load(_idStringFrom) || new SBTTransferValueHistory(_idStringFrom)

    if (historyFrom) {
        let account_from = loadOrCreateAccount(from)
        let account_to = loadOrCreateAccount(to)
        historyFrom.sbtAsset = loadOrCreateSBTAsset(from).id
        historyFrom.from = account_from.id
        historyFrom.to = account_to.id
        historyFrom.value = event.params._value
        historyFrom.timestamp = event.block.timestamp
        historyFrom.save()
    } 

    let _idStringTo = getLogId(event) + "-" + to.toHex()
    const historyTo = SBTTransferValueHistory.load(_idStringTo) || new SBTTransferValueHistory(_idStringTo)

    if (historyTo) {
        let account_from = loadOrCreateAccount(from)
        let account_to = loadOrCreateAccount(to)
        historyTo.sbtAsset = loadOrCreateSBTAsset(to).id
        historyTo.from = account_from.id
        historyTo.to = account_to.id
        historyTo.value = event.params._value
        historyTo.timestamp = event.block.timestamp
        historyTo.save()
    } 
}

export function handleSBTSlotChanged(event: SlotChanged): void {
    log.info("handleSBTSlotChanged, event.address: {}", [event.address.toHexString()])

    const sbt = loadOrCreateSoulBoundToken(event.params._tokenId)
    if (sbt) {    
        let wallet = Address.fromBytes(sbt.wallet) 
        const account = loadOrCreateAccount(wallet)
        if (account) {

            let _idString = getLogId(event) 
            const history = SBTSlotChangedHistory.load(_idString) || new SBTSlotChangedHistory(_idString)
        
            if (history) {
                history.account = account.id
                history.oldSlot = event.params._oldSlot
                history.newSlot = event.params._newSlot
                history.timestamp = event.block.timestamp
                history.save()
            }
        }

    }
}

export function handleApproval(event: Approval): void {
    log.info("handleApproval, event.address: {}", [event.address.toHexString()])

    let sbtAsset = loadOrCreateSBTAsset(event.params._owner)
    if (event.params._approved != Address.zero()) {
        sbtAsset.approvedSpender = loadOrCreateAccount(event.params._approved).id;
    } else {
        sbtAsset.approvedSpender = null;
    }
    sbtAsset.save();

}

export function handleApprovalForAll(event: ApprovalForAll): void {
    log.info("handleApprovalForAll, event.address: {}", [event.address.toHexString()])

    let id = event.address.toHex() + "-" + event.params._owner.toHex() + "-" + event.params._operator.toHex();
    if (event.params._approved) {
      let sbtAccountApproval = new SBTAccountApproval(id);
      sbtAccountApproval.owner = loadOrCreateAccount(event.params._owner).id;
      sbtAccountApproval.spender = loadOrCreateAccount(event.params._operator).id;
      sbtAccountApproval.timestamp = event.block.timestamp;
      sbtAccountApproval.save();
    } else {
      store.remove("SBTAccountApproval", id);
    }
}

export function handleApprovalValue(event: ApprovalValue): void {
    log.info("handleApprovalValue, event.address: {}", [event.address.toHexString()])

    let _idString = event.address.toHex() + "-" + event.params._tokenId.toString() + "-" + event.params._operator.toHexString() 
    const sbtApprovalValue = SBTApprovalValue.load(_idString) || new SBTApprovalValue(_idString)
    if (sbtApprovalValue) {
        const sbt = loadOrCreateSoulBoundToken(event.params._tokenId)
        if (sbt) {   
            let owner = Address.fromBytes(sbt.wallet) 
            let sbtAssetOwner = loadOrCreateSBTAsset(owner)
            const spender = loadOrCreateAccount(event.params._operator)

            sbtApprovalValue.soulBoundTokenId = event.params._tokenId
            sbtApprovalValue.owner = sbtAssetOwner.id
            sbtApprovalValue.spender = spender.id
            sbtApprovalValue.value = event.params._value
            sbtApprovalValue.timestamp = event.block.timestamp
            sbtApprovalValue.save()
        } 
    }
}
