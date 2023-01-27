// 

import { BigInt, Address } from "@graphprotocol/graph-ts";

import { Profile, SBTAsset } from "../../generated/schema";
import { ZERO_BIG_INT } from "./constants";

export function loadOrCreateSBTAsset(profile: Profile): SBTAsset {

    let addressHex = profile.wallet.toHex();

    let sbtAsset = SBTAsset.load(addressHex);
    if (!sbtAsset) {
        sbtAsset = new SBTAsset(addressHex);
        sbtAsset.profile = profile.id;
        sbtAsset.balance = ZERO_BIG_INT;
        sbtAsset.timestamp = ZERO_BIG_INT;
        sbtAsset.save();
    }
    return sbtAsset as SBTAsset;
}
