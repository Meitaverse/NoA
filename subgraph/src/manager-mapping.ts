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
    Publish,
    DnftCollectedHistory,
    Project,
    DerivativeNFTAirdropedHistory,
    Dispatcher,
    StateSetHistory,
    Account,
} from "../generated/schema"

import { loadProject } from "./shared/project";
import { loadHub } from "./shared/hub";
import { loadPublication } from "./shared/publication";
import { loadPublish } from "./shared/publish";
import { loadOrCreateAccount } from "./shared/accounts";
import { loadOrCreateDNFT, loadOrCreateDNFTContract } from "./dnft";
import { loadOrCreateSoulBoundToken } from "./shared/soulBoundToken";

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
    log.info("handleHubCreated, event.address: {}, hubOwner: {}", 
        [
            event.address.toHexString(),
            event.params.hubOwner.toHexString()
        ]
    )

    const hubOwner = loadOrCreateAccount(event.params.hubOwner)
    if (hubOwner) {
        const hub = new Hub(event.params.hubId.toString());

        hubOwner.hub = hub.id
        hub.hubOwner = hubOwner.id
        hub.hubId = event.params.hubId
        hub.name = event.params.name
        hub.description = event.params.description
        hub.imageURI = event.params.imageURI
        hub.timestamp = event.block.timestamp
        hub.save()
    }
}

export function handleHubUpdated(event: HubUpdated): void {
    log.info("handleHubUpdated, event.address: {}", [event.address.toHexString()])

    const hub = loadHub(event.params.hubId) 
    if (hub) {
        hub.name = event.params.name
        hub.description = event.params.description
        hub.imageURI = event.params.imageURI
        hub.timestamp = event.block.timestamp
        hub.save()
    }
}

export function handlePublishPrepared(event: PublishPrepared): void {
    log.info("handlePublishPrepared, event.address: {}", [event.address.toHexString()])

    let publisherAddr = Address.zero()

    const sbt = loadOrCreateSoulBoundToken(event.params.publication.soulBoundTokenId)
    if (sbt) {
        publisherAddr = Address.fromBytes(sbt.wallet) 

        const publisher = loadOrCreateAccount(publisherAddr)
        const hub = loadHub(event.params.publication.hubId)
        const project = loadProject(event.params.publication.projectId)
    
        if (publisher && hub && project) {
    
            let publication  = new Publication(event.params.publishId.toString());
            
            publication.publishId = event.params.publishId
            publication.publisher = publisher.id
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
  
    const hub = loadHub(event.params.hubId)
    if (hub) {
        const project = new Project(event.params.projectId.toString());
        project.projectId = event.params.projectId;
        project.projectCreator = projectCreator.id;
        project.hub = hub.id
        project.derivativeNFT = loadOrCreateDNFTContract(event.params.derivativeNFT).id;
        project.timestamp = event.block.timestamp;
        project.save();
    }
}

export function handlePublishCreated(event: PublishCreated): void {
    log.info("handlePublishCreated, event.address: {}", [event.address.toHexString()])
    
    let publisherAddr = Address.zero()
    const sbt = loadOrCreateSoulBoundToken(event.params.soulBoundTokenId)
    if (sbt) {
        publisherAddr = Address.fromBytes(sbt.wallet) 

        const publisher = loadOrCreateAccount(publisherAddr)
        const publication = Publication.load(event.params.publishId.toString());
        const hub = loadHub( event.params.hubId)
        const project = loadProject(event.params.projectId)
        let derivativeNFT = Address.fromHexString(project.derivativeNFT)
        let dnft = loadOrCreateDNFT(Address.fromBytes(derivativeNFT), event.params.newTokenId, event);
        

        if (publisher && publication && hub && project) {

            const publish = new Publish(event.params.publishId.toString());
            
            publish.publisher = publisher.id
            publish.publication = publication.id
            publish.hub = hub.id
            publish.project = project.id
            publish.derivativeNFT = project.derivativeNFT //loadOrCreateDNFTContract(Address.fromBytes(derivativeNFT)).id
            publish.dnft = dnft.id
            publish.newTokenId = event.params.newTokenId
            publish.amount = event.params.amount
            publish.collectModuleInitData = event.params.collectModuleInitData
            publish.timestamp = event.block.timestamp
            publish.save()
            
        }
    }
}

export function handleDerivativeNFTCollected(event: DerivativeNFTCollected): void {
    log.info("handleDerivativeNFTCollected, event.address: {}", [event.address.toHexString()])

    let fromWallet = Address.zero()
    let toWallet = Address.zero()
    const sbtFrom = loadOrCreateSoulBoundToken(event.params.fromSoulBoundTokenId)
    const sbtTo = loadOrCreateSoulBoundToken(event.params.toSoulBoundTokenId)
    if (sbtFrom && sbtTo) {
        fromWallet = Address.fromBytes(sbtFrom.wallet) 
        toWallet = Address.fromBytes(sbtTo.wallet) 

        const from = loadOrCreateAccount(fromWallet)
        const to =  loadOrCreateAccount(toWallet)
        const derivativeNFT = loadOrCreateDNFTContract(event.params.derivativeNFT)
        const project = loadProject(event.params.projectId)
        let dnft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
      
        if (from && to && derivativeNFT && project) {
            
            let _idString = event.params.derivativeNFT.toHex() + "-" + event.params.projectId.toString() + "-" + event.params.tokenId.toString()
            const history = DnftCollectedHistory.load(_idString) || new DnftCollectedHistory(_idString)
            if (history) {

                if (project) history.project = project.id
                if (derivativeNFT) history.derivativeNFT = derivativeNFT.id;
                if (from) history.from = from.id;
                if (to) history.to = to.id
                if (dnft) history.dnft = dnft.id
                history.tokenId = event.params.tokenId
                history.units = event.params.value
                history.newTokenId = event.params.newTokenId
                history.timestamp = event.params.timestamp
                history.save()
            }
        } 
    }
}

export function handleDerivativeNFTAirdroped(event: DerivativeNFTAirdroped): void {
    log.info("handleDerivativeNFTAirdroped, event.address: {}", [event.address.toHexString()])
    
    let fromWallet = Address.zero()
    const sbtFrom = loadOrCreateSoulBoundToken(event.params.fromSoulBoundTokenId)
    if (sbtFrom) {
        fromWallet = Address.fromBytes(sbtFrom.wallet) 
        const from = loadOrCreateAccount(fromWallet)
        const project = loadProject(event.params.projectId)

        if (from && project ) {
            let _idString = event.params.projectId.toString() + "-" + event.params.tokenId.toString() + "-" + event.params.timestamp.toString()
            const history = DerivativeNFTAirdropedHistory.load(_idString) || new DerivativeNFTAirdropedHistory(_idString)
            if (history) {
                history.project = project.id
                history.derivativeNFT = loadOrCreateDNFTContract(event.params.derivativeNFT).id;
                history.from = from.id
                history.tokenId = event.params.tokenId
                history.values = event.params.values
                history.toAccounts = event.params.toSoulBoundTokenIds
                history.newTokenIds = event.params.newTokenIds
                history.timestamp = event.params.timestamp
                history.save()
            }
        } 
    }
}

export function handleDispatcherSet(event: DispatcherSet): void {
    log.info("handleDispatcherSet, event.address: {}", [event.address.toHexString()])
   
    const sbt = loadOrCreateSoulBoundToken(event.params.soulBoundTokenId)
    if (sbt) {    

        const account = loadOrCreateAccount(Address.fromBytes(sbt.wallet) )
        if (account) {

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
