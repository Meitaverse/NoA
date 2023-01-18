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
  Events__factory,
} from '../typechain';

import { loadContract } from "./config";

import { deployContract, waitForTx , ProtocolState, Error, findEvent} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat collect --collectorid 3 --publishid 1 --network local

task("collect", "collect a dNFT function")
.addParam("collectorid", "soul bound token id ")
.addParam("publishid", "publish id")
.setAction(async ({collectorid, publishid}: {collectorid:number, publishid:number}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  //治理合约地址
  const user = accounts[2];
  const userTwo = accounts[3];
  const userThree = accounts[4];
  const userFour = accounts[5];

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
  console.log('\t-- userFour: ', userFour.address);

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
    );

    let collector = accounts[collectorid];
    console.log('\n\t-- collector: ', collector.address);
    let balance =(await sbt["balanceOf(uint256)"](collectorid)).toNumber();
    if (balance == 0) {
      //mint 10000000 Value to user
      await manager.connect(governance).mintSBTValue(collectorid, 10000000);
    }
    console.log('\t--- balance of collector: ', (await sbt["balanceOf(uint256)"](collectorid)).toNumber());


    const FIRST_PROJECT_ID = 1; 
   
    console.log(
      "\n\t--- Collet  ..."
    );

    const receipt = await waitForTx(
      manager.connect(collector).collect({
        publishId: publishid,
        collectorSoulBoundTokenId: collectorid,
        collectUnits: 1,
        data: [],
      })
    );

    let eventsLib = await new Events__factory(deployer).deploy();
    // console.log('\n\t--- eventsLib address: ', eventsLib.address);

    const event = findEvent(receipt, 'DerivativeNFTCollected', eventsLib);
    const projectId = event.args.projectId.toNumber();
    const derivativeNFTAddress = event.args.derivativeNFT;
    const fromSoulBoundTokenId = event.args.fromSoulBoundTokenId.toNumber();
    const toSoulBoundTokenId = event.args.toSoulBoundTokenId.toNumber();
    const tokenId = event.args.tokenId.toNumber();
    const value = event.args.value.toNumber();
    const newTokenId = event.args.newTokenId.toNumber();

    console.log(
      "\n\t--- Event DerivativeNFTCollected emited ..."
    );
    console.log(
      "\t--- DerivativeNFTCollected, projectId: ", projectId
    );
    console.log(
      "\t--- DerivativeNFTCollected, derivativeNFT address: ", derivativeNFTAddress
    );
    console.log(
      "\t--- DerivativeNFTCollected, fromSoulBoundTokenId: ", fromSoulBoundTokenId
    );
    console.log(
      "\t--- DerivativeNFTCollected, toSoulBoundTokenId: ", toSoulBoundTokenId
    );
    console.log(
      "\t--- DerivativeNFTCollected, tokenId: ", tokenId
    );
    console.log(
      "\t--- DerivativeNFTCollected, collect value: ", value
    );
    console.log(
      "\t--- DerivativeNFTCollected, newTokenId: ", newTokenId
    );


    let derivativeNFT: DerivativeNFTV1;
    derivativeNFT = DerivativeNFTV1__factory.connect(
      await manager.connect(collector).getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );
      
    console.log('\n\t--- ownerOf newTokenId : ', await derivativeNFT.ownerOf(newTokenId));
    console.log('\t--- balanceOf newTokenId : ', (await derivativeNFT["balanceOf(uint256)"](newTokenId)).toNumber());
    
});