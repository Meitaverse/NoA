// 

import { BigInt, Address } from "@graphprotocol/graph-ts";

import { Profile, Hub, Account } from "../../generated/schema";
import { ZERO_BIG_INT } from "./constants";
import { loadOrCreateAccount } from "./accounts";

export function loadOrCreateHub(address: Address): Hub {

    let addressHex = address.toHex();

    let account = loadOrCreateAccount(address)

    let hub = Hub.load(addressHex);
    if (!hub) {
        hub = new Hub(addressHex);
        hub.hubOwner = account.id;
        hub.hubId = ZERO_BIG_INT;
        hub.name = '';
        hub.description = '';
        hub.imageURI = '';
        hub.timestamp = ZERO_BIG_INT;
        hub.save();
    }
    return hub as Hub;
}
