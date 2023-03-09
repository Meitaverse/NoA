import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import { loadContract } from "./config";

import {
  ModuleGlobals__factory,
  BankTreasury__factory,
  NFTDerivativeProtocolTokenV1__factory,
  Manager__factory,
  Voucher__factory,
  InteractionLogic__factory,
  ManagerV2__factory,
  PublishLogic__factory,
  TransparentUpgradeableProxy__factory,
} from '../typechain';

  // yarn hardhat --network local upgrade-manager
task('upgrade-manager', 'upgrade manager contract').setAction(async ({}, hre) => {
        // Note that the use of these signers is a placeholder and is not meant to be used in
        // production.
        const ethers = hre.ethers;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        const governance = accounts[1];  
        const user = accounts[2];
        const userTwo = accounts[3];
        const userThree = accounts[4];
        const admin = accounts[5];

        const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
        const manager = await loadContract(hre, Manager__factory, "Manager");
        const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
        const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
        const voucher = await loadContract(hre, Voucher__factory, "Voucher");
        const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");



        const interactionLogicAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";
        const publishLogicAddress = "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9";
        let managerLibs = {
          'contracts/libraries/InteractionLogic.sol:InteractionLogic': interactionLogicAddress,
          'contracts/libraries/PublishLogic.sol:PublishLogic': publishLogicAddress,
        };
        
        const newImpl = await new ManagerV2__factory(managerLibs, deployer).deploy();
        const proxyManager = TransparentUpgradeableProxy__factory.connect(
          manager.address, 
          admin
        );
        
        await proxyManager.upgradeTo(
          newImpl.address
        );
        const managerV2 = new ManagerV2__factory(managerLibs, deployer).attach(proxyManager.address);
       
        let valueToSet = 100;
       
        await managerV2.connect(user).setAdditionalValue(valueToSet);
});