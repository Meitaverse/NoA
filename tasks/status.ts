import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import {loadContract } from "./config";

import {
    PublishModule__factory,
    FeeCollectModule__factory,
    ModuleGlobals__factory,
    BankTreasury__factory,
    NFTDerivativeProtocolTokenV1__factory,
    Manager__factory,
    Voucher__factory,
    Template__factory,
    MarketPlace__factory,
    Currency__factory,
  } from '../typechain';
  
  const FIRST_PROFILE_ID = 1; 


  // yarn hardhat status --network local
  // yarn hardhat status --network mumbai

  task('status', 'Display stats of grant roles and setings').setAction(async ({}, hre) => {
        const ethers = hre.ethers;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        const governance = accounts[1];  
        const user = accounts[2];
        const userTwo = accounts[3];
        const userThree = accounts[4];
        const deployer2 = accounts[5];

        const proxyAdminAddress = deployer.address;
        
        const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
        const manager = await loadContract(hre, Manager__factory, "Manager");
        const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
        const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
        const market = await loadContract(hre, MarketPlace__factory, "MarketPlace");
        const voucher = await loadContract(hre, Voucher__factory, "Voucher");
        const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");
        const feeCollectModule = await loadContract(hre, FeeCollectModule__factory, "FeeCollectModule");
        const publishModule = await loadContract(hre, PublishModule__factory, "PublishModule");
        const template = await loadContract(hre, Template__factory, "Template");
        const currency = await loadContract(hre, Currency__factory, "Currency");
      
        let deployerBalance  = await hre.ethers.provider.getBalance(deployer.address);
        console.log('\t-- Balance of deployer:', deployerBalance);
        
        let governanceBalance  = await hre.ethers.provider.getBalance(governance.address)
        console.log('\t-- Balance of governance:', governanceBalance);

        let balance =  await sbt['balanceOf(uint256)'](FIRST_PROFILE_ID); 
        console.log('\t-- INITIAL SUPPLY of the first soul bound token id:', balance);
        
        let [
          currencyAmount, 
          sbtAmount
        ]  = await bankTreasury.getExchangePrice(sbt.address);

        console.log('\n\t--- bankTreasuryContract setExchangePrice ok');
        console.log('\t\t---  currencyAmount:', currencyAmount.toNumber(), ' sbtAmount=', sbtAmount.toNumber());
        
        const transferValueRole = await sbt.TRANSFER_VALUE_ROLE();
        if (await sbt.hasRole(transferValueRole, manager.address)) {
          console.log('\n\t--- manager haRole of transferValueRole in sbt is ok.');
        }
        if (await sbt.hasRole(transferValueRole, publishModule.address)) {
          console.log('\n\t--- publishModule haRole of transferValueRole in sbt is ok');
        }
        if (await sbt.hasRole(transferValueRole, feeCollectModule.address)) {
          console.log('\t--- feeCollectModule haRole of transferValueRole in sbt is ok');
        }
        if (await sbt.hasRole(transferValueRole, bankTreasury.address)) {
          console.log('\t--- bankTreasury haRole of transferValueRole in sbt is ok');
        }
        if (await sbt.hasRole(transferValueRole, voucher.address)) {
          console.log('\t--- voucher haRole of transferValueRole in sbt is ok');
        }
        if (await sbt.hasRole(transferValueRole, market.address)) {
          console.log('\t--- market place haRole of transferValueRole in sbt is ok');
        }
    
   });