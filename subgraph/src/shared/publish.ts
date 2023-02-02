// 

import { Address, BigInt, Bytes } from "@graphprotocol/graph-ts";

import {  Publish } from "../../generated/schema";
import { ZERO_BIG_INT } from "./constants";

export function loadOrCreatePublish(publishId: BigInt): Publish {
    let publish = Publish.load(publishId.toString());
    if (!publish) {
            publish = new Publish(publishId.toString());
                
            publish.publisher = ""
            publish.publication = ""
            publish.hub = ""
            publish.project = ""
            publish.derivativeNFT = ""
            publish.dnft = ""
            publish.newTokenId = ZERO_BIG_INT
            publish.amount = ZERO_BIG_INT
            publish.collectModuleInitData = Bytes.fromI32(0)
            publish.timestamp = ZERO_BIG_INT
            publish.save()
    }
    
    return publish as Publish;
  
}
