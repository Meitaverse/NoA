import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { 
  ManagerImpl_ADDRESS, 
  Manager_ADDRESS, 
  Bank_Treasury_ADDRESS, 
  NDP_ADDRESS,
  Voucher_ADDRESS,
  ModuleGlobals_ADDRESS,
 } from './addresses';

import {
  Manager__factory,
} from '../typechain';

import { deployContract, waitForTx , ProtocolState, Error} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;

task("bankTreasury-set", "bankTreasury-set function")
// .addParam("manager", "address of manager")
.setAction(async ({}: {}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];

  const managerImpl = await ethers.getContractAt("Manager", ManagerImpl_ADDRESS);
  const manager = Manager__factory.connect(Manager_ADDRESS, governance);
  const bankTreasury = await ethers.getContractAt("BankTreasury", Bank_Treasury_ADDRESS);
  const ndp = await ethers.getContractAt("NFTDerivativeProtocolTokenV1", NDP_ADDRESS);
  const voucher = await ethers.getContractAt("Voucher", Voucher_ADDRESS);
  const moduleGlobals = await ethers.getContractAt("ModuleGlobals", ModuleGlobals_ADDRESS);

  console.log('\n\t-- bankTreasury set moduleGlobals address --');
  await waitForTx( bankTreasury.connect(governance).setGlobalModule(moduleGlobals.address));

  console.log(
    "---\t bankTreasury name: ", (await bankTreasury.name())
  );

  console.log(
    "---\t bankTreasury getManager(): ",(await bankTreasury.getManager())
  );

  console.log(
    "---\t bankTreasury getNDPT(): ", (await bankTreasury.getNDPT())
    );
    
});