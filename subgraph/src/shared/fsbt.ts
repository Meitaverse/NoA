import { Address, BigInt, ethereum } from "@graphprotocol/graph-ts";

import { Account, Fsbt, FsbtEscrow } from "../../generated/schema";
import { ZERO_BIG_DECIMAL } from "./constants";

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

export function loadOrCreateFsbt(account: Account, block: ethereum.Block): Fsbt {
  let fsbt = Fsbt.load(account.id);
  if (!fsbt) {
    fsbt = new Fsbt(account.id);
    fsbt.user = account.id;
    fsbt.balanceInSBTValue = ZERO_BIG_DECIMAL;
    fsbt.dateLastUpdated = block.timestamp;
  }
  return fsbt;
}

export function loadOrCreateFsbtEscrow<T extends EscrowEvent>(event: T, account: Account): FsbtEscrow {
  const escrowId = getEscrowId(event);
  let fsbtEscrow = FsbtEscrow.load(escrowId);
  if (!fsbtEscrow) {
    fsbtEscrow = new FsbtEscrow(escrowId);
    fsbtEscrow.transactionHashCreated = event.transaction.hash;
    fsbtEscrow.amountInSBTValue = ZERO_BIG_DECIMAL;

    // Placeholder for expiry (now), this should be immediately replaced by the actual expiry
    fsbtEscrow.dateExpiry = event.params.expiration;
  }

  // Ensure that the escrow is associated with the account's earnest money balance
  let fsbtAccount = loadOrCreateFsbt(account, event.block);
  fsbtAccount.save();
  fsbtEscrow.fsbt = fsbtAccount.id;

  return fsbtEscrow;
}
