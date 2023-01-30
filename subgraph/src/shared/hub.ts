// 

import { BigInt, Address } from "@graphprotocol/graph-ts";

import { Profile, Hub, Account } from "../../generated/schema";
import { ZERO_BIG_INT } from "./constants";
import { loadOrCreateAccount } from "./accounts";

export function loadHub(hubId: BigInt): Hub {

    // let addressHex = address.toHex();

    // let account = loadOrCreateAccount(address)

    let hub = Hub.load(hubId.toString());
    // if (!hub) {
    //     hub = new Hub(hubId.toString());
    //     hub.hubOwner = account.id;
    //     hub.hubId = ZERO_BIG_INT;
    //     hub.name = '';
    //     hub.description = '';
    //     hub.imageURI = '';
    //     hub.timestamp = ZERO_BIG_INT;
    //     hub.save();
    // }
    return hub as Hub;
}
