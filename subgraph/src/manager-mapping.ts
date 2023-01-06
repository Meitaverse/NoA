import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    TransferDerivativeNFT,
    TransferValueDerivativeNFT,
    HubCreated,
    GenerateVoucher,
    PublishPrepared,
    PublishCreated,
    DerivativeNFTCollected,
    DerivativeNFTDeployed,
    DerivativeNFTAirdroped,
} from "../generated/Manager/Events"

import {
    DerivativeNFTTransferHistory,
    DerivativeNFTTransferValueHistory,
    Hub,
    Publication,
    PublishCreatedHistory,
    DerivativeNFTCollectedHistory,
    Project,
    DerivativeNFTAirdropedHistory,
} from "../generated/schema"

export function handleTransferDerivativeNFT(event: TransferDerivativeNFT): void {
    log.info("handleTransferDerivativeNFT, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.tokenId.toString() + "-" +  event.params.timestamp.toString()
    const history = DerivativeNFTTransferHistory.load(_idString) || new DerivativeNFTTransferHistory(_idString)
    if (history) {
        history.fromSoulBoundTokenId = event.params.fromSoulBoundTokenId
        history.toSoulBoundTokenId = event.params.toSoulBoundTokenId
        history.projectId = event.params.projectId
        history.tokenId = event.params.tokenId
        history.timestamp = event.block.timestamp
        history.save()
    } 
}

export function handleTransferValueDerivativeNFT(event: TransferValueDerivativeNFT): void {
    log.info("handleTransferValueDerivativeNFT, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.tokenId.toString() + "-" +  event.params.timestamp.toString()
    const history = DerivativeNFTTransferValueHistory.load(_idString) || new DerivativeNFTTransferValueHistory(_idString)
    if (history) {
        history.fromSoulBoundTokenId = event.params.fromSoulBoundTokenId
        history.toSoulBoundTokenId = event.params.toSoulBoundTokenId
        history.projectId = event.params.projectId
        history.tokenId = event.params.tokenId
        history.value = event.params.value
        history.newTokenId = event.params.newTokenId    
        history.timestamp = event.block.timestamp
        history.save()
    } 
}

export function handleHubCreated(event: HubCreated): void {
    log.info("handleHubCreated, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" +  event.params.hubId.toString()
    const hub = Hub.load(_idString) || new Hub(_idString)
    if (hub) {
        hub.soulBoundTokenId = event.params.soulBoundTokenId
        hub.creator = event.params.creator
        hub.hubId = event.params.hubId
        hub.name = event.params.name
        hub.description = event.params.description
        hub.imageURI = event.params.imageURI
        hub.timestamp = event.block.timestamp
        hub.save()
    } 
}

export function handlePublishPrepared(event: PublishPrepared): void {
    log.info("handlePublishPrepared, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.publication.soulBoundTokenId.toString() + "-" +  event.params.publishId.toString()
    const publication = Publication.load(_idString) || new Publication(_idString)
    if (publication) {
        publication.soulBoundTokenId = event.params.publication.soulBoundTokenId
        publication.hubId = event.params.publication.hubId
        publication.projectId = event.params.publication.projectId
        publication.salePrice = event.params.publication.salePrice
        publication.royaltyBasisPoints = event.params.publication.royaltyBasisPoints
        publication.amount = event.params.publication.amount
        publication.name = event.params.publication.name
        publication.description = event.params.publication.description
        publication.materialURIs = event.params.publication.materialURIs
        publication.fromTokenIds = event.params.publication.fromTokenIds
        publication.collectModule = event.params.publication.collectModule
        publication.collectModuleInitData = event.params.publication.collectModuleInitData
        publication.publishModule = event.params.publication.publishModule
        publication.publishModuleInitData = event.params.publication.publishModuleInitData
        publication.publishId = event.params.publishId
        publication.previousPublishId = event.params.previousPublishId
        publication.publishTaxAmount = event.params.publishTaxAmount
        publication.timestamp = event.params.timestamp
        publication.save()
    } 

}

export function handleDerivativeNFTDeployed(event: DerivativeNFTDeployed): void {
    log.info("handleDerivativeNFTDeployed, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" +  event.params.projectId.toString()
    const project = Project.load(_idString) || new Project(_idString)
    if (project) {
        project.soulBoundTokenId = event.params.soulBoundTokenId
        project.projectId = event.params.projectId
        project.derivativeNFT = event.params.derivativeNFT
        project.timestamp = event.block.timestamp
        project.save()
    } 
}

export function handlePublishCreated(event: PublishCreated): void {
    log.info("handlePublishCreated, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString() + "-" +  event.params.publishId.toString()
    const history = PublishCreatedHistory.load(_idString) || new PublishCreatedHistory(_idString)
    if (history) {
        history.publishId = event.params.publishId
        history.soulBoundTokenId = event.params.soulBoundTokenId
        history.hubId = event.params.hubId
        history.projectId = event.params.projectId
        history.newTokenId = event.params.newTokenId
        history.amount = event.params.amount
        history.collectModuleInitData = event.params.collectModuleInitData
        history.timestamp = event.block.timestamp
        history.save()
    } 
}

export function handleDerivativeNFTCollected(event: DerivativeNFTCollected): void {
    log.info("handleDerivativeNFTCollected, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.projectId.toString() + "-" + event.params.tokenId.toString() + "-" + event.params.timestamp.toString()
    const history = DerivativeNFTCollectedHistory.load(_idString) || new DerivativeNFTCollectedHistory(_idString)
    if (history) {
        history.projectId = event.params.projectId
        history.derivativeNFT = event.params.derivativeNFT
        history.fromSoulBoundTokenId = event.params.fromSoulBoundTokenId
        history.toSoulBoundTokenId = event.params.toSoulBoundTokenId
        history.tokenId = event.params.tokenId
        history.value = event.params.value
        history.newTokenId = event.params.newTokenId
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

export function handleDerivativeNFTAirdroped(event: DerivativeNFTAirdroped): void {
    log.info("handleDerivativeNFTAirdroped, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.projectId.toString() + "-" + event.params.tokenId.toString() + "-" + event.params.timestamp.toString()
    const history = DerivativeNFTAirdropedHistory.load(_idString) || new DerivativeNFTAirdropedHistory(_idString)
    if (history) {
        history.projectId = event.params.projectId
        history.derivativeNFT = event.params.derivativeNFT
        history.fromSoulBoundTokenId = event.params.fromSoulBoundTokenId
        history.tokenId = event.params.tokenId
        history.toSoulBoundTokenIds = event.params.toSoulBoundTokenIds
        history.values = event.params.values
        history.newTokenIds = event.params.newTokenIds
        history.timestamp = event.params.timestamp
        history.save()
    } 
}

