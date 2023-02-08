import { log, Address, BigInt, ethereum, store } from "@graphprotocol/graph-ts";

import {
  DerivativeNFT
} from "../generated/Manager/DerivativeNFT"

import {
  DNFT,
  DerivativeNFTContract,
} from "../generated/schema";


import { loadOrCreateAccount } from "./shared/accounts";
import { ZERO_ADDRESS_STRING } from "./shared/constants";
import { loadOrCreateCreator } from "./shared/creators";
import { getLogId } from "./shared/ids";
import { loadOrCreatePublish } from "./shared/publish";

export function loadOrCreateDNFTContract(address: Address): DerivativeNFTContract {
  let derivativeNFT = DerivativeNFTContract.load(address.toHex());
  if (!derivativeNFT) {

    derivativeNFT = _createNFTContract(address);
    
  }
  return derivativeNFT as DerivativeNFTContract;
}

function _createNFTContract(address: Address): DerivativeNFTContract {
  let derivativeNFT = new DerivativeNFTContract(address.toHex());
  let contract = DerivativeNFT.bind(address);
  let nameResults = contract.try_name();
  if (!nameResults.reverted) {
    derivativeNFT.name = nameResults.value;
  }
  let symbolResults = contract.try_symbol();
  if (!symbolResults.reverted) {
    derivativeNFT.symbol = symbolResults.value;
  }
  derivativeNFT.contract = address
  //TODO
  derivativeNFT.baseURI = "ipfs://";
  derivativeNFT.save();
  return derivativeNFT;
}

function getNFTId(address: Address, id: BigInt): string {
  return address.toHex() + "-" + id.toString();
}
/*
export function loadOrCreateDNFT(address: Address, id: BigInt, event: ethereum.Event): DNFT {
  let nftId = getNFTId(address, id);
  let dnft = DNFT.load(nftId);
  if (!dnft) {
    dnft = new DNFT(nftId);
    dnft.derivativeNFT = loadOrCreateDNFTContract(address).id;
    dnft.tokenId = id;
    dnft.dateMinted = event.block.timestamp;

    let contract = DerivativeNFT.bind(address);

    if (id.isZero()) {
      log.info("id.isZero() --- in loadOrCreateDNFT", [])
      dnft.owner = loadOrCreateAccount(Address.zero()).id;
    } else {
      const resultPublish = contract.try_getPublishIdByTokenId(id)
      if (resultPublish.reverted) {
          log.info("resultPublish.reverted --- in loadOrCreateDNFT, try_getPublishIdByTokenId tokenId:{}", [
            dnft.tokenId.toString(),
          ])
  
      } else {
          log.info("!resultPublish.reverted --- in loadOrCreateDNFT, tokenId:{}, try_getPublishIdByTokenId result.value: {}", [
            dnft.tokenId.toString(),
            resultPublish.value.toString()
          ])
          if(!resultPublish.value.isZero()) {

            dnft.publish = loadOrCreatePublish(resultPublish.value).id
            dnft.project = loadOrCreatePublish(resultPublish.value).project
          }
      }
  
      let ownerResult = contract.try_ownerOf(id);
      if (!ownerResult.reverted) {
          log.info("!ownerResult.reverted --- in loadOrCreateDNFT, tokenId:{}", [
          dnft.tokenId.toString(),
        ])
        dnft.owner = loadOrCreateAccount(ownerResult.value).id;
      } else {
          log.info("ownerResult.reverted --- in loadOrCreateDNFT, tokenId:{}", [
          dnft.tokenId.toString(),
        ])
        dnft.owner = loadOrCreateAccount(Address.zero()).id;
      }

    }

    dnft.ownedOrListedBy = dnft.owner;
    dnft.netSales = ZERO_BIG_INT;
    dnft.netSalesPending = ZERO_BIG_INT;
    dnft.netRevenue = ZERO_BIG_INT;
    dnft.netRevenuePending = ZERO_BIG_INT;
    dnft.isFirstSale = true;
    let pathResult = contract.try_tokenURI(id);
    if (!pathResult.reverted) {
      dnft.tokenIPFSPath = pathResult.value;
    }
    let creatorResult = contract.try_tokenCreator(id);
    if (!creatorResult.reverted) {
      dnft.creator = loadOrCreateCreator(creatorResult.value).id;
    }
    dnft.save();
  }

  return dnft as DNFT;
}

*/

export function loadOrCreateDNFT(address: Address, id: BigInt, event: ethereum.Event): DNFT | null {
  let nftId = getNFTId(address, id);
  let dnft = DNFT.load(nftId);
  if (dnft) {
    return dnft as DNFT;
  } else {
    return null;
  }
}