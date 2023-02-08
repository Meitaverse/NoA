import { Address, BigInt, ethereum } from "@graphprotocol/graph-ts";

import { Account, CurrencyEarnestFunds, CurrencyEarnestFundsEscrow } from "../../generated/schema";
import { ZERO_BIG_INT } from "./constants";

interface EscrowEventParams {
  account: Address;
  amount: BigInt;
  expiration: BigInt;
}

interface EscrowEvent {
  params: EscrowEventParams;
  block: ethereum.Block;
  transaction: ethereum.Transaction;
}

export function getEscrowId<T extends EscrowEvent>(event: T): string {
  return event.params.account.toHex() + "-" + event.params.expiration.toString();
}

export function loadOrCreateCurrencyEarnestFunds(currency: Address, account: Account, block: ethereum.Block): CurrencyEarnestFunds {
  let _id = currency.toHex() + "-" + account.id;

  let currencyEarnestFunds = CurrencyEarnestFunds.load(_id);
  if (!currencyEarnestFunds) {
    currencyEarnestFunds = new CurrencyEarnestFunds(account.id);
    currencyEarnestFunds.user = account.id;
    currencyEarnestFunds.currency = currency;
    currencyEarnestFunds.balance = ZERO_BIG_INT;
    currencyEarnestFunds.dateLastUpdated = block.timestamp;
  }
  return currencyEarnestFunds;
}

export function loadOrCreateFsbtEscrow<T extends EscrowEvent>(event: T, currency: Address, account: Account): CurrencyEarnestFundsEscrow {
  const escrowId = getEscrowId(event);
  let fsbtEscrow = CurrencyEarnestFundsEscrow.load(escrowId);
  if (!fsbtEscrow) {
    fsbtEscrow = new CurrencyEarnestFundsEscrow(escrowId);
    fsbtEscrow.transactionHashCreated = event.transaction.hash;
    fsbtEscrow.amount = ZERO_BIG_INT;

    // Placeholder for expiry (now), this should be immediately replaced by the actual expiry
    fsbtEscrow.dateExpiry = event.params.expiration;
  }

  // Ensure that the escrow is associated with the account's earnest funds balance
  let fsbtAccount = loadOrCreateCurrencyEarnestFunds(currency, account, event.block);
  fsbtAccount.save();
  fsbtEscrow.currencyEarnestFunds = fsbtAccount.id;

  return fsbtEscrow;
}
