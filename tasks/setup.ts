import '@nomiclabs/hardhat-ethers';
import { hexlify, keccak256, parseEther, RLP } from 'ethers/lib/utils';
import fs from 'fs';
import { task } from 'hardhat/config';
// import { readFile, writeFile } from "fs/promises";
import { exportAddress, loadContract } from "./config";
import { exportSubgraphNetworksJson } from "./subgraph";

import {
    MIN_DELAY,
    QUORUM_PERCENTAGE,
    VOTING_PERIOD,
    VOTING_DELAY,
  } from "../helper-hardhat-config"

import {
    ERC1967Proxy__factory,
    PublishModule__factory,
    FeeCollectModule__factory,
    TimeLock__factory,
    InteractionLogic__factory,
    PublishLogic__factory,
    ModuleGlobals__factory,
    TransparentUpgradeableProxy__factory,
    ERC3525ReceiverMock__factory,
    GovernorContract__factory,
    BankTreasury__factory,
    DerivativeNFT__factory,
    NFTDerivativeProtocolTokenV1__factory,
    Manager__factory,
    Voucher__factory,
    DerivativeMetadataDescriptor__factory,
    Template__factory,
    MarketPlace__factory,
    SBTMetadataDescriptor__factory,
    MarketLogic__factory,
    Currency__factory,
    FETH__factory,
    RoyaltyRegistry__factory,
    VoucherMarket__factory,
    SBTLogic__factory,
  } from '../typechain';
  import { deployContract, waitForTx , ProtocolState, Error, ZERO_ADDRESS} from './helpers/utils';
  import { ManagerLibraryAddresses } from '../typechain/factories/contracts/Manager__factory';
  
  import { DataTypes } from '../typechain/contracts/modules/template/Template';
  import { MarketPlaceLibraryAddresses } from '../typechain/factories/contracts/MarketPlace__factory';
import { NFTDerivativeProtocolTokenV1LibraryAddresses } from '../typechain/factories/contracts/NFTDerivativeProtocolTokenV1__factory';
  
  const TREASURY_FEE_BPS = 500;
  const RECEIVER_MAGIC_VALUE = '0x009ce20b';
  const FIRST_PROFILE_ID = 1; 
  const INITIAL_SUPPLY =  1000000;
  const VOUCHER_AMOUNT_LIMIT = 100;  
  const SBT_NAME = 'Bitsoul Protocol';
  const SBT_SYMBOL = 'SOUL';
  const SBT_DECIMALS = 18;
  const MARKET_DURATION = 1200; // default: 24h in seconds
  const LOCKUP_DURATION = 86400; //24h in seconds
  const NUM_CONFIRMATIONS_REQUIRED = 3;
  const PublishRoyaltySBT = 100;
  
  let managerLibs: ManagerLibraryAddresses;
  export let sbtLibs: NFTDerivativeProtocolTokenV1LibraryAddresses;


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

        // console.log('\n\t-- moduleGlobals set whitelistProfileCreator --');
        // await waitForTx( moduleGlobals.connect(governance).whitelistProfileCreator(user.address, true));
        // await waitForTx( moduleGlobals.connect(governance).whitelistProfileCreator(userTwo.address, true));
        // await waitForTx( moduleGlobals.connect(governance).whitelistProfileCreator(userThree.address, true));
        
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


   });