import { Address } from "@graphprotocol/graph-ts";

import { Creator } from "../../generated/schema";
import { loadOrCreateAccount } from "./accounts";
import { ZERO_BIG_INT } from "./constants";

export function loadOrCreateCreator(address: Address): Creator {
  let account = loadOrCreateAccount(address);
  let creator = Creator.load(account.id);
  if (!creator) {
    creator = new Creator(account.id);
    creator.account = account.id;
    creator.netSales = ZERO_BIG_INT;
    creator.netSalesPending = ZERO_BIG_INT;
    creator.netRevenue = ZERO_BIG_INT;
    creator.netRevenuePending = ZERO_BIG_INT;
    creator.save();
  }
  return creator as Creator;
}
