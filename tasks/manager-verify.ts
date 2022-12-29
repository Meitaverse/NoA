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

export let runtimeHRE: HardhatRuntimeEnvironment;

task("manager-verify", "manager-verify function")
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

  console.log(
    "---\t manager version: ", (await managerImpl.version()).toNumber()
    );
  console.log(
      "---\t manager NDPT address: ", await manager.NDPT()
    );
  console.log(
    "---\t ndp contract version: ", (await ndp.version()).toNumber()
  );
  console.log(
    "---\t ndp getManager(): ", (await ndp.getManager())
  );
  console.log(
    "---\t ndp getManager(): ", (await ndp.getBankTreasury())
  );

  console.log(
    "---\t bankTreasury getManager(): ",(await bankTreasury.getManager())
  );

  console.log(
    "---\t bankTreasury name: ", (await bankTreasury.name())
  );
  console.log(
    "---\t bankTreasury getNDPT(): ", (await bankTreasury.getNDPT())
    );
    console.log(
      "---\t moduleGlobals tax: ", (await moduleGlobals.getPublishCurrencyTax(ndp.address)).toNumber()
      );
      

    console.log(
      "---\t voucher name: ", (await voucher.name())
    );
  
    console.log(
      "---\t voucher symbol: ", (await voucher.symbol())
    );

});