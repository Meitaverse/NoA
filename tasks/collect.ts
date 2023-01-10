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

// yarn hardhat collect --collectorid 3 --nftid 1 --network local

task("collect", "collect a dNFT function")
.addParam("collectorid", "soul bound token id ")
.addParam("nftid", "derivative nft id to collect")
.setAction(async ({collectorid, nftid}: {collectorid:number, nftid: number}, hre) =>  {
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

  console.log('\t-- deployer: ', deployer.address);
  console.log('\t-- governance: ', governance.address);
  console.log('\t-- user: ', user.address);
  console.log('\t-- userTwo: ', userTwo.address);
  console.log('\t-- userThree: ', userThree.address);

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
    );

    let collector = accounts[collectorid];
    console.log('\n\t-- collector: ', collector.address);
    let balance =(await sbt["balanceOf(uint256)"](collectorid)).toNumber();
    // if (balance == 0) {
      //mint 1000Value to user
      await manager.connect(governance).mintSBTValue(collectorid, 1000);
    // }
    console.log('\t--- balance of collector: ', (await sbt["balanceOf(uint256)"](collectorid)).toNumber());


    const FIRST_PROJECT_ID =1; 
    const FIRST_PUBLISH_ID =1; 
   
    console.log(
      "\n\t--- Collet  ..."
    );

    await waitForTx(
      manager.connect(collector).collect({
        publishId: FIRST_PUBLISH_ID,
        collectorSoulBoundTokenId: collectorid,
        collectValue: 1,
        data: [],
      })
    );

    let derivativeNFT: DerivativeNFTV1;
    derivativeNFT = DerivativeNFTV1__factory.connect(
      await manager.connect(collector).getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );
      
    console.log('\n\t--- ownerOf nftid : ', await derivativeNFT.ownerOf(nftid));
    console.log('\t--- balanceOf nftid : ', (await derivativeNFT["balanceOf(uint256)"](nftid)).toNumber());
    
});