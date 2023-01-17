import '@nomiclabs/hardhat-ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, ContractTransaction , logger} from 'ethers';
// import { BigNumberish, Bytes, logger, utils, BigNumber, Contract, Signer } from 'ethers';
import fs from 'fs';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TransactionReceipt, TransactionResponse } from '@ethersproject/providers';
import { BytesLike, hexlify, keccak256, RLP, toUtf8Bytes } from 'ethers/lib/utils';

// import {Events} from '../../typechain';

// let eventsLib: Events;

export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

export enum ProtocolState {
  Unpaused,
  PublishingPaused,
  Paused,
}

export enum Error {
  None,
  RevertWithMessage,
  RevertWithoutMessage,
  Panic
}

export function getAddrs(): any {
  const json = fs.readFileSync('addresses.json', 'utf8');
  const addrs = JSON.parse(json);
  return addrs;
}

// export async function waitForTx(tx: Promise<ContractTransaction>) {
//  return await (await tx).wait();
// }


export async function waitForTx(
  tx: Promise<TransactionResponse> | TransactionResponse,
  skipCheck = false
): Promise<TransactionReceipt> {
  // if (!skipCheck) await expect(tx).to.not.be.reverted;
  return await (await tx).wait();
}

export function findEvent(
  receipt: TransactionReceipt,
  name: string,
  eventContract: Contract,
  emitterAddress?: string
) {
  
  const events = receipt.logs;

  if (events != undefined) {
    // match name from list of events in eventContract, when found, compute the sigHash
    let sigHash: string | undefined;
    for (const contractEvent of Object.keys(eventContract.interface.events)) {
      if (contractEvent.startsWith(name) && contractEvent.charAt(name.length) == '(') {
        sigHash = keccak256(toUtf8Bytes(contractEvent));
        break;
      }
    }
    // Throw if the sigHash was not found
    if (!sigHash) {
      logger.throwError(
        `Event "${name}" not found in provided contract (default: Events libary). \nAre you sure you're using the right contract?`
      );
    }

    for (const emittedEvent of events) {
      // If we find one with the correct sighash, check if it is the one we're looking for
      if (emittedEvent.topics[0] == sigHash) {
        // If an emitter address is passed, validate that this is indeed the correct emitter, if not, continue
        if (emitterAddress) {
          if (emittedEvent.address != emitterAddress) continue;
        }
        const event = eventContract.interface.parseLog(emittedEvent);
        return event;
      }
    }
    // Throw if the event args were not expected or the event was not found in the logs
    logger.throwError(
      `Event "${name}" not found emitted by "${emitterAddress}" in given transaction log`
    );
  } else {
    logger.throwError('No events were emitted');
  }
}

export async function deployContract(tx: any): Promise<Contract> {
  const result = await tx;
  await result.deployTransaction.wait();
  return result;
}

export async function deployWithVerify(
  tx: any,
  args: any,
  contractPath: string
): Promise<Contract> {
  const deployedContract = await deployContract(tx);
  let count = 0;
  let maxTries = 8;
  const runtimeHRE = require('hardhat');
  while (true) {
    await delay(10000);
    try {
      console.log('Verifying contract at', deployedContract.address);
      await runtimeHRE.run('verify:verify', {
        address: deployedContract.address,
        constructorArguments: args,
        contract: contractPath,
      });
      break;
    } catch (error) {
      if (String(error).includes('Already Verified')) {
        console.log(
          `Already verified contract at ${contractPath} at address ${deployedContract.address}`
        );
        break;
      }
      if (++count == maxTries) {
        console.log(
          `Failed to verify contract at ${contractPath} at address ${deployedContract.address}, error: ${error}`
        );
        break;
      }
      console.log(`Retrying... Retry #${count}, last error: ${error}`);
    }
  }

  return deployedContract;
}

export async function initEnv(hre: HardhatRuntimeEnvironment): Promise<SignerWithAddress[]> {
  const ethers = hre.ethers; // This allows us to access the hre (Hardhat runtime environment)'s injected ethers instance easily

  const accounts = await ethers.getSigners(); // This returns an array of the default signers connected to the hre's ethers instance
  const governance = accounts[1];
  const treasury = accounts[2]; //金库地址
  const user = accounts[3];

  return [governance, treasury, user];
}

async function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
