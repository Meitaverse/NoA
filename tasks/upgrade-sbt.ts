import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import { loadContract } from "./config";

import {
  ModuleGlobals__factory,
  BankTreasury__factory,
  NFTDerivativeProtocolTokenV1__factory,
  Manager__factory,
  Voucher__factory,
  NFTDerivativeProtocolTokenV2,
} from '../typechain';

  

task('upgrade-sbt', 'upgrade sbt contract').setAction(async ({}, hre) => {
        // Note that the use of these signers is a placeholder and is not meant to be used in
        // production.
        const ethers = hre.ethers;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        const governance = accounts[1];  
        const user = accounts[2];
        const userTwo = accounts[3];
        const userThree = accounts[4];

        const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
        const manager = await loadContract(hre, Manager__factory, "Manager");
        const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
        const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
        const voucher = await loadContract(hre, Voucher__factory, "Voucher");
        const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");

        console.log('\n\t ---- version: ', await  sbt.version());

        let balance = await sbt['balanceOf(uint256)'](1);
        console.log('\n\t ----Before upgrade, balance of treasury: ', balance);


        let sbtV2Impl = await hre.ethers.getContractFactory('NFTDerivativeProtocolTokenV2');
        
        const sbtV2 = (await hre.upgrades.upgradeProxy(
          sbt.address,
          sbtV2Impl,
        )) as NFTDerivativeProtocolTokenV2;

        
        console.log('\n\t ---- version: ', await sbtV2.version());

        balance = await sbtV2['balanceOf(uint256)'](1);
        console.log('\n\t ---- After upgraded, balance of treasury: ', balance);
  

});