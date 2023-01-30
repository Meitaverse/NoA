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
} from "../../generated/DerivativeNFT/DerivativeNFT"

import {
    DnftTransfer,
    DnftCollection,
    DnftTransferValue,
    DnftSlotChanged,
    DnftBurn,
    DnftAccountApproval,
    DnftApprovalValue,
    DnftImageURI,
    DNFT,
} from "../../generated/schema"
import { loadOrCreateDNFTContract, loadOrCreateDNFT } from "../dnft";
import { ZERO_ADDRESS_STRING, ZERO_BIG_DECIMAL } from "../shared/constants";
import { loadOrCreateAccount } from "../shared/accounts";
import { recordNftEvent } from "../shared/events";
import { getLogId } from "../shared/ids";
import { loadProject } from "../shared/project";
import { loadOrCreateSoulBoundToken } from "../shared/soulBoundToken";
import { loadOrCreateDnftImageURI } from "../shared/dnftImageURI";

function getDNFTId(address: Address, id: BigInt): string {
    return address.toHex() + "-" + id.toString();
  }

export function handleDNFTTransfer(event: Transfer): void {
    log.info("handleDNFTTransfer, event.address: {}, _from: {}", [event.address.toHexString(), event.params._from.toHexString()])

    let dnftContract = loadOrCreateDNFTContract(event.address);

    let dnftId = getDNFTId(event.address, event.params._tokenId);
    let dnft: DNFT | null;
    if (event.params._from.toHex() == ZERO_ADDRESS_STRING) {
        // Mint
        dnft = new DNFT(dnftId);
        dnft.derivativeNFT = dnftContract.id;
        dnft.tokenId = event.params._tokenId;
        dnft.imageURI = loadOrCreateDnftImageURI(event.address, event.params._tokenId).id;
        dnft.dateMinted = event.block.timestamp;
        dnft.owner = loadOrCreateAccount(event.params._to).id;
        dnft.ownedOrListedBy = dnft.owner;
        dnft.netSalesInSBTValue = ZERO_BIG_DECIMAL;
        dnft.netSalesPendingInSBTValue = ZERO_BIG_DECIMAL;
        dnft.netRevenueInSBTValue = ZERO_BIG_DECIMAL;
        dnft.netRevenuePendingInSBTValue = ZERO_BIG_DECIMAL;
        dnft.isFirstSale = true;
        dnft.save();
        
    } else {
        // Transfer or Burn
        dnft = loadOrCreateDNFT(event.address, event.params._tokenId, event);
        dnft.owner = loadOrCreateAccount(event.params._to).id;
        dnft.ownedOrListedBy = dnft.owner;

        if (event.params._to.toHex() == ZERO_ADDRESS_STRING) {
        // Burn
        recordNftEvent(event, dnft as DNFT, "Burned", loadOrCreateAccount(event.params._from));
        } else {
        // Transfer
        recordNftEvent(
            event,
            dnft as DNFT,
            "Transferred",
            loadOrCreateAccount(event.params._from),
            null,
            null,
            null,
            loadOrCreateAccount(event.params._to),
        );
        }
    }

    let transfer = new DnftTransfer(getLogId(event));
    transfer.dnft = dnft.id;
    transfer.from = loadOrCreateAccount(event.params._from).id;
    transfer.to = loadOrCreateAccount(event.params._to).id;
    transfer.tokenId = event.params._tokenId;
    transfer.dateTransferred = event.block.timestamp;
    transfer.transactionHash = event.transaction.hash;
    transfer.save();

    if (event.params._from.toHex() == ZERO_ADDRESS_STRING) {
        dnft.mintedTransfer = transfer.id;
    }
    dnft.save();

}

export function handleDNFTTransferValue(event: TransferValue): void {
    log.info("handleDNFTTransferValue, event.address: {}, _fromTokenId:{},_toTokenId:{}, _value:{} ", [
        event.address.toHexString(),
        event.params._fromTokenId.toString(),
        event.params._toTokenId.toString(),
        event.params._value.toString()
    ])

    const sbtFrom = loadOrCreateSoulBoundToken(event.params._fromTokenId)
    const sbtTo = loadOrCreateSoulBoundToken(event.params._toTokenId)
    if (sbtFrom && sbtTo) {   
        
        let _idString = event.address.toHex() + "-" + event.params._fromTokenId.toString() + "-" + event.params._toTokenId.toHexString()
        const dnftTransferValue = DnftTransferValue.load(_idString) || new DnftTransferValue(_idString)
    
        if (dnftTransferValue) {
            let dnftFrom = loadOrCreateDNFT(event.address, event.params._fromTokenId, event);

            if (dnftFrom) {
                dnftTransferValue.dnft = dnftFrom.id
            }
            dnftTransferValue.from = loadOrCreateAccount(Address.fromBytes(sbtFrom.wallet)).id
            dnftTransferValue.to = loadOrCreateAccount(Address.fromBytes(sbtTo.wallet)).id
            dnftTransferValue.value = event.params._value
            dnftTransferValue.timestamp = event.block.timestamp
            dnftTransferValue.save()
    
            const derivativeNFT = DerivativeNFT.bind(event.address) 
    
            if (event.params._fromTokenId.isZero()){
                //mint value
    
            } else {
    
                let _idStringFrom = event.address.toHex() + "-" + event.params._fromTokenId.toString()
                const collectionFrom = DnftCollection.load(_idStringFrom) 
        
                if (collectionFrom) {
                    collectionFrom.owner = loadOrCreateAccount(Address.fromBytes(sbtFrom.wallet)).id
                    collectionFrom.tokenId = event.params._fromTokenId;
                    
                    const result2 = derivativeNFT.try_getPublishIdByTokenId(event.params._fromTokenId)
                    if (result2.reverted) {
                        log.warning('try_getPublishIdByTokenId, result2.reverted is true', [])
                    } else {
                        log.info("try_getPublishIdByTokenId, result2.value: {}", [result2.value.toString()])
                        collectionFrom.publish = loadProject(result2.value).id
                    }

                    if (dnftFrom) {
                        collectionFrom.dnft = dnftFrom.id
                    }
                    
                    const result = derivativeNFT.try_balanceOf1(event.params._fromTokenId)
                    if (result.reverted) {
                        log.warning('try_balanceOf1, result.reverted is true', [])
                        collectionFrom.value = collectionFrom.value.minus(event.params._value)
                    } else {
                        log.info("try_balanceOf1, result.value: {}", [result.value.toString()])
                        collectionFrom.value = result.value
                    }
                    
                    collectionFrom.timestamp = event.block.timestamp
                    collectionFrom.save()
                }
            }
    
            if (event.params._toTokenId.isZero()){
                //burn
    
            } else {
                
                let _idStringTo = event.address.toHex() + "-" + event.params._toTokenId.toString()
                const collectionTo = DnftCollection.load(_idStringTo) || new DnftCollection(_idStringTo)
        
                if (collectionTo) {
                    collectionTo.owner = loadOrCreateAccount(Address.fromBytes(sbtTo.wallet)).id
                    collectionTo.tokenId = event.params._toTokenId;

                    const result2 = derivativeNFT.try_getPublishIdByTokenId(event.params._toTokenId)
                    if (result2.reverted) {
                        log.warning('try_getPublishIdByTokenId, result2.reverted is true', [])
                    } else {
                        log.info("try_getPublishIdByTokenId, result2.value: {}", [result2.value.toString()])
                        collectionTo.publish = loadProject(result2.value).id
                    }


                    // let dnftIdTo = getDNFTId(event.address, event.params._toTokenId);
                    // let dnftTo = DNFT.load(dnftIdTo)
                    let dnftTo = loadOrCreateDNFT(event.address, event.params._toTokenId, event);
                    if (dnftTo) {
                        collectionTo.dnft = dnftTo.id
                    }
                    const result = derivativeNFT.try_balanceOf1(event.params._toTokenId)
            
                    if (result.reverted) {
                        log.warning('try_balanceOf1, result.reverted is true', [])
                        collectionTo.value = collectionTo.value.plus(event.params._value)

                    } else {
                        log.info("try_balanceOf1, result.value: {}", [result.value.toString()])
                        collectionTo.value = result.value
                    }
                                    
                    collectionTo.timestamp = event.block.timestamp
                    collectionTo.save()
                }
            }
        }
    }
}

export function handleDNFTSlotChanged(event: SlotChanged): void {
    log.info("handleDNFTSlotChanged, event.address: {}", [event.address.toHexString()])

    let dnftContract = loadOrCreateDNFTContract(event.address);
    let _idString = event.address.toHex() + "-" + event.params._tokenId.toString() + "-" + event.params._oldSlot.toString()
    const history = DnftSlotChanged.load(_idString) || new DnftSlotChanged(_idString)

    if (history) {
        history.derivativeNFT = dnftContract.id
        history.tokenId = event.params._tokenId
        history.oldSlot = event.params._oldSlot
        history.newSlot = event.params._newSlot
        history.timestamp = event.block.timestamp
        history.save()
    } 
}

export function handleDNFTBurnToken(event: BurnToken): void {
    log.info("handleDNFTBurnToken, event.address: {}", [event.address.toHexString()])

    let dnftContract = loadOrCreateDNFTContract(event.address);

    let project = loadProject(event.params.projectId);
    if (project) {

        let _idString = event.address.toHex() + "-" + event.params.tokenId.toString()
        const history = DnftBurn.load(_idString) || new DnftBurn(_idString)
    
        if (history) {
            history.derivativeNFT = dnftContract.id
            history.project = project.id
            history.tokenId = event.params.tokenId
            history.owner = loadOrCreateAccount(event.params.owner).id
            history.timestamp = event.block.timestamp
            history.save()
        } 
    }
}

export function handleDNFTApproval(event: Approval): void {
    log.info("handleDNFTApproval, event.address: {}", [event.address.toHexString()])

    let dnft = loadOrCreateDNFT(event.address, event.params._tokenId, event);
    if (event.params._approved != Address.zero()) {
        dnft.approvedSpender = loadOrCreateAccount(event.params._approved).id;
    } else {
        dnft.approvedSpender = null;
    }
    dnft.save();
}

export function handleDNFTApprovalForAll(event: ApprovalForAll): void {
    log.info("handleDNFTApprovalForAll, event.address: {}", [event.address.toHexString()])

    let id = event.address.toHex() + "-" + event.params._owner.toHex() + "-" + event.params._operator.toHex();
    if (event.params._approved) {
      let accountApproval = new DnftAccountApproval(id);
      let dnftContract = loadOrCreateDNFTContract(event.address);
      accountApproval.derivativeNFT = dnftContract.id;
      accountApproval.owner = loadOrCreateAccount(event.params._owner).id;
      accountApproval.spender = loadOrCreateAccount(event.params._operator).id;
      accountApproval.save();
    } else {
      store.remove("DnftAccountApproval", id);
    }
}

export function handleDNFTApprovalValue(event: ApprovalValue): void {
    log.info("handleApprovalValue, event.address: {}", [event.address.toHexString()])

    let dnftContract = loadOrCreateDNFTContract(event.address);
    const derivativeNFT = DerivativeNFT.bind(event.address) 

    const result = derivativeNFT.try_ownerOf(event.params._tokenId)
        
    if (result.reverted) {
        log.warning('try_balanceOf1, result.reverted is true', [])
    } else {
        log.info("try_balanceOf1, result.value: {}", [result.value.toString()])
        let owner = result.value

        let _idString = event.address.toHex() + "-" + owner.toHex() + "-" + event.params._operator.toHex();
        const approvalValueRecord = DnftApprovalValue.load(_idString) || new DnftApprovalValue(_idString)
        
        if (approvalValueRecord) {
            approvalValueRecord.tokenId = event.params._tokenId
            approvalValueRecord.derivativeNFT = dnftContract.id
            approvalValueRecord.owner = loadOrCreateAccount(owner).id
            approvalValueRecord.operator = loadOrCreateAccount(event.params._operator).id
            approvalValueRecord.value = event.params._value
            approvalValueRecord.timestamp = event.block.timestamp
            approvalValueRecord.save()
        } 
    }
}

export function handleDFTImageURISet(event: DerivativeNFTImageURISet): void {
    log.info("handleDNFTImageURISet, event.address: {}", [event.address.toHexString()])

    let dnftContract = loadOrCreateDNFTContract(event.address);
    let _idString = event.address.toHex() + "-" + event.params.tokenId.toString()
    const derivativeNFTImageURI = DnftImageURI.load(_idString) || new DnftImageURI(_idString)

    if (derivativeNFTImageURI) {
        derivativeNFTImageURI.tokenId = event.params.tokenId
        derivativeNFTImageURI.derivativeNFT = dnftContract.id
        derivativeNFTImageURI.imageURI = event.params.imageURI
        derivativeNFTImageURI.timestamp = event.block.timestamp
        derivativeNFTImageURI.save()
    }

}

