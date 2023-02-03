// 

import { Address, BigInt, Bytes, ethereum, store } from "@graphprotocol/graph-ts";

import { Publication } from "../../generated/schema";
import { ZERO_ADDRESS_STRING, ZERO_BIG_INT, ZERO_BYTES_32_STRING } from "./constants";
import { loadOrCreateAccount } from "./accounts";
import { loadHub } from "./hub";
import { loadProject } from "./project";

export function loadPublication(
   publishId: BigInt
): Publication {
  let publication = Publication.load(publishId.toString());
  return publication as Publication;
}

