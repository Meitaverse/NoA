import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

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
} from '../typechain';

import { loadContract } from "./config";

export let runtimeHRE: HardhatRuntimeEnvironment;

task("manager-verify", "manager-verify function")
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

  const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
  const manager = await loadContract(hre, Manager__factory, "Manager");
  const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
  const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
  const voucher = await loadContract(hre, Voucher__factory, "Voucher");
  const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");

  console.log(
    "---\t manager version: ", (await managerImpl.version()).toNumber()
    );
  console.log(
      "---\t manager governance address: ", await manager.connect(user).getGovernance()
    );
  console.log(
    "---\t sbt contract version: ", (await sbt.version()).toNumber()
  );
  // console.log(
  //   "---\t sbt getManager(): ", (await sbt.getManager())
  // );
  // console.log(
  //   "---\t sbt getBankTreasury(): ", (await sbt.getBankTreasury())
  // );

  console.log(
    "---\t bankTreasury getManager(): ",(await bankTreasury.getManager())
  );

  console.log(
    "---\t bankTreasury name: ", (await bankTreasury.name())
  );

  console.log(
    "---\t bankTreasury getSBT(): ", (await bankTreasury.getSBT())
  );

  console.log(
    "---\t moduleGlobals getGovernance(): ", await moduleGlobals.getGovernance()
  );

  console.log(
    "---\t moduleGlobals tax: ", (await moduleGlobals.getPublishCurrencyTax()).toNumber()
  );
    

  console.log(
    "---\t voucher name: ", (await voucher.name())
  );

  console.log(
    "---\t voucher symbol: ", (await voucher.symbol())
  );

});