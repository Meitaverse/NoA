import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import {
  developmentChains,
  VOTING_DELAY,
  proposalsFile,
  FUNC,
  PROPOSAL_DESCRIPTION,
  NEW_STORE_VALUE,
} from "../helper-hardhat-config"
import * as fs from "fs"
import { moveBlocks } from "../utils/move-blocks"

import {
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
  GovernorContract__factory,
  TimeLock__factory,
  Box__factory,
} from '../typechain';

import { loadContract } from "./config";

import { deployContract, waitForTx , ProtocolState, Error} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;


// yarn hardhat create-proposal --network local
task("create-proposal", "create-proposal function")
.setAction(async ({}: {}, hre) =>  {
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
  const governor = await loadContract(hre, GovernorContract__factory, "GovernorContract");
  const timeLock = await loadContract(hre, TimeLock__factory, "TimeLock");

  console.log('\t-- deployer: ', deployer.address);
  console.log('\t-- governance: ', governance.address);
  console.log('\t-- user: ', user.address);
  console.log('\t-- userTwo: ', userTwo.address);
  console.log('\t-- userThree: ', userThree.address);

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
    );
  
   // permit user to create a hub
   const SECOND_PROFILE_ID = 2;
   const THIRD_PROFILE_ID = 3;
   await waitForTx( moduleGlobals.connect(governance).whitelistHubCreator(SECOND_PROFILE_ID, true));

    console.log(
      "\n\t--- moduleGlobals whitelistHubCreator set true for user: ", userAddress
    );

    //mint Value to user for vote , value 必须大于90万
    await manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, 900000);
    let balanceOfUser =(await sbt['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber();
    console.log('balance of user: ', balanceOfUser);

    let balanceOfUserTwo =(await sbt['balanceOf(uint256)'](THIRD_PROFILE_ID)).toNumber();
    console.log('balance of userTwo: ', balanceOfUserTwo);

    await waitForTx(
      sbt.connect(user).delegate(userAddress, SECOND_PROFILE_ID)
    );

    console.log(`Checkpoints: ${await sbt.numCheckpoints(userAddress)}`);
    let checkpoints = await sbt.checkpoints(userAddress, 0);
    console.log(`checkpoints.fromBlock: ${checkpoints.fromBlock}`);
    console.log(`checkpoints.votes: ${checkpoints.votes}`);
 
     //返回 user 选择的委托。    
    console.log("delegates: ",await sbt.delegates(userAddress));


  });