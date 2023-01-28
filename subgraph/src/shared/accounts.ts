import { Address } from "@graphprotocol/graph-ts";

import { Account, Profile } from "../../generated/schema";
import { ZERO_BIG_DECIMAL } from "./constants";
import { loadOrCreateProfile } from "./profile";

export function loadOrCreateAccount(address: Address): Account {
  let addressHex = address.toHex();
  let profile = loadOrCreateProfile(address);
  
  let account = Account.load(addressHex);
  if (!account) {
    account = new Account(addressHex);
    account.profile = profile.id
    account.netRevenueInSBTValue = ZERO_BIG_DECIMAL;
    account.netRevenuePendingInSBTValue = ZERO_BIG_DECIMAL;
    account.save();
  }
  return account as Account;
}
