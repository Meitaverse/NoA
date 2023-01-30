// 

import { Address, BigInt, Bytes, ethereum, store } from "@graphprotocol/graph-ts";

import { Publication } from "../../generated/schema";
import { ZERO_ADDRESS_STRING, ZERO_BIG_INT, ZERO_BYTES_32_STRING } from "./constants";
import { loadOrCreateAccount } from "./accounts";
import { loadHub } from "./hub";
import { loadProject } from "./project";

export function createPublication(
  publisherAddress: Address, 
  hubId: BigInt, projectId: 
  BigInt, publishId: BigInt
): Publication {
  let publication = Publication.load(publishId.toString());

  if (!publication) {
    const publisher = loadOrCreateAccount(publisherAddress)
    const hub = loadHub(hubId)
    const project = loadProject(projectId)

    if (publisher && hub && project) {
      
      publication = new Publication(publishId.toString());
      publication.publishId = publishId;
      publication.publisher = publisher.id;
      publication.hub = hub.id;
      publication.project = project.id;
      publication.salePrice = ZERO_BIG_INT;
      publication.royaltyBasisPoints = ZERO_BIG_INT;
      publication.amount = ZERO_BIG_INT;
      publication.name = '';
      publication.description = '';
      publication.canCollect = true;
      publication.materialURIs = [];
      publication.fromTokenIds = [];
      publication.collectModule = Address.zero();
      publication.collectModuleInitData = Bytes.fromI32(0);
      publication.publishModule = Address.zero();
      publication.publishModuleInitData = Bytes.fromI32(0);
      publication.genesisPublishId = ZERO_BIG_INT;
      publication.previousPublishId = ZERO_BIG_INT;
      publication.publishTaxAmount = ZERO_BIG_INT;
      publication.timestamp = ZERO_BIG_INT;
      publication.save();
    }

  }
  return publication as Publication;
}


/**
  publishId: BigInt!

  #soulBoundTokenId: BigInt!
  profile: Profile!

  hub: Hub!

  project: Project!

  salePrice: BigInt!
  royaltyBasisPoints: BigInt!
  amount: BigInt!
  name: String!
  description: String!
  canCollect: Boolean!
  materialURIs: [String!]!
  fromTokenIds: [BigInt!]!
  collectModule: Bytes!
  collectModuleInitData: Bytes!
  publishModule: Bytes!
  publishModuleInitData: Bytes!

  genesisPublishId: BigInt!
  previousPublishId: BigInt!
  publishTaxAmount: BigInt!
  timestamp: BigInt!

 */