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
import { loadOrCreatePublishRecord } from "./shared/publish";
import { loadOrCreateAccount } from "./shared/accounts";
import { loadOrCreateNFTContract } from "./dnft";

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

    const hubOwner = loadOrCreateAccount(event.params.creator)

    const hub = loadOrCreateHub(event.params.creator) 

    hub.hubOwner = hubOwner.id
    hub.hubId = event.params.hubId
    hub.name = event.params.name
    hub.description = event.params.description
    hub.imageURI = event.params.imageURI
    hub.timestamp = event.block.timestamp
    hub.save()
    
}

export function handleHubUpdated(event: HubUpdated): void {
    log.info("handleHubUpdated, event.address: {}", [event.address.toHexString()])

    const hubOwner = loadOrCreateAccount(event.params.creator)

    const hub = loadOrCreateHub(event.params.creator) 

    hub.hubOwner = hubOwner.id
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
        let publisher = result.value
        const profilePublisher = loadOrCreateAccount(publisher)
        
        const resultHubInfo = manager.try_getHubInfo(event.params.publication.hubId)
        if (!resultHubInfo.reverted) {
            
            const hubOwner = loadOrCreateAccount(resultHubInfo.value.hubOwner)
    
            const hub = loadOrCreateHub(resultHubInfo.value.hubOwner)

            const project = loadOrCreateProject(event.params.publication.projectId)

            let publication = loadOrCreatePublication(event.params.publishId)
            if (publication) {
                publication.publishId = event.params.publishId
                publication.publisher = profilePublisher.id
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

    let publication = Publication.load(event.params.publishId.toString());
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

        publication.publishTaxAmount = publication.publishTaxAmount.plus(event.params.addedPublishTaxes)
        publication.timestamp = event.params.timestamp
        publication.save()
    }

}

export function handleDerivativeNFTDeployed(event: DerivativeNFTDeployed): void {
    log.info("handleDerivativeNFTDeployed, event.address: {}", [event.address.toHexString()])
    const projectCreator = loadOrCreateAccount(event.params.creator)
    
    //TODO try_getProjectInfo

    const project = loadOrCreateProject(event.params.projectId)
    if (project) {
        project.projectId = event.params.projectId
        project.projectCreator = projectCreator.id
        project.derivativeNFT = loadOrCreateNFTContract(event.params.derivativeNFT).id; 
        project.timestamp = event.block.timestamp
        project.save()
    } 
}

export function handlePublishCreated(event: PublishCreated): void {
    log.info("handlePublishCreated, event.address: {}", [event.address.toHexString()])

    const manager = Manager.bind(event.address) 
    const result = manager.try_getWalletBySoulBoundTokenId(event.params.soulBoundTokenId)
    if (result.reverted) {
        log.warning('try_getWalletBySoulBoundTokenId, result.reverted is true', [])
    } else {
        log.info("try_getWalletBySoulBoundTokenId, result.value: {}", [result.value.toHex()])
        let publisherAddr = result.value
        const publisher = loadOrCreateAccount(publisherAddr)
        let publication = Publication.load(event.params.publishId.toString());
       
        const resultHubInfo = manager.try_getHubInfo(event.params.hubId)
        if (!resultHubInfo.reverted) {
            
            const hubOwner = loadOrCreateAccount(resultHubInfo.value.hubOwner)
    
            const hub = loadOrCreateHub(resultHubInfo.value.hubOwner)
           
            const project = loadOrCreateProject(event.params.projectId)
            
            const publishRecord = loadOrCreatePublishRecord(
                publisher, 
                hub, 
                project, 
                event.params.publishId
            ) 
            
            if (publishRecord) {
                publishRecord.publisher = publisher.id
                if (publication) publishRecord.publication = publication.id
                publishRecord.hub = hub.id
                publishRecord.project = project.id
                publishRecord.newTokenId = event.params.newTokenId
                publishRecord.amount = event.params.amount
                publishRecord.collectModuleInitData = event.params.collectModuleInitData
                publishRecord.timestamp = event.block.timestamp
                publishRecord.save()
            } 
            
        }
    }
}

export function handleDerivativeNFTCollected(event: DerivativeNFTCollected): void {
    log.info("handleDerivativeNFTCollected, event.address: {}", [event.address.toHexString()])

    const manager = Manager.bind(event.address) 

    const resultFrom = manager.try_getWalletBySoulBoundTokenId(event.params.fromSoulBoundTokenId)
    const resultTo = manager.try_getWalletBySoulBoundTokenId(event.params.toSoulBoundTokenId)

    if (!resultFrom.reverted && !resultTo.reverted) {
        const project = loadOrCreateProject(event.params.projectId)

        let _idString = event.params.projectId.toString() + "-" + event.params.tokenId.toString() + "-" + event.params.timestamp.toString()
        const history = DerivativeNFTCollectedHistory.load(_idString) || new DerivativeNFTCollectedHistory(_idString)
        if (history) {
            history.project = project.id
            history.derivativeNFT = loadOrCreateNFTContract(event.params.derivativeNFT).id;
            history.from = loadOrCreateAccount(resultFrom.value).id
            history.to = loadOrCreateAccount(resultTo.value).id
            history.tokenId = event.params.tokenId
            history.units = event.params.value
            history.newTokenId = event.params.newTokenId
            history.timestamp = event.params.timestamp
            history.save()
        } 
    }
}

export function handleDerivativeNFTAirdroped(event: DerivativeNFTAirdroped): void {
    log.info("handleDerivativeNFTAirdroped, event.address: {}", [event.address.toHexString()])
    
    const manager = Manager.bind(event.address) 
    const resultFrom = manager.try_getWalletBySoulBoundTokenId(event.params.fromSoulBoundTokenId)
    if (!resultFrom.reverted) {

        const from = loadOrCreateAccount(resultFrom.value)

        const project = loadOrCreateProject(event.params.projectId)

        let _idString = event.params.projectId.toString() + "-" + event.params.tokenId.toString() + "-" + event.params.timestamp.toString()
        const history = DerivativeNFTAirdropedHistory.load(_idString) || new DerivativeNFTAirdropedHistory(_idString)
        if (history) {
            history.project = project.id
            history.derivativeNFT = loadOrCreateNFTContract(event.params.derivativeNFT).id;
            history.from = from.id
            history.tokenId = event.params.tokenId
            for (let index = 0; index <  event.params.toSoulBoundTokenIds.length; index++) {
                let result = manager.try_getWalletBySoulBoundTokenId(event.params.toSoulBoundTokenIds[index])
                if (!result.reverted) {
                    let to = loadOrCreateAccount(resultFrom.value).id
                    history.toAccounts[index] = to
                }
            }
            history.values = event.params.values
            history.newTokenIds = event.params.newTokenIds
            history.timestamp = event.params.timestamp
            history.save()
        } 
    }
}

export function handleDispatcherSet(event: DispatcherSet): void {
    log.info("handleDispatcherSet, event.address: {}", [event.address.toHexString()])
   
    const manager = Manager.bind(event.address) 
    const result = manager.try_getWalletBySoulBoundTokenId(event.params.soulBoundTokenId)
    if (!result.reverted) {

        const account = loadOrCreateAccount(result.value)

        let _idString = event.params.soulBoundTokenId.toString()
        const dispatcher = Dispatcher.load(_idString) || new Dispatcher(_idString)
        
        if (dispatcher) {
            dispatcher.account = account.id
            dispatcher.dispatcher = event.params.dispatcher
            dispatcher.timestamp = event.params.timestamp
            dispatcher.save()
        }
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
