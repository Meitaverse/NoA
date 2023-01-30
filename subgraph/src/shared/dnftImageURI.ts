// 

import { log, Address, BigInt } from "@graphprotocol/graph-ts";

import { DnftImageURI } from "../../generated/schema";
import { DEFAULT_DNFT_IMAGEURI, ZERO_BIG_INT } from "./constants";
import { loadOrCreateDNFTContract } from "../dnft";

export function loadOrCreateDnftImageURI(address: Address, tokenId: BigInt): DnftImageURI {
  let addressHex = address.toHex();
  let dnftImageURI = DnftImageURI.load(addressHex + "-" + tokenId.toString());
  if (!dnftImageURI) {
    dnftImageURI = new DnftImageURI(addressHex);
    dnftImageURI.derivativeNFT = loadOrCreateDNFTContract(address).id;
    dnftImageURI.tokenId = ZERO_BIG_INT;
    dnftImageURI.imageURI = DEFAULT_DNFT_IMAGEURI;
    dnftImageURI.timestamp = ZERO_BIG_INT;
    dnftImageURI.save();
    
  }
  return dnftImageURI as DnftImageURI;
}
