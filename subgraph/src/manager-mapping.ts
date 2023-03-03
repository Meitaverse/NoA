import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    EmergencyAdminSet,
    ManagerGovernanceSet,
    GlobalModulesSet,
    HubCreated,
    HubUpdated,
    PublishPrepared,
    PublishUpdated,
    PublishCreated,
    PublishMinted,
    DerivativeNFTCollected,
    DerivativeNFTDeployed,
    DerivativeNFTAirdroped,
    DispatcherSet,
    StateSet,
} from "../generated/Manager/Events"

import {
    ModuleGlobals
} from "../generated/Manager/ModuleGlobals"

import {
    ProtocolContract,
    EmergencyAdminSetHistory,
    ManagerGovernanceSetHistory,
    Hub,
    Publication,
    Publish,
    DnftCollectedHistory,
    Project,
    DnftAirdropedHistory,
    Dispatcher,
    StateSetHistory,
    Account,
    DNFT,
    PreparePublishFeesHistory,
} from "../generated/schema"

import { loadProject } from "./shared/project";
import { loadHub } from "./shared/hub";
import { loadOrCreatePublish } from "./shared/publish";
import { loadOrCreateAccount } from "./shared/accounts";
import { loadOrCreateDNFT, loadOrCreateDNFTContract, saveTransactionHashHistory } from "./dnft";
import { loadOrCreateSoulBoundToken } from "./shared/soulBoundToken";
import { getLogId } from "./shared/ids";
import { TREASURY_SBT_ID } from "./shared/constants";

export function handleEmergencyAdminSet(event: EmergencyAdminSet): void {
    log.info("handleEmergencyAdminSet, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = EmergencyAdminSetHistory.load(_idString) || new EmergencyAdminSetHistory(_idString)
    if (history) {
        history.caller = event.params.caller
        history.oldEmergencyAdmin = event.params.oldEmergencyAdmin
        history.newEmergencyAdmin = event.params.newEmergencyAdmin
        history.timestamp = event.block.timestamp
        history.save()
    } 

    saveTransactionHashHistory("EmergencyAdminSet", event);
}


export function handleManagerGovernanceSet(event: ManagerGovernanceSet): void {
    log.info("handleManagerGovernanceSet, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = ManagerGovernanceSetHistory.load(_idString) || new ManagerGovernanceSetHistory(_idString)
    if (history) {
        history.caller = event.params.caller
        history.prevGovernance = event.params.prevGovernance
        history.newGovernance = event.params.newGovernance
        history.timestamp = event.block.timestamp
        history.save()

        let _id = "Governance"
        const protocolContract = ProtocolContract.load(_id) || new ProtocolContract(_id)
        if (protocolContract) {
            protocolContract.contract = event.params.newGovernance
            protocolContract.save()        
        }
    } 

    saveTransactionHashHistory("ManagerGovernanceSet", event);
}

export function handleGlobalModulesSet(event: GlobalModulesSet): void {
    log.info("handleGlobalModulesSet, event.address: {}", [event.address.toHexString()])

 
    let _id = "GlobalModules"
    const protocolContract = ProtocolContract.load(_id) || new ProtocolContract(_id)
    if (protocolContract) {
        protocolContract.contract = event.params.globalModule
        protocolContract.save()        
    }
    saveTransactionHashHistory("GlobalModulesSet", event);
}

export function handleHubCreated(event: HubCreated): void {
    log.info("handleHubCreated, event.address: {}, hubOwner: {}", 
        [
            event.address.toHexString(),
            event.params.hubOwner.toHexString()
        ]
    )
    let _id = "GlobalModules"
    const protocolContract = ProtocolContract.load(_id) || new ProtocolContract(_id)
    if (protocolContract) {
             
        const moduleGlobals = ModuleGlobals.bind(Address.fromBytes(protocolContract.contract))
        const result = moduleGlobals.try_getHubInfo(event.params.hubId)
        if (result.reverted) {
            log.info("try_getHubInfo, result.reverted, hubId:{}", [event.params.hubId.toString()])
            return 
        }
    
        const hubOwner = loadOrCreateAccount(result.value.hubOwner)
        if (hubOwner) {
            const hub = new Hub(event.params.hubId.toString());
    
            hubOwner.hub = hub.id
            hub.hubOwner = hubOwner.id
            hub.hubId = event.params.hubId
            hub.name = result.value.name
            hub.description = result.value.description
            hub.imageURI = result.value.imageURI
            hub.timestamp = event.block.timestamp
            hub.save()
        }
    }
    saveTransactionHashHistory("HubCreated", event);
}

export function handleHubUpdated(event: HubUpdated): void {
    log.info("handleHubUpdated, event.address: {}", [event.address.toHexString()])
    let _id = "GlobalModules"
    const protocolContract = ProtocolContract.load(_id) || new ProtocolContract(_id)
    if (protocolContract) {
        const moduleGlobals = ModuleGlobals.bind(Address.fromBytes(protocolContract.contract))
        const result = moduleGlobals.try_getHubInfo(event.params.hubId)
        if (result.reverted) {
            log.info("try_getHubInfo, result.reverted", [])
            return 
        }

        const hub = loadHub(event.params.hubId) 
        if (hub) {
            hub.name = result.value.name
            hub.description =  result.value.description
            hub.imageURI = result.value.imageURI
            hub.timestamp = event.block.timestamp
            hub.save()
        }
    }
    saveTransactionHashHistory("HubUpdated", event);
}

export function handlePublishPrepared(event: PublishPrepared): void {
    log.info("handlePublishPrepared, publishId: {}, previousPublishId: {}", [
        event.params.publishId.toString(),
        event.params.previousPublishId.toString(),
    ])
    let _id = "GlobalModules"
    const protocolContract = ProtocolContract.load(_id) || new ProtocolContract(_id)
    if (protocolContract) {
        const moduleGlobals = ModuleGlobals.bind(Address.fromBytes(protocolContract.contract))

        const result = moduleGlobals.try_getPublication(event.params.publishId)
        if (result.reverted) {
            log.info("try_getPublication, result.reverted", [])
            return 
        }

        const sbt = loadOrCreateSoulBoundToken(result.value.soulBoundTokenId)
        if (sbt) {

            const publisher = loadOrCreateAccount(Address.fromBytes(sbt.wallet) )
            const hub = loadHub(result.value.hubId)
            const project = loadProject(result.value.projectId)
        
            if (publisher && hub && project) {
        
                let publication  = new Publication(event.params.publishId.toString());
            
                publication.publishId = event.params.publishId
                publication.publisher = publisher.id
                publication.hub = hub.id
                publication.project = project.id
                publication.salePrice = result.value.salePrice
                publication.royaltyBasisPoints = result.value.royaltyBasisPoints
                publication.currency = result.value.currency
                publication.amount = result.value.amount
                publication.name = result.value.name
                publication.description = result.value.description
                publication.canCollect = result.value.canCollect
                publication.materialURIs = result.value.materialURIs
                publication.collectModule = result.value.collectModule
                publication.collectModuleInitData = result.value.collectModuleInitData
                publication.publishModule = result.value.publishModule
                publication.publishModuleInitData = result.value.publishModuleInitData
                if (!event.params.previousPublishId.isZero()) {
                    publication.previousPublish = loadOrCreatePublish(event.params.previousPublishId).id
                }
                
                // publication.fromTokenIds = fromTokenIds
                if (result.value.fromTokenIds.length > 0 ) {
                    
                    let publicationFrom = Publication.load(result.value.projectId.toString())
                    if (publicationFrom) {
                            // publication.genesisPublishId = publicationFrom.genesisPublishId
                            publication.genesisPublish = publicationFrom.genesisPublish
                    }
                    
                    let fromDNFTs: Array<string> = [];

                    for (let index = 0; index <  result.value.fromTokenIds.length; index++) {
                        let tokenId = result.value.fromTokenIds[index]
                        let dnft = loadOrCreateDNFT(Address.fromString(project.derivativeNFT), tokenId, event);
                        if (dnft) {
                            fromDNFTs.push(dnft.id)
                        }
                    }
                    publication.fromTokenIds = fromDNFTs
                
                } 
                let _id = getLogId(event) + "-" + event.params.publishId.toString()
                let feesHistory = PreparePublishFeesHistory.load(_id) || new PreparePublishFeesHistory(_id)
                if (feesHistory) {
                    feesHistory.publisher = publisher.id
                    feesHistory.publication = publication.id
                    let treasury = loadOrCreateSoulBoundToken(TREASURY_SBT_ID)
                    feesHistory.treasury = loadOrCreateAccount(Address.fromBytes(treasury.wallet)).id
                    feesHistory.feesAmountOfPublish = event.params.publishTaxAmount
                }
                publication.publishTaxAmount = event.params.publishTaxAmount
                publication.timestamp = event.block.timestamp
                publication.save()
            
            }
        }
    }

    saveTransactionHashHistory("PublishPrepared", event);
}


export function handlePublishUpdated(event: PublishUpdated): void {
    log.info("handlePublishUpdated, event.address: {}", [event.address.toHexString()])

    let _id = "GlobalModules"
    const protocolContract = ProtocolContract.load(_id) || new ProtocolContract(_id)
    if (protocolContract) {
        const moduleGlobals = ModuleGlobals.bind(Address.fromBytes(protocolContract.contract))

        const result = moduleGlobals.try_getPublication(event.params.publishId)
        if (result.reverted) {
            log.info("try_getPublication, result.reverted", [])
            return 
        }
       

        let publication = Publication.load(event.params.publishId.toString());
        if (publication) {
            publication.salePrice = result.value.salePrice
            publication.royaltyBasisPoints = result.value.royaltyBasisPoints
            publication.amount = result.value.amount
            publication.name = result.value.name
            publication.description = result.value.description
            publication.materialURIs = result.value.materialURIs

            if (result.value.fromTokenIds.length > 0 ) {
                let publicationFrom = Publication.load(result.value.projectId.toString())
                if (publicationFrom) {
                    publication.genesisPublish = publicationFrom.genesisPublish
                }
            } else {

                const publish = loadOrCreatePublish(event.params.publishId);
                if (publish) {
                    let fromDNFTs: Array<string> = [];

                    for (let index = 0; index <  result.value.fromTokenIds.length; index++) {
                        let dnft = loadOrCreateDNFT(Address.fromString(publish.derivativeNFT), result.value.fromTokenIds[index], event);
                        if (dnft) {
                            fromDNFTs.push(dnft.id)
                        }
                    }
                    publication.fromTokenIds = fromDNFTs
                }
            }
            let _id = getLogId(event) + "-" + event.params.publishId.toString()
            let feesHistory = PreparePublishFeesHistory.load(_id) || new PreparePublishFeesHistory(_id)
            if (feesHistory) {
                feesHistory.publisher = publication.publisher
                feesHistory.publication = publication.id
                let treasury = loadOrCreateSoulBoundToken(TREASURY_SBT_ID)
                feesHistory.treasury = loadOrCreateAccount(Address.fromBytes(treasury.wallet)).id
                feesHistory.feesAmountOfPublish = feesHistory.feesAmountOfPublish.plus(event.params.addedPublishTaxes)
            }
            publication.publishTaxAmount = publication.publishTaxAmount.plus(event.params.addedPublishTaxes)
            publication.timestamp = event.block.timestamp
            publication.save()
        }
    }

    saveTransactionHashHistory("PublishUpdated", event);
}

export function handleDerivativeNFTDeployed(event: DerivativeNFTDeployed): void {
    log.info("handleDerivativeNFTDeployed, event.address: {}", [event.address.toHexString()])
    
    const hub = loadHub(event.params.hubId)
    if (hub) {
        let _id = "GlobalModules"
        const protocolContract = ProtocolContract.load(_id) || new ProtocolContract(_id)
        if (protocolContract) {
            const moduleGlobals = ModuleGlobals.bind(Address.fromBytes(protocolContract.contract))
            const result = moduleGlobals.try_getProjectInfo(event.params.projectId)
            if (result.reverted) {
                log.info("try_getProjectInfo, result.reverted", [])
                return 
            }
            const project = new Project(event.params.projectId.toString());
            project.projectId = event.params.projectId;
            project.projectCreator = loadOrCreateAccount(event.params.creator).id;
            project.hub = hub.id
            project.name = result.value.name
            project.description = result.value.description
            project.image = result.value.image
            project.metadataURI = result.value.metadataURI
            project.descriptor = result.value.descriptor
            project.defaultRoyaltyBPS = result.value.defaultRoyaltyPoints
            project.permitByHubOwner = result.value.permitByHubOwner
            project.derivativeNFT = loadOrCreateDNFTContract(event.params.derivativeNFT).id;
            project.timestamp = event.block.timestamp;
            project.save();
        }    
    }

    saveTransactionHashHistory("DerivativeNFTDeployed", event);
}

export function handlePublishCreated(event: PublishCreated): void {
    log.info("handlePublishCreated, event.address: {}", [event.address.toHexString()])
    
    const sbt = loadOrCreateSoulBoundToken(event.params.soulBoundTokenId)
    if (sbt) {

        const publisher = loadOrCreateAccount(Address.fromBytes(sbt.wallet) )
        const publication = Publication.load(event.params.publishId.toString());
        const hub = loadHub( event.params.hubId)
        const project = loadProject(event.params.projectId)

        if (publisher && publication && hub && project) {

            const publish = loadOrCreatePublish(event.params.publishId);
            if (publish) {
                publish.publisher = publisher.id
                publish.publication = publication.id
                publish.hub = hub.id
                publish.project = project.id
                publish.derivativeNFT = project.derivativeNFT 
                // publish.dnft = dnft.id
                // publish.newTokenId = event.params.newTokenId
                publish.amount = event.params.amount
                publish.collectModuleInitData = event.params.collectModuleInitData
                publish.timestamp = event.block.timestamp
                publish.save()
            }
        }
    }

    saveTransactionHashHistory("PublishCreated", event);
}

export function handlePublishMinted(event: PublishMinted): void {

    const publish = loadOrCreatePublish(event.params.publishId);
    if (publish) {
        publish.newTokenId = event.params.newTokenId
        let dnft = loadOrCreateDNFT(Address.fromString(publish.derivativeNFT), event.params.newTokenId, event);
        if (dnft) {
            publish.dnft = dnft.id

            log.info("handlePublishMinted, derivativeNFT: {}, publishId:{}, newTokenId:{}", [
                publish.derivativeNFT,
                event.address.toHexString(),
                event.params.publishId.toString(),
                event.params.newTokenId.toString(),
            ])
        }    
    }

    saveTransactionHashHistory("PublishMinted", event);
 
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
            
            let _idString = event.address.toHex() + "-" + event.params.projectId.toString() + "-" + event.params.tokenId.toString()
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
                history.timestamp = event.block.timestamp
                history.save()
            }

            //TODO royaltyAmounts
        } 
    }

    saveTransactionHashHistory("DerivativeNFTCollected", event);
}

export function handleDerivativeNFTAirdroped(event: DerivativeNFTAirdroped): void {
    log.info("handleDerivativeNFTAirdroped, event.address: {}", [event.address.toHexString()])
    
    let fromWallet = Address.zero()
    const sbtFrom = loadOrCreateSoulBoundToken(event.params.fromSoulBoundTokenId)
    if (sbtFrom) {
        fromWallet = Address.fromBytes(sbtFrom.wallet) 

        let _idString = getLogId(event)
        const history = DnftAirdropedHistory.load(_idString) || new DnftAirdropedHistory(_idString)
        if (history) {
            history.project = loadProject(event.params.projectId).id
            history.publish = loadOrCreatePublish(event.params.publishId).id
            history.derivativeNFT = loadOrCreateDNFTContract(event.params.derivativeNFT).id;
            history.from =  loadOrCreateAccount(fromWallet).id
            history.tokenId = event.params.tokenId
            history.values = event.params.values
            history.toAccounts = event.params.toSoulBoundTokenIds
            history.newTokenIds = event.params.newTokenIds
            history.timestamp = event.params.timestamp
            history.save()
        }
    }

    saveTransactionHashHistory("DerivativeNFTAirdroped", event);
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

    saveTransactionHashHistory("DispatcherSet", event);
}

export function handleStateSet(event: StateSet): void {
    log.info("handleStateSet, event.address: {}", [event.address.toHexString()])

    let _idString = getLogId(event)
    const history = StateSetHistory.load(_idString) || new StateSetHistory(_idString)
    if (history) {
        history.caller = event.params.caller
        history.prevState = event.params.prevState
        history.newState = event.params.newState
        history.timestamp = event.params.timestamp
        history.save()
    } 

    saveTransactionHashHistory("StateSet", event);
}
