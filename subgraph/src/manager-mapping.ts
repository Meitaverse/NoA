import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    EmergencyAdminSet,
    ManagerGovernanceSet,
    HubCreated,
    HubUpdated,
    PublishPrepared,
    PublishUpdated,
    PublishCreated,
    DerivativeNFTCollected,
    DerivativeNFTDeployed,
    DerivativeNFTAirdroped,
    DispatcherSet,
    StateSet,
} from "../generated/Manager/Events"

import {
    Manager
} from "../generated/Manager/Manager"

import {
    EmergencyAdminSetHistory,
    ManagerGovernanceSetHistory,
    Hub,
    Publication,
    PublishRecord,
    DerivativeNFTCollectedHistory,
    Project,
    DerivativeNFTAirdropedHistory,
    Dispatcher,
    StateSetHistory,
} from "../generated/schema"

import { loadOrCreateProject } from "./shared/project";
import { loadOrCreateHub } from "./shared/hub";
import { loadOrCreateProfile } from "./shared/profile";
import { loadOrCreatePublication } from "./shared/publication";

export function handleEmergencyAdminSet(event: EmergencyAdminSet): void {
    log.info("handleEmergencyAdminSet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.caller.toHexString() + "-" +  event.params.timestamp.toString()
    const history = EmergencyAdminSetHistory.load(_idString) || new EmergencyAdminSetHistory(_idString)
    if (history) {
        history.caller = event.params.caller
        history.oldEmergencyAdmin = event.params.oldEmergencyAdmin
        history.newEmergencyAdmin = event.params.newEmergencyAdmin
        history.timestamp = event.block.timestamp
        history.save()
    } 
}

export function handleManagerGovernanceSet(event: ManagerGovernanceSet): void {
    log.info("handleManagerGovernanceSet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.caller.toHexString() + "-" +  event.params.timestamp.toString()
    const history = ManagerGovernanceSetHistory.load(_idString) || new ManagerGovernanceSetHistory(_idString)
    if (history) {
        history.caller = event.params.caller
        history.prevGovernance = event.params.prevGovernance
        history.newGovernance = event.params.newGovernance
        history.timestamp = event.block.timestamp
        history.save()
    } 
}

export function handleHubCreated(event: HubCreated): void {
    log.info("handleHubCreated, event.address: {}", [event.address.toHexString()])

    const profile = loadOrCreateProfile(event.params.creator)

    const hub = loadOrCreateHub(profile) 

    hub.profile = profile.id
    hub.hubId = event.params.hubId
    hub.name = event.params.name
    hub.description = event.params.description
    hub.imageURI = event.params.imageURI
    hub.timestamp = event.block.timestamp
    hub.save()
    
}

export function handleHubUpdated(event: HubUpdated): void {
    log.info("handleHubUpdated, event.address: {}", [event.address.toHexString()])

    const profile = loadOrCreateProfile(event.params.creator)

    const hub = loadOrCreateHub(profile) 

    hub.profile = profile.id
    hub.name = event.params.name
    hub.description = event.params.description
    hub.imageURI = event.params.imageURI
    hub.timestamp = event.block.timestamp
    hub.save()
}

export function handlePublishPrepared(event: PublishPrepared): void {
    log.info("handlePublishPrepared, event.address: {}", [event.address.toHexString()])

    const manager = Manager.bind(event.address) 
    const result = manager.try_getWalletBySoulBoundTokenId(event.params.publication.soulBoundTokenId)
    if (result.reverted) {
        log.warning('try_getWalletBySoulBoundTokenId, result.reverted is true', [])
    } else {
        log.info("try_getWalletBySoulBoundTokenId, result.value: {}", [result.value.toHex()])
        let creator = result.value
        const profile = loadOrCreateProfile(creator)

        const hub = loadOrCreateHub(profile)

        const result2 = manager.try_getDerivativeNFT(event.params.publication.projectId)
        if (result2.reverted) {
            log.warning('try_getDerivativeNFT, result.reverted is true', [])
        } else {
            let derivativeNFT = result2.value
            const project = loadOrCreateProject(profile, derivativeNFT)


            let publication = loadOrCreatePublication(creator, derivativeNFT,  event.params.publishId)
            if (publication) {
                publication.publishId = event.params.publishId
                publication.profile = profile.id
                publication.hub = hub.id
                publication.project = project.id
                publication.salePrice = event.params.publication.salePrice
                publication.royaltyBasisPoints = event.params.publication.royaltyBasisPoints
                publication.amount = event.params.publication.amount
                publication.name = event.params.publication.name
                publication.description = event.params.publication.description
                publication.canCollect = event.params.publication.canCollect
                publication.materialURIs = event.params.publication.materialURIs
                publication.fromTokenIds = event.params.publication.fromTokenIds
                publication.collectModule = event.params.publication.collectModule
                publication.collectModuleInitData = event.params.publication.collectModuleInitData
                publication.publishModule = event.params.publication.publishModule
                publication.publishModuleInitData = event.params.publication.publishModuleInitData
                publication.previousPublishId = event.params.previousPublishId
                if (event.params.publication.fromTokenIds.length > 0 ) {
                    const manager = Manager.bind(event.address) 
                    const result = manager.try_getGenesisPublishIdByProjectId(event.params.publication.projectId)
                        if (result.reverted) {
                            log.warning('try_getGenesisPublishIdByProjectId, result.reverted is true', [])
                        } else {
                            log.info("try_getGenesisPublishIdByProjectId ok, result.value: {}", [result.value.toString()])
                            publication.genesisPublishId = result.value
                        }
                } else {
                    publication.genesisPublishId = event.params.publishId
                }
                publication.publishTaxAmount = event.params.publishTaxAmount
                publication.timestamp = event.block.timestamp
                publication.save()
            } 
        }
    }
}

export function handlePublishUpdated(event: PublishUpdated): void {
    log.info("handlePublishUpdated, event.address: {}", [event.address.toHexString()])
    const manager = Manager.bind(event.address) 
    const result = manager.try_getWalletBySoulBoundTokenId(event.params.soulBoundTokenId)
    if (result.reverted) {
        log.warning('try_getWalletBySoulBoundTokenId, result.reverted is true', [])
    } else {
        log.info("try_getWalletBySoulBoundTokenId, result.value: {}", [result.value.toHex()])
        let creator = result.value
        const profile = loadOrCreateProfile(creator)

        const hub = loadOrCreateHub(profile)

        const result2 = manager.try_getDerivativeNFT(event.params.projectId)
        if (result2.reverted) {
            log.warning('try_getDerivativeNFT, result.reverted is true', [])
        } else {
            let derivativeNFT = result2.value
            const project = loadOrCreateProject(profile, derivativeNFT)

            let publication = loadOrCreatePublication(creator, derivativeNFT,  event.params.publishId)
            if (publication) {
                publication.salePrice = event.params.salePrice
                publication.royaltyBasisPoints = event.params.royaltyBasisPoints
                publication.amount = event.params.amount
                publication.name = event.params.name
                publication.description = event.params.description
                publication.materialURIs = event.params.materialURIs
                publication.fromTokenIds = event.params.fromTokenIds
                if (event.params.fromTokenIds.length > 0 ) {
                    const manager = Manager.bind(event.address) 
                    const result = manager.try_getGenesisPublishIdByProjectId(event.params.projectId)
                        if (result.reverted) {
                            log.warning('try_getGenesisPublishIdByProjectId, result.reverted is true', [])
                        } else {
                            log.info("try_getGenesisPublishIdByProjectId ok, result.value: {}", [result.value.toString()])
                            publication.genesisPublishId = result.value
                        }
                } else {
                    publication.genesisPublishId = event.params.publishId
                }
        
                publication.publishId = event.params.publishId
                publication.publishTaxAmount = publication.publishTaxAmount.plus(event.params.addedPublishTaxes)
                publication.timestamp = event.params.timestamp
                publication.save()
            } 
        
        }
    }

}

export function handleDerivativeNFTDeployed(event: DerivativeNFTDeployed): void {
    log.info("handleDerivativeNFTDeployed, event.address: {}", [event.address.toHexString()])
    const profile = loadOrCreateProfile(event.params.creator)
    
    const project = loadOrCreateProject(profile, event.params.derivativeNFT)
    if (project) {
        project.projectId = event.params.projectId
        project.profile = profile.id
        project.derivativeNFT = event.params.derivativeNFT
        project.timestamp = event.block.timestamp
        project.save()
    } 
}

export function handlePublishCreated(event: PublishCreated): void {
    log.info("handlePublishCreated, event.address: {}", [event.address.toHexString()])

    let _idString =  event.params.publishId.toString()
    const history = PublishRecord.load(_idString) || new PublishRecord(_idString)
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

export function handleDispatcherSet(event: DispatcherSet): void {
    log.info("handleDispatcherSet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.soulBoundTokenId.toString()
    const dispatcher = Dispatcher.load(_idString) || new Dispatcher(_idString)
    if (dispatcher) {
        dispatcher.soulBoundTokenId = event.params.soulBoundTokenId
        dispatcher.dispatcher = event.params.dispatcher
        dispatcher.timestamp = event.params.timestamp
        dispatcher.save()
    } 
}

export function handleStateSet(event: StateSet): void {
    log.info("handleStateSet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.caller.toHexString() + "-" + event.params.timestamp.toString()
    const history = StateSetHistory.load(_idString) || new StateSetHistory(_idString)
    if (history) {
        history.caller = event.params.caller
        history.prevState = event.params.prevState
        history.newState = event.params.newState
        history.timestamp = event.params.timestamp
        history.save()
    } 
}
