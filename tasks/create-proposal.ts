import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

import {
  ModuleGlobals__factory,
  BankTreasury__factory,
  NFTDerivativeProtocolTokenV1__factory,
  Manager__factory,
  Voucher__factory,
  GovernorContract__factory,
  TimeLock__factory,
} from '../typechain';

import { loadContract } from "./config";

import { waitForTx } from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;


// yarn hardhat --network local create-proposal

task("create-proposal", "create-proposal function")
.setAction(async ({}: {}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  
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

    //mint Value to user for vote , value 必须大于90%
    await bankTreasury.connect(user).buySBT(SECOND_PROFILE_ID, {value: 10000});
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