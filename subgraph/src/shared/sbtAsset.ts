// 

import { BigInt, Address } from "@graphprotocol/graph-ts";

import { Profile, SBTAsset } from "../../generated/schema";
import { ZERO_BIG_INT } from "./constants";
import { loadOrCreateAccount } from "./accounts";

export function loadOrCreateSBTAsset(address: Address): SBTAsset {

    let addressHex = address.toHex();
    let account = loadOrCreateAccount(address);

    let sbtAsset = SBTAsset.load(addressHex);
    if (!sbtAsset) {
        sbtAsset = new SBTAsset(addressHex);
        sbtAsset.owner = account.id;
        sbtAsset.balance = ZERO_BIG_INT;
        sbtAsset.timestamp = ZERO_BIG_INT;
        sbtAsset.save();
    }
    return sbtAsset as SBTAsset;
}
