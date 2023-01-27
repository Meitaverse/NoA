// 

import { BigInt, Address } from "@graphprotocol/graph-ts";

import { Profile, Hub } from "../../generated/schema";
import { ZERO_BIG_INT } from "./constants";
import { loadOrCreateProfile } from "./profile";

export function loadOrCreateHub(profile: Profile): Hub {

    let addressHex = profile.wallet.toHex();

    let hub = Hub.load(addressHex);
    if (!hub) {
        hub = new Hub(addressHex);
        hub.profile = profile.id;
        hub.hubId = ZERO_BIG_INT;
        hub.name = '';
        hub.description = '';
        hub.imageURI = '';
        hub.timestamp = ZERO_BIG_INT;
        hub.save();
    }
    return hub as Hub;
}
