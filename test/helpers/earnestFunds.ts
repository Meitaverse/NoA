import { ContractReceipt, ContractTransaction } from "ethers";
import { ONE_DAY, ONE_HOUR } from "./constants";
import { getBlockTime } from "./time";

export async function getEarnestFundsExpectedExpiration(receipt: ContractReceipt): Promise<number> {
  // const receipt = await tx.wait();
  const timestamp = await getBlockTime(receipt.blockNumber);
  return getEarnestFundsExpirationFromSeconds(timestamp);
}

export function getEarnestFundsExpirationFromSeconds(timestampInSeconds: number): number {
  return Math.ceil(timestampInSeconds / ONE_HOUR) * ONE_HOUR + ONE_DAY;
}
