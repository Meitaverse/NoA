import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { parseEther } from '@ethersproject/units';

import {
  DerivativeNFTV1,
  DerivativeNFTV1__factory,
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

// yarn hardhat dNFT-tokenURI --projectid 1 --tokenid 1 --network local

task("dNFT-tokenURI", "get sbt tokenURI function")
.addParam("projectid", "project id")
.addParam("tokenid", "token id")
.setAction(async ({projectid, tokenid}: {projectid: number,tokenid: number}, hre) =>  {
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

  let derivativeNFT: DerivativeNFTV1;
  derivativeNFT = DerivativeNFTV1__factory.connect(
    await manager.connect(user).getDerivativeNFT(projectid),
    user
  );

  const contractURI = await derivativeNFT.contractURI();
  console.log('\n\t--- derivativeNFT  contractURI: \n', contractURI);

  const svg = await derivativeNFT.tokenURI(tokenid);

  console.log('\n\t--- derivativeNFT tokenURI of tokenId(', tokenid, '): \n', svg);

  const publishId = 1;
  const slot = await derivativeNFT.getSlot(publishId);
  const slotURI = await derivativeNFT.slotURI(slot);
  console.log('\n\t--- derivativeNFT slotURI of slot(',slot,'): \n', slotURI);

  });