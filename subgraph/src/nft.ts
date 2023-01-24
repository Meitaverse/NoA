import { Address, BigInt, ethereum, store } from "@graphprotocol/graph-ts";

import {
  DerivativeNFTV1
} from "../generated/MarketPlace/DerivativeNFTV1"

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
  let contract = DerivativeNFTV1.bind(address);
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
  let nft = DNFT.load(nftId);
  if (!nft) {
    nft = new DNFT(nftId);
    nft.derivativeNFT = loadOrCreateNFTContract(address).id;
    nft.tokenId = id;
    nft.dateMinted = event.block.timestamp;
    let contract = DerivativeNFTV1.bind(address);
    let ownerResult = contract.try_ownerOf(id);
    if (!ownerResult.reverted) {
      nft.owner = loadOrCreateAccount(ownerResult.value).id;
    } else {
      nft.owner = loadOrCreateAccount(Address.zero()).id;
    }
    nft.ownedOrListedBy = nft.owner;
    nft.netSalesInETH = ZERO_BIG_DECIMAL;
    nft.netSalesPendingInETH = ZERO_BIG_DECIMAL;
    nft.netRevenueInETH = ZERO_BIG_DECIMAL;
    nft.netRevenuePendingInETH = ZERO_BIG_DECIMAL;
    nft.isFirstSale = true;
    let pathResult = contract.try_tokenURI(id);
    if (!pathResult.reverted) {
      nft.tokenIPFSPath = pathResult.value;
    }
    let creatorResult = contract.try_tokenCreator(id);
    if (!creatorResult.reverted) {
      nft.creator = loadOrCreateCreator(creatorResult.value).id;
    }
    nft.save();
  }

  return nft as DNFT;
}

