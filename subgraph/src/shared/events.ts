import { BigDecimal, BigInt, Bytes, ethereum, store } from "@graphprotocol/graph-ts";

import {
  Account,
  DNFT,
  DnftHistory,
  DnftMarketAuction,
  DnftMarketBuyNow,
  DnftMarketOffer,
} from "../../generated/schema";
import { loadOrCreateAccount } from "./accounts";
import { ONE_BIG_INT, ZERO_BIG_INT } from "./constants";
import { getEventId, getPreviousEventId } from "./ids";

export function recordDnftEvent(
  event: ethereum.Event,
  dnft: DNFT,
  eventType: string,
  actorAccount: Account,
  auction: DnftMarketAuction | null = null,
  marketplace: string | null = null,
  currency: Bytes | null = null,
  amount: BigInt | null = null,
  nftRecipient: Account | null = null,
  dateOverride: BigInt | null = null,
  amountInTokens: BigInt | null = null,
  tokenAddress: Bytes | null = null,
  offer: DnftMarketOffer | null = null,
  buyNow: DnftMarketBuyNow | null = null,
): void {
  let historicalEvent = new DnftHistory(getEventId(event, eventType));
  historicalEvent.dnft = dnft.id;
  historicalEvent.event = eventType;
  if (auction) {
    historicalEvent.auction = auction.id;
  }
  if (dateOverride) {
    historicalEvent.date = dateOverride as BigInt;
  } else {
    historicalEvent.date = event.block.timestamp;
  }
  historicalEvent.contractAddress = event.address;
  historicalEvent.transactionHash = event.transaction.hash;
  historicalEvent.actorAccount = actorAccount.id;
  historicalEvent.txOrigin = loadOrCreateAccount(event.transaction.from).id;
  if (nftRecipient) {
    historicalEvent.nftRecipient = nftRecipient.id;
  }
  historicalEvent.marketplace = marketplace;
  historicalEvent.amount = amount;
  historicalEvent.amountInTokens = amountInTokens;
  historicalEvent.tokenAddress = tokenAddress;

  if (offer) {
    historicalEvent.offer = offer.id;
  }
  if (buyNow) {
    historicalEvent.buyNow = buyNow.id;
  }
  historicalEvent.save();
}

export function removePreviousTransferEvent(event: ethereum.Event): void {
  // There may be multiple logs that occurred since the last transfer event
  for (let i = event.logIndex.minus(ONE_BIG_INT); i.ge(ZERO_BIG_INT); i = i.minus(ONE_BIG_INT)) {
    let previousEvent = DnftHistory.load(getPreviousEventId(event, "Transferred", i));
    if (previousEvent) {
      store.remove("DnftHistory", previousEvent.id);
      return;
    }
  }
}
