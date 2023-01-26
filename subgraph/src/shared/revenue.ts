import { BigDecimal } from "@graphprotocol/graph-ts";

import { Account, Creator, DNFT } from "../../generated/schema";

export function recordSale(
  nft: DNFT,
  seller: Account,
  creatorRevenueInSBTValue: BigDecimal | null,
  previousCreatorRevenueInSBTValue: BigDecimal | null,
  ownerRevenueInSBTValue: BigDecimal | null,
  foundationRevenueInSBTValue: BigDecimal | null,
): void {
  if (!creatorRevenueInSBTValue || !previousCreatorRevenueInSBTValue || !ownerRevenueInSBTValue || !foundationRevenueInSBTValue) {
    // This should never occur
    return;
  }
  let amountInSBTValue = creatorRevenueInSBTValue.plus(previousCreatorRevenueInSBTValue).plus(ownerRevenueInSBTValue).plus(foundationRevenueInSBTValue);

  // Creator revenue & sales
  let creator: Creator | null;
  if (nft.creator) {
    creator = Creator.load(nft.creator as string);
  } else {
    creator = null;
  }
  if (creator) {
    creator.netRevenueInSBTValue = creator.netRevenueInSBTValue.plus(creatorRevenueInSBTValue);
    creator.netSalesInSBTValue = creator.netSalesInSBTValue.plus(amountInSBTValue);
    creator.save();
  }

  // Account revenue
  seller.netRevenueInSBTValue = seller.netRevenueInSBTValue.plus(ownerRevenueInSBTValue);
  seller.save();

  // NFT revenue & sales
  nft.netSalesInSBTValue = nft.netSalesInSBTValue.plus(amountInSBTValue);
  nft.netRevenueInSBTValue = nft.netRevenueInSBTValue.plus(creatorRevenueInSBTValue);
  nft.isFirstSale = false;
  nft.lastSalePriceInSBTValue = amountInSBTValue;
  nft.save();
}
