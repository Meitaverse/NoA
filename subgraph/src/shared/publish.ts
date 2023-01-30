// 

import { Address, BigInt, Bytes } from "@graphprotocol/graph-ts";

import {  Publish } from "../../generated/schema";

export function loadPublish( publishId: BigInt): Publish {
    let record = Publish.load(publishId.toString());
    
    return record as Publish;
}
