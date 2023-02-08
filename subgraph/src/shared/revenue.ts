import { BigInt } from "@graphprotocol/graph-ts";

import { Account, Creator, DNFT } from "../../generated/schema";

export function recordSale(
  nft: DNFT,
  seller: Account,
  creatorRevenue: BigInt | null,
  previousCreatorRevenue: BigInt | null,
  ownerRevenue: BigInt | null,
  foundationRevenue: BigInt | null,
): void {
  if (!creatorRevenue || !previousCreatorRevenue || !ownerRevenue || !foundationRevenue) {
    // This should never occur
    return;
  }
  let amount = creatorRevenue.plus(previousCreatorRevenue).plus(ownerRevenue).plus(foundationRevenue);

  // Creator revenue & sales
  let creator: Creator | null;
  if (nft.creator) {
    creator = Creator.load(nft.creator as string);
  } else {
    creator = null;
  }
  if (creator) {
    creator.netRevenue = creator.netRevenue.plus(creatorRevenue);
    creator.netSales = creator.netSales.plus(amount);
    creator.save();
  }

  // Account revenue
  seller.netRevenue = seller.netRevenue.plus(ownerRevenue);
  seller.save();

  // NFT revenue & sales
  nft.netSales = nft.netSales.plus(amount);
  nft.netRevenue = nft.netRevenue.plus(creatorRevenue);
  nft.isFirstSale = false;
  nft.lastSalePrice = amount;
  nft.save();
}
