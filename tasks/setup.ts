import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import { loadContract } from "./config";

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
  import { waitForTx , ProtocolState, Error, ZERO_ADDRESS} from './helpers/utils';
  
  
  const FIRST_PROFILE_ID = 1; 
  const INITIAL_SUPPLY =  1000000;
  const VOUCHER_AMOUNT_LIMIT = 100;  

  // yarn setup-mumbai

  task('setup', 'setup grant roles and setings').setAction(async ({}, hre) => {
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
      
        /*
        let deployerBalance  = await hre.ethers.provider.getBalance(deployer.address);
        if (deployerBalance.eq(0)) {
           console.log('\t\t Failed!!! Balance of deployer is 0');
           return
        } else {
          console.log('\t-- Balance of deployer:', deployerBalance);
        }

        let governanceBalance  = await hre.ethers.provider.getBalance(governance.address)
        if (governanceBalance.eq(0)) {
           console.log('\t\t Failed!!! Balance of governance is 0');
           return
        }else {
          console.log('\t-- Balance of governance:', governanceBalance);
        }

        await waitForTx(
            manager.connect(governance).setGlobalModules(moduleGlobals.address)
        );
  
        console.log('\n\t-- sbt set bankTreasuryContract address and INITIAL SUPPLY --');
        await waitForTx(sbt.connect(deployer).setBankTreasury(
            bankTreasury.address, 
            INITIAL_SUPPLY
        ));
        let balance =  await sbt['balanceOf(uint256)'](FIRST_PROFILE_ID); 
        console.log('\t-- INITIAL SUPPLY of the first soul bound token id:', balance);
        
        console.log('\n\t-- Whitelisting sbt Contract address --');
        const transferValueRole = await sbt.TRANSFER_VALUE_ROLE();
        await waitForTx( sbt.connect(deployer).grantRole(transferValueRole, sbt.address));
        await waitForTx( sbt.connect(deployer).grantRole(transferValueRole, manager.address));
        await waitForTx( sbt.connect(deployer).grantRole(transferValueRole, publishModule.address));
        await waitForTx( sbt.connect(deployer).grantRole(transferValueRole, feeCollectModule.address));
        await waitForTx( sbt.connect(deployer).grantRole(transferValueRole, bankTreasury.address));
        await waitForTx( sbt.connect(deployer).grantRole(transferValueRole, voucher.address));
        await waitForTx( sbt.connect(deployer).grantRole(transferValueRole, market.address));
        
        await waitForTx(
          bankTreasury.connect(deployer).grantFeeModule(feeCollectModule.address)
        );
        await waitForTx(
          bankTreasury.connect(deployer).grantFeeModule(market.address)
        );

        await waitForTx(
            market.connect(governance).grantOperator(governance.address)
        );
          
        console.log('\n\t-- Add publishModule,feeCollectModule,template to moduleGlobals whitelists --');
        await waitForTx( moduleGlobals.connect(governance).whitelistPublishModule(publishModule.address, true));
        await waitForTx( moduleGlobals.connect(governance).whitelistCollectModule(feeCollectModule.address, true));
        await waitForTx( moduleGlobals.connect(governance).whitelistTemplate(template.address, true));

        console.log('\n\t-- voucher set moduleGlobals address --');
        await waitForTx( voucher.connect(deployer).setUserAmountLimit(VOUCHER_AMOUNT_LIMIT));

        console.log('\n\t-- bankTreasuryContract set moduleGlobals and  marketPlace--');
        await waitForTx( bankTreasury.connect(governance).setGlobalModules(moduleGlobals.address));
        await waitForTx( bankTreasury.connect(governance).setFoundationMarket(market.address));
        
        console.log('\n\t-- market set moduleGlobals address --');
        await waitForTx( market.connect(governance).setGlobalModules(moduleGlobals.address));

        console.log('\n\t-- manager set Protocol state to unpaused --');
        await waitForTx( manager.connect(governance).setState(ProtocolState.Unpaused));

        // Whitelist the currency
        console.log('\n\t-- Whitelisting SBT in Module Globals --');
        await waitForTx(
            moduleGlobals
            .connect(governance)
            .whitelistCurrency(sbt.address, true)
        );

        console.log('\t-- Whitelisting Currency in Module Globals --');
        await waitForTx(
            moduleGlobals
            .connect(governance)
            .whitelistCurrency(currency.address, true)
        );
    
        console.log('\n\t-- bankTreasuryContract setExchangePrice, 1 Ether = 1000 SBT Value');
        await waitForTx( bankTreasury.connect(governance).setExchangePrice(sbt.address, 1, 1000));
        
        if (await manager.connect(governance).getGlobalModule() == ZERO_ADDRESS) {
            console.log('\n\t ==== error: manager not set ModuleGlobas ====');
        }
        
        if (await bankTreasury.getGlobalModule() == ZERO_ADDRESS) {
            console.log('\n\t ==== error: bankTreasury not set ModuleGlobas ====');
        }
        
        if (await market.getGlobalModule() == ZERO_ADDRESS) {
            console.log('\n\t ==== error: marketPlace not set ModuleGlobas ====');
        }
        */

        // Admins can register extensions or set token uri
        await waitForTx( voucher.connect(deployer).approveAdmin(governance.address) );

   });