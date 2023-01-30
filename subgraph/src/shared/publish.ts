// 

import { Address, BigInt, Bytes } from "@graphprotocol/graph-ts";

import { Account, Hub, Profile, Project, Publication, PublishRecord } from "../../generated/schema";
import { ZERO_BIG_INT } from "./constants";

export function loadOrCreatePublishRecord(publisher: Account, hub: Hub, project: Project, publication: Publication, publishId: BigInt): PublishRecord {
    let record = PublishRecord.load(publishId.toString());
    
    if (!record) {
        record = new PublishRecord(publishId.toString());
        record.publication = publication.id
        record.publisher = publisher.id;
        record.hub = hub.id;
        record.project = project.id;
        record.newTokenId = ZERO_BIG_INT;
        record.amount = ZERO_BIG_INT;
        record.collectModuleInitData = Bytes.fromI32(0);
        record.timestamp = ZERO_BIG_INT;
        record.save();
    }
    
    return record as PublishRecord;
}
