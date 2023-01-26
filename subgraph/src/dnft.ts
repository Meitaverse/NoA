import { Address, BigInt, ethereum, store } from "@graphprotocol/graph-ts";

import {
  DerivativeNFT
} from "../generated/MarketPlace/DerivativeNFT"

import {
  DNFT,
  DerivativeNFTContract,
} from "../generated/schema";


import { loadOrCreateAccount } from "./shared/accounts";
import { ZERO_ADDRESS_STRING, ZERO_BIG_DECIMAL } from "./shared/constants";
import { loadOrCreateCreator } from "./shared/creators";
import { recordNftEvent, removePreviousTransferEvent } from "./shared/events";
import { getLogId } from "./shared/ids";


export function loadOrCreateNFTContract(address: Address): DerivativeNFTContract {
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
  //TODO
  derivativeNFT.baseURI = "ipfs://";
  derivativeNFT.save();
  return derivativeNFT;
}


function getNFTId(address: Address, id: BigInt): string {
  return address.toHex() + "-" + id.toString();
}

export function loadOrCreateNFT(address: Address, id: BigInt, event: ethereum.Event): DNFT {
  let nftId = getNFTId(address, id);
  let dnft = DNFT.load(nftId);
  if (!dnft) {
    dnft = new DNFT(nftId);
    dnft.derivativeNFT = loadOrCreateNFTContract(address).id;
    dnft.tokenId = id;
    dnft.dateMinted = event.block.timestamp;
    let contract = DerivativeNFT.bind(address);
    let ownerResult = contract.try_ownerOf(id);
    if (!ownerResult.reverted) {
      dnft.owner = loadOrCreateAccount(ownerResult.value).id;
    } else {
      dnft.owner = loadOrCreateAccount(Address.zero()).id;
    }
    dnft.ownedOrListedBy = dnft.owner;
    dnft.netSalesInSBTValue = ZERO_BIG_DECIMAL;
    dnft.netSalesPendingInSBTValue = ZERO_BIG_DECIMAL;
    dnft.netRevenueInSBTValue = ZERO_BIG_DECIMAL;
    dnft.netRevenuePendingInSBTValue = ZERO_BIG_DECIMAL;
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

