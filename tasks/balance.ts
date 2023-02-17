import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

import {
  ModuleGlobals__factory,
  BankTreasury__factory,
  NFTDerivativeProtocolTokenV1__factory,
  Manager__factory,
  Voucher__factory,
} from '../typechain';

import { loadContract } from "./config";

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network mumbai balance --sbtid 2

task("balance", "balance function")
.addParam("sbtid", "sbt id")
.setAction(async ({sbtid}: {sbtid : number}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  
  const user = accounts[2];
  const userTwo = accounts[3];
  const userThree = accounts[4];
  const userFour = accounts[5];
  const userFive = accounts[6];


  const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
  const manager = await loadContract(hre, Manager__factory, "Manager");
  const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
  const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
  const voucher = await loadContract(hre, Voucher__factory, "Voucher");
  const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");

  // console.log('\t-- deployer: ', deployer.address);
  // console.log('\t-- governance: ', governance.address);
  // console.log('\t-- user: ', user.address);
  // console.log('\t-- userTwo: ', userTwo.address);
  // console.log('\t-- userThree: ', userThree.address);
  // console.log('\t-- userFour: ', userFour.address);


  let balance = await sbt["balanceOf(uint256)"](sbtid);
  console.log(
    "\n\t--- balance Of sbtid(", sbtid, " ) is ", balance
  );
});