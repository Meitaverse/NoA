import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import { loadContract } from "./config";

import {
    
    ModuleGlobals__factory,
    BankTreasury__factory,
    NFTDerivativeProtocolTokenV1__factory,
    Manager__factory,
    Voucher__factory,

  } from '../typechain';
  import { waitForTx} from './helpers/utils';
  

  // yarn hardhat --network local mint-sbt

  task('mint-sbt', 'mint sbt to treasury').setAction(async ({}, hre) => {
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
        console.log('\n\t ---- balance of treasury: ', balance);

        // mint SBT
        await waitForTx(sbt.connect(deployer).setBankTreasury(
            bankTreasury.address, 
            50000000
        ));

        balance = await sbt['balanceOf(uint256)'](1);
        console.log('\n\t ---- After mint SBT, balance of treasury: ', balance);
  

  });