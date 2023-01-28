import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    ProfileCreated,
    MintSBTValue,
    BurnSBT,
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
    MintSBTValueHistory,
    BurnSBTHistory,
    SBTTransferHistory,
    SBTAsset,
    SBTTransferValueHistory,
    SBTSlotChangedHistory,
    SBTAccountApproval,
    SBTApprovalValue,
} from "../generated/schema"

import { BASIS_POINTS, ONE_BIG_INT, ZERO_ADDRESS_STRING, ZERO_BIG_DECIMAL, ZERO_BIG_INT } from "./shared/constants"; 
import { loadOrCreateProfile } from "./shared/profile";
import { loadOrCreateSBTAsset } from "./shared/sbtAsset";
import { loadOrCreateAccount } from "./shared/accounts";

export function handleProfileCreated(event: ProfileCreated): void {
    log.info("handleProfileCreated, event.address: {}", [event.address.toHexString()])

    const profile = loadOrCreateProfile(event.params.wallet);
    if (profile) {
        profile.soulBoundTokenId = event.params.soulBoundTokenId
        profile.creator = event.params.creator
        profile.wallet = event.params.wallet
        profile.nickName = event.params.nickName
        profile.imageURI = event.params.imageURI
        profile.timestamp = event.params.timestamp
        profile.save()
        
    } 
}

export function handleMintSBTValue(event: MintSBTValue): void {
    log.info("handleMintSBTValue, event.address: {}", [event.address.toHexString()])
    
    const sbt = SBT.bind(event.address) 
    const result = sbt.try_ownerOf(event.params.soulBoundTokenId)
    if (result.reverted) {
        log.warning('try_ownerOf, result.reverted is true', [])
    } else {
        log.info("try_ownerOf, result.value: {}", [result.value.toHex()])

        const account = loadOrCreateAccount(result.value)

        let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
        const history = MintSBTValueHistory.load(_idString) || new MintSBTValueHistory(_idString)
    
        if (history) {
            history.caller = event.params.caller
            history.account = account.id
            history.value = event.params.value
            history.timestamp = event.params.timestamp
            history.save()
        } 
    }
}

export function handleBurnSBT(event: BurnSBT): void {
    log.info("handleBurnSBT, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" + event.params.timestamp.toString()
    const history = BurnSBTHistory.load(_idString) || new BurnSBTHistory(_idString)

    const sbt = SBT.bind(event.address) 
    const result = sbt.try_ownerOf(event.params.soulBoundTokenId)
    if (result.reverted) {
        log.warning('try_ownerOf, result.reverted is true', [])
    } else {
        log.info("try_ownerOf, result.value: {}", [result.value.toHex()])

        const account = loadOrCreateAccount(result.value)
   
        if (history) {
            history.caller = event.params.caller
            history.account = account.id
            history.balance = event.params.balance
            history.timestamp = event.params.timestamp
            history.save()
        } 
        
    }
}

export function handleSBTTransfer(event: Transfer): void {
    log.info("handleSBTTransfer, event.address: {}, _from: {}", [event.address.toHexString(), event.params._from.toHexString()])

    let _idString = event.params._from.toHexString() + "-" + event.params._to.toHexString()+ "-" + event.block.timestamp.toString()
    const history = SBTTransferHistory.load(_idString) || new SBTTransferHistory(_idString)
    
    let from = loadOrCreateProfile(event.params._from)
    let to = loadOrCreateProfile(event.params._to)

    if (history) {
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
    let from = Address.zero();
    let to = Address.zero();

    if (!event.params._fromTokenId.isZero()) {
        const result = sbt.try_ownerOf(event.params._fromTokenId)
        if (result.reverted) {
            log.warning('try_ownerOf, result.reverted is true', [])
        } else {
            log.info("try_ownerOf, result.value: {}", [result.value.toHex()])
            from = result.value
           
            const sbtAsset_from = loadOrCreateSBTAsset(from)
    
            const result2 = sbt.try_balanceOf1(event.params._fromTokenId)
    
            if (result2.reverted) {
                log.warning('try_balanceOf1, result2.reverted is true', [])
                sbtAsset_from.balance = sbtAsset_from.balance.minus(event.params._value)
            } else {
                log.info("try_balanceOf1, result2.value: {}", [result2.value.toString()])
                sbtAsset_from.balance = result2.value
            }
            sbtAsset_from.timestamp = event.block.timestamp
            sbtAsset_from.save()
        }
    }

    if (!event.params._toTokenId.isZero()){
        const result = sbt.try_ownerOf(event.params._toTokenId)
        if (result.reverted) {
            log.warning('try_ownerOf, result.reverted is true', [])
        } else {
            log.info("try_ownerOf, result.value: {}", [result.value.toHex()])
            to = result.value
            
            const sbtAsset_to = loadOrCreateSBTAsset(to)
                
            const result2 = sbt.try_balanceOf1(event.params._toTokenId)
    
            if (result2.reverted) {
                log.warning('try_balanceOf1, result2.reverted is true', [])
                sbtAsset_to.balance = sbtAsset_to.balance.plus(event.params._value)
            } else {
                log.info("try_balanceOf1, result2.value: {}", [result2.value.toString()])
                sbtAsset_to.balance = result2.value
            }
            sbtAsset_to.timestamp = event.block.timestamp
            sbtAsset_to.save()
        }
    }

    let _idString = event.params._fromTokenId.toHexString() + "-" + event.params._toTokenId.toHexString()+ "-" + event.block.timestamp.toString()
    const history = SBTTransferValueHistory.load(_idString) || new SBTTransferValueHistory(_idString)

    if (history) {
        let account_from = loadOrCreateAccount(from)
        let account_to = loadOrCreateAccount(to)
        history.from = account_from.id
        history.to = account_to.id
        history.value = event.params._value
        history.timestamp = event.block.timestamp
        history.save()
    } 
}


export function handleSBTSlotChanged(event: SlotChanged): void {
    log.info("handleSBTSlotChanged, event.address: {}", [event.address.toHexString()])

    const sbt = SBT.bind(event.address) 
    const result = sbt.try_ownerOf(event.params._tokenId)
    if (result.reverted) {
        log.warning('try_ownerOf, result.reverted is true', [])
    } else {
        log.info("try_ownerOf, result.value: {}", [result.value.toHex()])

        const account = loadOrCreateAccount(result.value)

        let _idString = event.params._tokenId.toHexString() + "-" + event.block.timestamp.toString()
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
        const sbt = SBT.bind(event.address) 
        const result = sbt.try_ownerOf(event.params._tokenId)
        if (result.reverted) {
            log.warning('try_ownerOf, result.reverted is true', [])
        } else {
            log.info("try_ownerOf, result.value: {}", [result.value.toHex()])
            let owner = result.value
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
