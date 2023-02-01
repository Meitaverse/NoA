import { DNFT, DnftMarketBuyNow } from "../../generated/schema";

export function loadLatestBuyNow(dnft: DNFT): DnftMarketBuyNow | null {
  if (!dnft.mostRecentBuyNow) {
    return null;
  }
  let buyNow = DnftMarketBuyNow.load(dnft.mostRecentBuyNow as string);
  if (!buyNow || buyNow.status != "Open") {
    return null;
  }
  return buyNow;
}
