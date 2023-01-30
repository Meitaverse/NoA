// 

import { log, Address, BigInt } from "@graphprotocol/graph-ts";

import { SoulBoundToken } from "../../generated/schema";

export function loadOrCreateSoulBoundToken(soulBoundTokenId: BigInt): SoulBoundToken {
  let sbt = SoulBoundToken.load(soulBoundTokenId.toString());
  if (!sbt) {
    sbt = new SoulBoundToken(soulBoundTokenId.toString());
    sbt.wallet = Address.zero();
    sbt.save();
  }
  return sbt as SoulBoundToken;
}
