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
  Events__factory,
} from '../typechain';

import { loadContract } from "./config";

import { deployContract, waitForTx , ProtocolState, Error, findEvent} from './helpers/utils';
import { ContractTransaction } from "ethers";

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local split --sbtid 2 --nftid 1

task("split", "split a dNFT function")
.addParam("sbtid", "soul bound token id ")
.addParam("nftid", "nft id")
.setAction(async ({sbtid, nftid}: {sbtid:number, nftid:number}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  
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

    let owner = accounts[sbtid];
    console.log('\n\t-- owner: ', owner.address);
    let balance =(await sbt["balanceOf(uint256)"](sbtid)).toNumber();

    console.log('\t--- balance of owner: ', (await sbt["balanceOf(uint256)"](sbtid)).toNumber());


    const FIRST_PROJECT_ID = 1; 
   
    console.log(
      "\n\t--- Split  ..."
    );

    let derivativeNFT: DerivativeNFT;
    derivativeNFT = DerivativeNFT__factory.connect(
      await manager.connect(owner).getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );

    let tx: ContractTransaction;

    tx = await
      derivativeNFT.connect(owner).split(
        FIRST_PROJECT_ID,
        nftid,
        owner.address,
        1, //unit
    );
    // const receipt = await waitForTx(
    //   derivativeNFT.connect(owner).split(
    //     FIRST_PROJECT_ID,
    //     nftid,
    //     owner.address,
    //     1,
    //   )
    // );

    const receipt = await tx.wait(1);
    const tokenId = receipt.events![0].args!._tokenId;
    console.log('split a new tokenId:', tokenId);


});