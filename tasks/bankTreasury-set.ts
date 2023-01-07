import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

import {
  BankTreasury__factory,
  ModuleGlobals__factory,
} from '../typechain';

import { loadContract } from "./config";

import { deployContract, waitForTx , ProtocolState, Error} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;

task("bankTreasury-set", "bankTreasury-set function")
.setAction(async ({}: {}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];

  const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
  const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");

  console.log('\n\t--- bankTreasury set moduleGlobals address --');
  await waitForTx( bankTreasury.connect(governance).setGlobalModule(moduleGlobals.address));

  console.log(
    "\t--- bankTreasury name: ", (await bankTreasury.name())
  );

  console.log(
    "\t--- bankTreasury getManager(): ",(await bankTreasury.getManager())
  );

  console.log(
    "\t--- bankTreasury getSBT(): ", (await bankTreasury.getSBT())
    );
    
});