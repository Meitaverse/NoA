import '@nomiclabs/hardhat-ethers';
import { BigNumberish, Bytes, logger, utils, BigNumber, Contract, Signer } from 'ethers';
import {
  eventsLib,
  helper,
  manager,
  metadataDescriptor,
  NDPT_NAME,
  testWallet,
  user,
  userTwo,
} from '../__setup.spec';
import { expect } from 'chai';
import { HARDHAT_CHAINID, MAX_UINT256 } from './constants';
import { BytesLike, hexlify, keccak256, RLP, toUtf8Bytes } from 'ethers/lib/utils';
import { Manager__factory } from '../../typechain';
import { TransactionReceipt, TransactionResponse } from '@ethersproject/providers';
import hre, { ethers } from 'hardhat';
import { readFileSync } from 'fs';
import { join } from 'path';

import { DataTypes } from '../../typechain/contracts/Manager';

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

export function matchEvent(
  receipt: TransactionReceipt,
  name: string,
  expectedArgs?: any[],
  eventContract: Contract = eventsLib,
  emitterAddress?: string
) {
  const events = receipt.logs;

  if (events != undefined) {
    // match name from list of events in eventContract, when found, compute the sigHash
    let sigHash: string | undefined;
    for (let contractEvent of Object.keys(eventContract.interface.events)) {
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

    // Find the given event in the emitted logs
    let invalidParamsButExists = false;
    for (let emittedEvent of events) {
      // If we find one with the correct sighash, check if it is the one we're looking for
      if (emittedEvent.topics[0] == sigHash) {
        // If an emitter address is passed, validate that this is indeed the correct emitter, if not, continue
        if (emitterAddress) {
          if (emittedEvent.address != emitterAddress) continue;
        }
        const event = eventContract.interface.parseLog(emittedEvent);
        // If there are expected arguments, validate them, otherwise, return here
        if (expectedArgs) {
          if (expectedArgs.length != event.args.length) {
            logger.throwError(
              `Event "${name}" emitted with correct signature, but expected args are of invalid length`
            );
          }
          invalidParamsButExists = false;
          // Iterate through arguments and check them, if there is a mismatch, continue with the loop
          for (let i = 0; i < expectedArgs.length; i++) {
            // Parse empty arrays as empty bytes
            if (expectedArgs[i].constructor == Array && expectedArgs[i].length == 0) {
              expectedArgs[i] = '0x';
            }

            // Break out of the expected args loop if there is a mismatch, this will continue the emitted event loop
            if (BigNumber.isBigNumber(event.args[i])) {
              if (!event.args[i].eq(BigNumber.from(expectedArgs[i]))) {
                invalidParamsButExists = true;
                break;
              }
            } else if (event.args[i].constructor == Array) {
              let params = event.args[i];
              let expected = expectedArgs[i];
              if (expected != '0x' && params.length != expected.length) {
                invalidParamsButExists = true;
                break;
              }
              for (let j = 0; j < params.length; j++) {
                if (BigNumber.isBigNumber(params[j])) {
                  if (!params[j].eq(BigNumber.from(expected[j]))) {
                    invalidParamsButExists = true;
                    break;
                  }
                } else if (params[j] != expected[j]) {
                  invalidParamsButExists = true;
                  break;
                }
              }
              if (invalidParamsButExists) break;
            } else if (event.args[i] != expectedArgs[i]) {
              invalidParamsButExists = true;
              break;
            }
          }
          // Return if the for loop did not cause a break, so a match has been found, otherwise proceed with the event loop
          if (!invalidParamsButExists) {
            return;
          }
        } else {
          return;
        }
      }
    }
    // Throw if the event args were not expected or the event was not found in the logs
    if (invalidParamsButExists) {
      logger.throwError(`Event "${name}" found in logs but with unexpected args`);
    } else {
      logger.throwError(
        `Event "${name}" not found emitted by "${emitterAddress}" in given transaction log`
      );
    }
  } else {
    logger.throwError('No events were emitted');
  }
}

export function findEvent(
  receipt: TransactionReceipt,
  name: string,
  eventContract: Contract = eventsLib,
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

export function computeContractAddress(deployerAddress: string, nonce: number): string {
  const hexNonce = hexlify(nonce);
  return '0x' + keccak256(RLP.encode([deployerAddress, hexNonce])).substr(26);
}

export function getChainId(): number {
  return hre.network.config.chainId || HARDHAT_CHAINID;
}

// export function getAbbreviation(handle: string) {
//   let slice = handle.substr(0, 4);
//   if (slice.charAt(3) == ' ') {
//     slice = slice.substr(0, 3);
//   }
//   return slice;
// }

export async function waitForTx(
  tx: Promise<TransactionResponse> | TransactionResponse,
  skipCheck = false
): Promise<TransactionReceipt> {
  if (!skipCheck) await expect(tx).to.not.be.reverted;
  return await (await tx).wait();
}

export async function getBlockNumber(): Promise<number> {
  return (await helper.getBlockNumber()).toNumber();
}

export async function resetFork(): Promise<void> {
  await hre.network.provider.request({
    method: 'hardhat_reset',
    params: [
      {
        forking: {
          jsonRpcUrl: process.env.MAINNET_RPC_URL,
          blockNumber: 12012081,
        },
      },
    ],
  });
  console.log('\t> Fork reset');

  await hre.network.provider.request({
    method: 'evm_setNextBlockTimestamp',
    params: [1614290545], // Original block timestamp + 1
  });

  console.log('\t> Timestamp reset to 1614290545');
}

export async function getTimestamp(): Promise<any> {
  const blockNumber = await hre.ethers.provider.send('eth_blockNumber', []);
  const block = await hre.ethers.provider.send('eth_getBlockByNumber', [blockNumber, false]);
  return block.timestamp;
}

export async function setNextBlockTimestamp(timestamp: number): Promise<void> {
  await hre.ethers.provider.send('evm_setNextBlockTimestamp', [timestamp]);
}

export async function mine(blocks: number): Promise<void> {
  for (let i = 0; i < blocks; i++) {
    await hre.ethers.provider.send('evm_mine', []);
  }
}

let snapshotId: string = '0x1';
export async function takeSnapshot() {
  snapshotId = await hre.ethers.provider.send('evm_snapshot', []);
}

export async function revertToSnapshot() {
  await hre.ethers.provider.send('evm_revert', [snapshotId]);
}
/*
export async function cancelWithPermitForAll(nft: string = manager.address) {
  const nftContract = Manager__factory.connect(nft, testWallet);
  const name = await nftContract.name();
  const nonce = (await nftContract.sigNonces(testWallet.address)).toNumber();
  const { v, r, s } = await getPermitForAllParts(
    nft,
    name,
    testWallet.address,
    testWallet.address,
    false,
    nonce,
    MAX_UINT256
  );
  await nftContract.permitForAll(testWallet.address, testWallet.address, false, {
    v,
    r,
    s,
    deadline: MAX_UINT256,
  });
}

export async function getPermitParts(
  nft: string,
  name: string,
  spender: string,
  tokenId: BigNumberish,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildPermitParams(nft, name, spender, tokenId, nonce, deadline);
  return await getSig(msgParams);
}

export async function getPermitForAllParts(
  nft: string,
  name: string,
  owner: string,
  operator: string,
  approved: boolean,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildPermitForAllParams(nft, name, owner, operator, approved, nonce, deadline);
  return await getSig(msgParams);
}

export async function getBurnWithSigparts(
  nft: string,
  name: string,
  tokenId: BigNumberish,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildBurnWithSigParams(nft, name, tokenId, nonce, deadline);
  return await getSig(msgParams);
}

export async function getDelegateBySigParts(
  nft: string,
  name: string,
  delegator: string,
  delegatee: string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildDelegateBySigParams(nft, name, delegator, delegatee, nonce, deadline);
  return await getSig(msgParams);
}

const buildDelegateBySigParams = (
  nft: string,
  name: string,
  delegator: string,
  delegatee: string,
  nonce: number,
  deadline: string
) => ({
  types: {
    DelegateBySig: [
      { name: 'delegator', type: 'address' },
      { name: 'delegatee', type: 'address' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: {
    name: name,
    version: '1',
    chainId: getChainId(),
    verifyingContract: nft,
  },
  value: {
    delegator: delegator,
    delegatee: delegatee,
    nonce: nonce,
    deadline: deadline,
  },
});

export async function getSetFollowModuleWithSigParts(
  profileId: BigNumberish,
  followModule: string,
  followModuleInitData: Bytes | string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildSetFollowModuleWithSigParams(
    profileId,
    followModule,
    followModuleInitData,
    nonce,
    deadline
  );
  return await getSig(msgParams);
}

export async function getSetDispatcherWithSigParts(
  profileId: BigNumberish,
  dispatcher: string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildSetDispatcherWithSigParams(profileId, dispatcher, nonce, deadline);
  return await getSig(msgParams);
}

export async function getSetProfileImageURIWithSigParts(
  profileId: BigNumberish,
  imageURI: string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildSetProfileImageURIWithSigParams(profileId, imageURI, nonce, deadline);
  return await getSig(msgParams);
}

export async function getSetDefaultProfileWithSigParts(
  wallet: string,
  profileId: BigNumberish,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildSetDefaultProfileWithSigParams(profileId, wallet, nonce, deadline);
  return await getSig(msgParams);
}

export async function getSetFollowNFTURIWithSigParts(
  profileId: BigNumberish,
  followNFTURI: string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildSetFollowNFTURIWithSigParams(profileId, followNFTURI, nonce, deadline);
  return await getSig(msgParams);
}

export async function getPostWithSigParts(
  profileId: BigNumberish,
  contentURI: string,
  collectModule: string,
  collectModuleInitData: Bytes | string,
  referenceModule: string,
  referenceModuleInitData: Bytes | string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildPostWithSigParams(
    profileId,
    contentURI,
    collectModule,
    collectModuleInitData,
    referenceModule,
    referenceModuleInitData,
    nonce,
    deadline
  );
  return await getSig(msgParams);
}

export async function getCommentWithSigParts(
  profileId: BigNumberish,
  contentURI: string,
  profileIdPointed: BigNumberish,
  pubIdPointed: string,
  referenceModuleData: Bytes | string,
  collectModule: string,
  collectModuleInitData: Bytes | string,
  referenceModule: string,
  referenceModuleInitData: Bytes | string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildCommentWithSigParams(
    profileId,
    contentURI,
    profileIdPointed,
    pubIdPointed,
    referenceModuleData,
    collectModule,
    collectModuleInitData,
    referenceModule,
    referenceModuleInitData,
    nonce,
    deadline
  );
  return await getSig(msgParams);
}

export async function getMirrorWithSigParts(
  profileId: BigNumberish,
  profileIdPointed: BigNumberish,
  pubIdPointed: string,
  referenceModuleData: Bytes | string,
  referenceModule: string,
  referenceModuleInitData: Bytes | string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildMirrorWithSigParams(
    profileId,
    profileIdPointed,
    pubIdPointed,
    referenceModuleData,
    referenceModule,
    referenceModuleInitData,
    nonce,
    deadline
  );
  return await getSig(msgParams);
}

export async function getFollowWithSigParts(
  profileIds: string[] | number[],
  datas: Bytes[] | string[],
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildFollowWithSigParams(profileIds, datas, nonce, deadline);
  return await getSig(msgParams);
}

export async function getToggleFollowWithSigParts(
  profileIds: string[] | number[],
  enables: boolean[],
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildToggleFollowWithSigParams(profileIds, enables, nonce, deadline);
  return await getSig(msgParams);
}

export async function getSetProfileMetadataURIWithSigParts(
  profileId: string | number,
  metadata: string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildSetProfileMetadataURIWithSigParams(profileId, metadata, nonce, deadline);
  return await getSig(msgParams);
}

export async function getCollectWithSigParts(
  profileId: BigNumberish,
  pubId: string,
  data: Bytes | string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildCollectWithSigParams(profileId, pubId, data, nonce, deadline);
  return await getSig(msgParams);
}

export function expectEqualArrays(actual: BigNumberish[], expected: BigNumberish[]) {
  if (actual.length != expected.length) {
    logger.throwError(
      `${actual} length ${actual.length} does not match ${expected} length ${expect.length}`
    );
  }

  let areEquals = true;
  for (let i = 0; areEquals && i < actual.length; i++) {
    areEquals = BigNumber.from(actual[i]).eq(BigNumber.from(expected[i]));
  }

  if (!areEquals) {
    logger.throwError(`${actual} does not match ${expected}`);
  }
}
*/
export interface CreateProfileReturningTokenIdStruct {
  sender?: Signer;
  vars: DataTypes.CreateProfileDataStruct;
}

export async function createProfileReturningTokenId({
  sender = user,
  vars,
}: CreateProfileReturningTokenIdStruct): Promise<BigNumber> {
  const tokenId = await manager.connect(sender).callStatic.createProfile(vars);
  await expect(manager.connect(sender).createProfile(vars)).to.not.be.reverted;
  return tokenId;
}

export interface CreateHubReturningHubIdStruct {
  sender?: Signer;
  hub: DataTypes.HubDataStruct;
}

export async function createHubReturningHubId({
  sender = user,
  hub,
}: CreateHubReturningHubIdStruct): Promise<BigNumber> {
  const hubId = await manager.connect(sender).callStatic.createHub(hub);
  await expect(manager.connect(sender).createHub(hub)).to.not.be.reverted;
  return hubId;
}

export interface CreateProjectReturningProjectId {
  sender?: Signer;
  project: DataTypes.ProjectDataStruct;
}

export async function createProjectReturningProjectId({
  sender = user,
  project,
}: CreateProjectReturningProjectId): Promise<BigNumber> {
  const projectId = await manager.connect(sender).callStatic.createProject(project);
  await expect(manager.connect(sender).createProject(project)).to.not.be.reverted;
  return projectId;
}


export interface CollectReturningTokenIdStruct {
  sender?: Signer;
  vars: DataTypes.CollectDataStruct;
}

export async function collectReturningTokenId({
  sender = user,
  vars,
}: CollectReturningTokenIdStruct): Promise<BigNumber> {
  let tokenId = await manager
      .connect(sender)
      .callStatic.collect(vars);

    await expect(manager.connect(sender).collect(vars)).to.not.be
      .reverted;
  
  return tokenId;
}
