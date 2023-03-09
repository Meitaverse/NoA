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
  Voucher,
  VoucherV2,
} from '../typechain';

  // yarn hardhat --network local upgrade-voucher
task('upgrade-voucher', 'upgrade voucher contract').setAction(async ({}, hre) => {
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

        let voucherV2Impl = await hre.ethers.getContractFactory('VoucherV2');

        const voucherV2 = (await hre.upgrades.upgradeProxy(
          voucher.address,
          voucherV2Impl,
        )) as VoucherV2;

        console.log('\n\t ---- version: ', await voucherV2.version());

});