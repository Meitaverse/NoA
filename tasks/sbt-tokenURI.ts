import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { parseEther } from '@ethersproject/units';

import {
  DerivativeNFT,
  DerivativeNFT__factory,
  FeeCollectModule,
  FeeCollectModule__factory,
  PublishLogic__factory,
  ModuleGlobals,
  ModuleGlobals__factory,
  TransparentUpgradeableProxy__factory,
  BankTreasury,
  BankTreasury__factory,
  NFTDerivativeProtocolTokenV1,
  NFTDerivativeProtocolTokenV1__factory,
  Manager,
  Manager__factory,
  Voucher,
  Voucher__factory,
  DerivativeMetadataDescriptor,
  DerivativeMetadataDescriptor__factory,
  Template,
  Template__factory,
  PublishModule__factory,
} from '../typechain';

import { loadContract } from "./config";

import { deployContract, waitForTx , ProtocolState, Error} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat sbt-tokenURI --tokenid 2 --network local

task("sbt-tokenURI", "get sbt tokenURI function")
.addParam("tokenid", "token id")
.setAction(async ({tokenid}: {tokenid: number}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  //治理合约地址
  const user = accounts[2];
  const userTwo = accounts[3];
  const userThree = accounts[4];

  const userAddress = user.address;
  const userTwoAddress = userTwo.address;
  const userThreeAddress = userThree.address;

  const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
  const manager = await loadContract(hre, Manager__factory, "Manager");
  const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
  const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
  const voucher = await loadContract(hre, Voucher__factory, "Voucher");
  const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");
  const feeCollectModule = await loadContract(hre, FeeCollectModule__factory, "FeeCollectModule");
  const publishModule = await loadContract(hre, PublishModule__factory, "PublishModule");
  const template = await loadContract(hre, Template__factory, "Template");

  const contractURI = await sbt.contractURI();
  console.log('\n\t--- contractURI: \n', contractURI);

  const svg = await sbt.tokenURI(tokenid);

  console.log('\n\t--- tokenURI of tokenId(', tokenid, '): \n', svg);

  const slotURI = await sbt.slotURI(1);
  console.log('\n\t--- slotURI of slot(1): \n', slotURI);

  });