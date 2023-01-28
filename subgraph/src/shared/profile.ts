// 

import { Address } from "@graphprotocol/graph-ts";

import { Profile } from "../../generated/schema";
import { ZERO_BIG_INT } from "./constants";

export function loadOrCreateProfile(address: Address): Profile {
  let addressHex = address.toHex();
  let profile = Profile.load(addressHex);
  if (!profile) {
    profile = new Profile(addressHex);
    profile.wallet = address;
    profile.soulBoundTokenId = ZERO_BIG_INT;
    profile.nickName = '';
    profile.imageURI = '';
    profile.timestamp = ZERO_BIG_INT;
    profile.save();
  }
  return profile as Profile;
}
