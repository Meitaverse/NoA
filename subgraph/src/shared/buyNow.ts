import { DNFT, NftMarketBuyNow } from "../../generated/schema";

export function loadLatestBuyNow(dnft: DNFT): NftMarketBuyNow | null {
  if (!dnft.mostRecentBuyNow) {
    return null;
  }
  let buyNow = NftMarketBuyNow.load(dnft.mostRecentBuyNow as string);
  if (!buyNow || buyNow.status != "Open") {
    return null;
  }
  return buyNow;
}
