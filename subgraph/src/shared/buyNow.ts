import { DNFT, NftMarketBuyNow } from "../../generated/schema";

export function loadLatestBuyNow(nft: DNFT): NftMarketBuyNow | null {
  if (!nft.mostRecentBuyNow) {
    return null;
  }
  let buyNow = NftMarketBuyNow.load(nft.mostRecentBuyNow as string);
  if (!buyNow || buyNow.status != "Open") {
    return null;
  }
  return buyNow;
}
