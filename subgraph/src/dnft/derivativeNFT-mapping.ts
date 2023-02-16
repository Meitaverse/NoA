import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    DerivativeNFT,
    Transfer,
    TransferValue,
    SlotChanged,
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
    Publish,
    SoulBoundToken,
    Account,
} from "../../generated/schema"
import { loadOrCreateDNFTContract, loadOrCreateDNFT } from "../dnft";
import { ZERO_ADDRESS_STRING, ZERO_BIG_DECIMAL, ZERO_BIG_INT } from "../shared/constants";
import { loadOrCreateAccount } from "../shared/accounts";
import { recordDnftEvent } from "../shared/events";
import { getLogId } from "../shared/ids";
import { loadProject } from "../shared/project";
import { loadOrCreateDnftImageURI } from "../shared/dnftImageURI";
import { loadOrCreatePublish } from "../shared/publish";
import { loadOrCreateCreator } from "../shared/creators";

function getDNFTId(address: Address, id: BigInt): string {
    return address.toHex() + "-" + id.toString();
  }


export function handleDNFTTransfer(event: Transfer): void {
    log.info("handleDNFTTransfer, event.address: {}, _from: {}, _to: {}, _tokenId: {}", [
        event.address.toHexString(), 
        event.params._from.toHexString(),
        event.params._to.toHexString(),
        event.params._tokenId.toString()
    ])
    
    const derivativeNFT = DerivativeNFT.bind(event.address) 

    const result = derivativeNFT.try_getPublishIdByTokenId(event.params._tokenId)
    if (result.reverted) {
        log.warning('In handleDNFTTransfer, try_getPublishIdByTokenId, result.reverted is true, _tokenId:{}', [event.params._tokenId.toString()])
    } else {
        log.info("In handleDNFTTransfer, try_getPublishIdByTokenId, _tokenId:{}, result.value: {}", [event.params._tokenId.toString(), result.value.toString()])
        
        let publish = loadOrCreatePublish(result.value)

        let dnftContract = loadOrCreateDNFTContract(event.address);

        if (event.params._from.toHex() == ZERO_ADDRESS_STRING && 
                event.params._to.toHex() != ZERO_ADDRESS_STRING) {
            log.info("_from is zero, mint DNFT", [])

            let dnftId = getDNFTId(event.address, event.params._tokenId);
    
            // Mint
            let dnft = new DNFT(dnftId);
            dnft.derivativeNFT = dnftContract.id;
            dnft.tokenId = event.params._tokenId;
            dnft.dateMinted = event.block.timestamp;
            dnft.project = publish.project
            dnft.publish = publish.id
            dnft.imageURI = loadOrCreateDnftImageURI(event.address, event.params._tokenId).id;
            dnft.owner = loadOrCreateAccount(event.params._to).id;

            let creatorResult = derivativeNFT.try_tokenCreator(event.params._tokenId);
            if (!creatorResult.reverted) {
              dnft.creator = loadOrCreateCreator(creatorResult.value).id;
            } 
            let pathResult = derivativeNFT.try_tokenURI(event.params._tokenId);
            if (!pathResult.reverted) {
              dnft.tokenIPFSPath = pathResult.value;
            }            
            dnft.ownedOrListedBy = dnft.owner;
            dnft.netSales = ZERO_BIG_INT;
            dnft.netSalesPending = ZERO_BIG_INT;
            dnft.netRevenue = ZERO_BIG_INT;
            dnft.netRevenuePending = ZERO_BIG_INT;
            dnft.isFirstSale = true;
            dnft.save();



            let creatorAccount = loadOrCreateAccount(event.params._to);
            recordDnftEvent(
                event, 
                dnft as DNFT, 
                "Minted", 
                creatorAccount, 
                null, 
                null, 
                null, 
                null, 
                creatorAccount
            );
            
        } 
        
        if (event.params._from.toHex() != ZERO_ADDRESS_STRING && 
                event.params._to.toHex() != ZERO_ADDRESS_STRING) {

            // Transfer
            log.info("recordDnftEvent", [])
            let dnft = loadOrCreateDNFT(event.address, event.params._tokenId, event);
            if (dnft) {

                // Transfer
                recordDnftEvent(
                    event,
                    dnft as DNFT,
                    "Transferred",
                    loadOrCreateAccount(event.params._from),
                    null,
                    null,
                    null,
                    null,
                    loadOrCreateAccount(event.params._to),
                );

              
                dnft.save();

            } else {
                log.info("handleDNFTTransfer,dnft=null", [])
            }
        }

        if (event.params._from.toHex() != ZERO_ADDRESS_STRING && 
                event.params._to.toHex() == ZERO_ADDRESS_STRING) {
            
            //Burn
            let dnft = loadOrCreateDNFT(event.address, event.params._tokenId, event);
            if (dnft) {
                    recordDnftEvent(
                        event,
                        dnft as DNFT,
                        "Burned",
                        loadOrCreateAccount(event.params._from)
                    );
            }
        }

        let dnftNew = loadOrCreateDNFT(event.address, event.params._tokenId, event)
        if (dnftNew) {
            log.info("DNFT check ok", [])

            let transfer = new DnftTransfer(getLogId(event));
            transfer.dnft = dnftNew.id;
            transfer.from = loadOrCreateAccount(event.params._from).id;
            transfer.to = loadOrCreateAccount(event.params._to).id;
            transfer.tokenId = event.params._tokenId;
            transfer.dateTransferred = event.block.timestamp;
            transfer.transactionHash = event.transaction.hash;
            transfer.save();
        
            if (event.params._from.toHex() == ZERO_ADDRESS_STRING) {
                dnftNew.mintedTransfer = transfer.id;
            }

        } else {
            log.info("DNFT check faild", [])
        }
    }
}

export function handleDNFTTransferValue(event: TransferValue): void {

    const derivativeNFT = DerivativeNFT.bind(event.address) 
   
    if (event.params._fromTokenId.isZero() && 
            !event.params._toTokenId.isZero())
    {
        log.info("handleDNFTTransferValue, mint value, event.address: {}, _fromTokenId:{},_toTokenId:{}, _value:{} ", [
            event.address.toHexString(),
            event.params._fromTokenId.toString(),
            event.params._toTokenId.toString(),
            event.params._value.toString()
        ])
    
        //mint value

        let _idStringTo = event.address.toHex() + "-" + event.params._toTokenId.toString()
        const collectionTo = DnftCollection.load(_idStringTo) || new DnftCollection(_idStringTo)

        if (collectionTo) {
            
            collectionTo.tokenId = event.params._toTokenId;

            let dnftTo = loadOrCreateDNFT(event.address, event.params._toTokenId, event);
            if (dnftTo) {
                collectionTo.owner = dnftTo.owner
                collectionTo.dnft = dnftTo.id
                log.info("dnftTo ---loadOrCreateDNFT ok, _toTokenId:{}", [
                    event.params._toTokenId.toString(),
                ])
            } else {
                log.info("Error: dnftTo ---loadOrCreateDNFT fail, _toTokenId:{}", [
                    event.params._toTokenId.toString(),
                ])
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

    if (!event.params._fromTokenId.isZero() && 
            !event.params._toTokenId.isZero())
    {
        log.info("handleDNFTTransferValue, transfer value, event.address: {}, _fromTokenId:{},_toTokenId:{}, _value:{} ", [
            event.address.toHexString(),
            event.params._fromTokenId.toString(),
            event.params._toTokenId.toString(),
            event.params._value.toString()
        ]) 
        
        let dnftFrom = loadOrCreateDNFT(event.address, event.params._fromTokenId, event);
        if (dnftFrom) {

            log.info("dnftFrom ---loadOrCreateDNFT, _fromTokenId:{}", [
                event.params._fromTokenId.toString(),
            ])
    
            let _idStringFrom = event.address.toHex() + "-" + event.params._fromTokenId.toString()
            const collectionFrom = DnftCollection.load(_idStringFrom) || new DnftCollection(_idStringFrom)
    
            if (collectionFrom) {
                collectionFrom.owner = dnftFrom.owner
                collectionFrom.dnft = dnftFrom.id
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
    
            } else {
                log.info("handleDNFTTransferValue,dnftFromIsnull",[])
            }
        }
    
        let fromAccount:Account| null;
        const resultTokenCreator = derivativeNFT.try_tokenCreator(event.params._fromTokenId)
        if (resultTokenCreator.reverted) {
            log.info("resultTokenCreator.reverted, _fromTokenId:", [event.params._fromTokenId.toString()])
            fromAccount = null
        } else {

            fromAccount = loadOrCreateAccount(resultTokenCreator.value)
        }
    
        let toAccount:Account | null
        const resultTokenCreatorTo = derivativeNFT.try_tokenCreator(event.params._toTokenId)
        if (resultTokenCreatorTo.reverted) {
            log.info("resultTokenCreatorTo.reverted, _toTokenId:", [event.params._toTokenId.toString()])
            toAccount = null
        } else {
            toAccount = loadOrCreateAccount(resultTokenCreatorTo.value)

        } 
        
        let dnft = loadOrCreateDNFT(event.address, event.params._fromTokenId, event);
        if (dnft) {
    
            let _idString = event.address.toHex() + "-" + event.params._fromTokenId.toString() + "-" + event.params._toTokenId.toString()
            const dnftTransferValue = DnftTransferValue.load(_idString) || new DnftTransferValue(_idString)
        
            if (dnftTransferValue) {
                dnftTransferValue.dnft = dnft.id
                if (fromAccount) {
                    dnftTransferValue.from = fromAccount.id
                }else {
                    dnftTransferValue.from = ZERO_ADDRESS_STRING
                }
                if (toAccount) {
                    dnftTransferValue.to = toAccount.id
                }else {
                    dnftTransferValue.to = ZERO_ADDRESS_STRING
                }
                dnftTransferValue.value = event.params._value
                dnftTransferValue.timestamp = event.block.timestamp
                dnftTransferValue.save()
            }
        
            recordDnftEvent(
                event,
                dnft as DNFT,
                "ValueTransferred",
                loadOrCreateAccount(resultTokenCreator.value),
                null,
                null,
                null,
                null,
                toAccount,
            );
        }
    }

    if (!event.params._fromTokenId.isZero() && 
        event.params._toTokenId.isZero())
    {
        //burn value

        log.info("handleDNFTTransferValue, burn value, event.address: {}, _fromTokenId:{},_toTokenId:{}, _value:{} ", [
            event.address.toHexString(),
            event.params._fromTokenId.toString(),
            event.params._toTokenId.toString(),
            event.params._value.toString()
        ])         
        const resultTokenCreator = derivativeNFT.try_tokenCreator(event.params._fromTokenId)
        if (resultTokenCreator.reverted) {
            log.info("resultTokenCreator.reverted, _fromTokenId:", [event.params._fromTokenId.toString()])
            return
        } 
        let fromAccount = loadOrCreateAccount(resultTokenCreator.value)
    
        let dnft = loadOrCreateDNFT(event.address, event.params._fromTokenId, event);
        if (dnft) {
            recordDnftEvent(
                event,
                dnft as DNFT,
                "ValueBurned",
                fromAccount,
            );
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


export function handleDNFTApproval(event: Approval): void {
    log.info("handleDNFTApproval, event.address: {}", [event.address.toHexString()])

    let dnft = loadOrCreateDNFT(event.address, event.params._tokenId, event);
    if(dnft) {

        if (event.params._approved != Address.zero()) {
            dnft.approvedSpender = loadOrCreateAccount(event.params._approved).id;
        } else {
            dnft.approvedSpender = null;
        }
        dnft.save();
    } else {
        log.info("handleDNFTApproval,dnftisnull", [])
    }
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

