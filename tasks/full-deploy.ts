import '@nomiclabs/hardhat-ethers';
import { hexlify, keccak256, parseEther, RLP } from 'ethers/lib/utils';
import fs from 'fs';
import { task } from 'hardhat/config';
// import { readFile, writeFile } from "fs/promises";
import { exportAddress } from "./config";
import { exportSubgraphNetworksJson } from "./subgraph";

import {
    MIN_DELAY,
    QUORUM_PERCENTAGE,
    VOTING_PERIOD,
    VOTING_DELAY,
  } from "../helper-hardhat-config"

import {
    ERC1967Proxy__factory,
    Events,
    Events__factory,
    PublishModule,
    PublishModule__factory,
    FeeCollectModule,
    FeeCollectModule__factory,
    Helper,
    Helper__factory,
    Box,
    Box__factory,
    TimeLock,
    TimeLock__factory,
    InteractionLogic__factory,
    PublishLogic__factory,
    ModuleGlobals,
    ModuleGlobals__factory,
    TransparentUpgradeableProxy__factory,
    ERC3525ReceiverMock,
    ERC3525ReceiverMock__factory,
    GovernorContract,
    GovernorContract__factory,
    BankTreasury,
    BankTreasury__factory,
    DerivativeNFT,
    DerivativeNFT__factory,
    NFTDerivativeProtocolTokenV1,
    NFTDerivativeProtocolTokenV2,
    NFTDerivativeProtocolTokenV1__factory,
    NFTDerivativeProtocolTokenV2__factory,
    Manager,
    Manager__factory,
    Voucher,
    Voucher__factory,
    DerivativeMetadataDescriptor,
    DerivativeMetadataDescriptor__factory,
    Template,
    Template__factory,
    MarketPlace,
    MarketPlace__factory,
    SBTMetadataDescriptor__factory,
    MarketLogic__factory,
    Currency__factory,
    FETH,
    FETH__factory,
    RoyaltyRegistry__factory,
    VoucherMarket__factory,
  } from '../typechain';
  import { deployContract, waitForTx , ProtocolState, Error, ZERO_ADDRESS} from './helpers/utils';
  import { ManagerLibraryAddresses } from '../typechain/factories/contracts/Manager__factory';
  
  import { DataTypes } from '../typechain/contracts/modules/template/Template';
  import { MarketPlaceLibraryAddresses } from '../typechain/factories/contracts/MarketPlace__factory';
  
  const TREASURY_FEE_BPS = 500;
  const RECEIVER_MAGIC_VALUE = '0x009ce20b';
  const FIRST_PROFILE_ID = 1; 
  const INITIAL_SUPPLY =  1000000;
  const VOUCHER_AMOUNT_LIMIT = 100;  
  

  const SBT_NAME = 'NFT Derivative Protocol';
  const SBT_SYMBOL = 'SBT';
  const SBT_DECIMALS = 18;
  
  //TODO
  const MARKET_DURATION = 1200; // default: 1 days in seconds

  const LOCKUP_DURATION = 86400; //24h in seconds
  
  const NUM_CONFIRMATIONS_REQUIRED = 3;
  const PublishRoyaltySBT = 100;
  
  let managerLibs: ManagerLibraryAddresses;

  // yarn full-deploy-local

  task('full-deploy', 'deploys the entire NFT Derivative Protocol').setAction(async ({}, hre) => {
        // Note that the use of these signers is a placeholder and is not meant to be used in
        // production.
        const ethers = hre.ethers;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        const governance = accounts[1];  
        const user = accounts[2];
        const userTwo = accounts[3];
        const userThree = accounts[4];

        const proxyAdminAddress = deployer.address;

        // Nonce management in case of deployment issues
        let deployerNonce = await ethers.provider.getTransactionCount(deployer.address);

        //Template
        let canvas: DataTypes.CanvasDataStruct = {width:800, height:600};
        let watermark: DataTypes.CanvasDataStruct = {width:200, height:300};
        let position: DataTypes.PositionStruct = {x:400, y: 0};

        console.log('\t-- deployer: ', deployer.address);
        console.log('\t-- governance: ', governance.address);
        console.log('\t-- user: ', user.address);
        console.log('\t-- userTwo: ', userTwo.address);
        console.log('\t-- userThree: ', userThree.address);

        console.log('\n\t-- Deploying template  --');
        const template = await deployContract(
            new Template__factory(deployer).deploy(
                1,
                "WaterMark",
                "descript for this template",
                "image",
                canvas,
                watermark,
                position,
              { nonce: deployerNonce++ }
            )
        );
        console.log('\t-- template: ', template.address);
        await exportAddress(hre, template, 'Template');

        // box = await new Box__factory(deployer).deploy();
        // console.log("box address: ", box.address);
      
        // timeLock = await new TimeLock__factory(deployer).deploy(MIN_DELAY, [], [], deployer.address);
        // console.log("timeLock address: ", timeLock.address);
        console.log('\n\t-- Deploying timeLock  --');
        const timeLock = await deployContract(
            new TimeLock__factory(deployer).deploy(
                MIN_DELAY, 
                [], 
                [], 
                deployer.address,
                { nonce: deployerNonce++ }
            )
        );
        console.log('\t-- timeLock: ', timeLock.address);
        await exportAddress(hre, timeLock, 'TimeLock');

      
        console.log('\n\t-- Deploying receiver  --');
        const receiverMock = await deployContract(
            new ERC3525ReceiverMock__factory(deployer).deploy(
                RECEIVER_MAGIC_VALUE, 
                Error.None,
              { nonce: deployerNonce++ }
            )
        );
        console.log('\t-- Receiver: ', receiverMock.address);
        await exportAddress(hre, receiverMock, 'Receiver');
        await exportSubgraphNetworksJson(hre, receiverMock, 'Receiver');
    
        console.log('\n\t-- Deploying interactionLogic  --');
        const interactionLogic = await deployContract(
            new InteractionLogic__factory(deployer).deploy(
              { nonce: deployerNonce++ }
            )
        );
        console.log('\t-- interactionLogic: ', interactionLogic.address);

        console.log('\n\t-- Deploying publishLogic  --');
        const publishLogic = await deployContract(
            new PublishLogic__factory(deployer).deploy(
              { nonce: deployerNonce++ }
            )
        );
        console.log('\t-- publishLogic: ', publishLogic.address);

        managerLibs = {
            'contracts/libraries/InteractionLogic.sol:InteractionLogic': interactionLogic.address,
            'contracts/libraries/PublishLogic.sol:PublishLogic': publishLogic.address,
        };
        
        console.log('\n\t-- Deploying Manager Implementation --');

        const derivativeNFTNonce = hexlify(deployerNonce + 1);
        const managerProxyNonce = hexlify(deployerNonce + 2);
      
        const derivativeNFTImplAddress =
            '0x' + keccak256(RLP.encode([deployer.address, derivativeNFTNonce])).substr(26);

        const managerProxyAddress =
            '0x' + keccak256(RLP.encode([deployer.address, managerProxyNonce])).substr(26);
        

        const managerImpl = await deployContract(
            new Manager__factory(managerLibs, deployer).deploy(
                derivativeNFTImplAddress, 
                receiverMock.address,
                { nonce: deployerNonce++,}
            )
        );
        console.log('\t-- managerImpl address: ', managerImpl.address);

        await exportAddress(hre, managerImpl, 'ManagerImpl');


        console.log('\n\t-- Deploying derivativeNFT Implementations --');
        await deployContract(
          new DerivativeNFT__factory(deployer).deploy(managerProxyAddress, { nonce: deployerNonce++ })
        );

        console.log('\n\t-- Deploying Manager --');

        let data = managerImpl.interface.encodeFunctionData('initialize', [
            governance.address
          ]);

        let proxy = await deployContract(
            new TransparentUpgradeableProxy__factory(deployer).deploy(
                managerImpl.address,
                proxyAdminAddress,
                data,
                { nonce: deployerNonce++ }
            )
        );
       
        console.log('\t-- manager proxy address: ', proxy.address);
        await exportAddress(hre, proxy, 'Manager');
        


        // Connect the manager proxy to the Manager factory and the governance for ease of use.
        const manager = Manager__factory.connect(proxy.address, governance);

        // console.log('\t-- manager: ', manager.address);
        await exportSubgraphNetworksJson(hre, manager, 'Manager');
    

        console.log('\n\t-- Deploying SBT --');

        //SBT descriptor
        const  sbtMetadataDescriptor = await new SBTMetadataDescriptor__factory(deployer).deploy(
                manager.address,
                { nonce: deployerNonce++ }
        );
     
        const sbtImpl = await deployContract(
            new NFTDerivativeProtocolTokenV1__factory(deployer).deploy(
                { nonce: deployerNonce++ }
            )
        );

        let initializeSBTData = sbtImpl.interface.encodeFunctionData("initialize", [
            SBT_NAME, 
            SBT_SYMBOL, 
            SBT_DECIMALS,
            manager.address,
            sbtMetadataDescriptor.address,
        ]);
        const sbtProxy = await new ERC1967Proxy__factory(deployer).deploy(
            sbtImpl.address,
            initializeSBTData,
            { nonce: deployerNonce++ }
        );
        const sbtContract = new NFTDerivativeProtocolTokenV1__factory(deployer).attach(sbtProxy.address);
        console.log('\t-- sbtContract: ', sbtContract.address);
        await exportAddress(hre, sbtContract, 'SBT');
        await exportSubgraphNetworksJson(hre, sbtContract, 'SBT');


        console.log('\n\t-- Deploying voucher --');
        const voucherImpl = await deployContract(
            new Voucher__factory(deployer).deploy(sbtContract.address, { nonce: deployerNonce++ })
        );

        let initializeVoucherData = voucherImpl.interface.encodeFunctionData("initialize", [
            "Voucher Bitsoul",
            "Voucher",
        ]);
        const voucherProxy = await new ERC1967Proxy__factory(deployer).deploy(
            voucherImpl.address,
            initializeVoucherData,
            { nonce: deployerNonce++ }
        );
        const voucherContract = new Voucher__factory(deployer).attach(voucherProxy.address);
        console.log('\t-- voucherContract: ', voucherContract.address);
        await exportAddress(hre, voucherContract, 'Voucher');
        await exportSubgraphNetworksJson(hre, voucherContract, 'Voucher');

        const governorImpl = await new GovernorContract__factory(deployer).deploy({ nonce: deployerNonce++ });
        let initializeDataGovrnor = governorImpl.interface.encodeFunctionData("initialize", [
            sbtContract.address,
            timeLock.address,
            QUORUM_PERCENTAGE, 
            VOTING_PERIOD,
            VOTING_DELAY,
        ]);

        const gonvernorProxy = await new ERC1967Proxy__factory(deployer).deploy(
            governorImpl.address,
            initializeDataGovrnor,
            { nonce: deployerNonce++ }
            );
        const governorContract = new GovernorContract__factory(deployer).attach(gonvernorProxy.address);
        console.log("\t-- governorContract address: ", governorContract.address);
        await exportAddress(hre, governorContract, 'GovernorContract');
        // await exportSubgraphNetworksJson(hre, governorContract, 'GovernorContract');

        console.log('\n\t-- Deploying bank treasury --');
        const soulBoundTokenIdOfBankTreaury = 1;
        const bankTreasuryImpl = await deployContract(
            new BankTreasury__factory(deployer).deploy(
                { nonce: deployerNonce++ })
        );

        let initializeData = bankTreasuryImpl.interface.encodeFunctionData("initialize", [
            deployer.address,
            governance.address,
            soulBoundTokenIdOfBankTreaury,
            [user.address, userTwo.address, userThree.address],
            NUM_CONFIRMATIONS_REQUIRED,  //All full signed 
            LOCKUP_DURATION, 
        ]);
      
        const bankTreasuryProxy = await new ERC1967Proxy__factory(deployer).deploy(
          bankTreasuryImpl.address,
          initializeData,
          { nonce: deployerNonce++ }
        );
        const bankTreasuryContract = new BankTreasury__factory(deployer).attach(bankTreasuryProxy.address);
        console.log('\t-- bankTreasuryContract: ', bankTreasuryContract.address);
        await exportAddress(hre, bankTreasuryContract, 'BankTreasury');
        await exportSubgraphNetworksJson(hre, bankTreasuryContract, 'BankTreasury');

        
        console.log('\n\t-- Deploying market place --');
        let marketLibs:MarketPlaceLibraryAddresses
        const marketLogic = await new MarketLogic__factory(deployer).deploy({ nonce: deployerNonce++ });
        marketLibs = {
          'contracts/libraries/MarketLogic.sol:MarketLogic': marketLogic.address,
        };
        const marketPlaceImpl = await deployContract(
            new MarketPlace__factory(marketLibs, deployer).deploy(
                bankTreasuryContract.address,
                MARKET_DURATION,
                { nonce: deployerNonce++ })
        );

        let initializeDataMarket = marketPlaceImpl.interface.encodeFunctionData("initialize", [
          governance.address
        ]);
      
        const marketPlaceProxy = await new ERC1967Proxy__factory(deployer).deploy(
            marketPlaceImpl.address,
            initializeDataMarket,
          { nonce: deployerNonce++ }
        );
        const marketPlaceContract = new MarketPlace__factory(marketLibs, deployer).attach(marketPlaceProxy.address);
        console.log('\t-- marketPlaceContract: ', marketPlaceContract.address);
        await exportAddress(hre, marketPlaceContract, 'MarketPlace');
        await exportSubgraphNetworksJson(hre, marketPlaceContract, 'MarketPlace');

        console.log('\n\t-- Deploying moduleGlobals --');
        const moduleGlobals = await deployContract(
            new ModuleGlobals__factory(deployer).deploy(
                manager.address,
                sbtContract.address,
                governance.address,
                bankTreasuryContract.address,
                marketPlaceContract.address,
                voucherContract.address,
                TREASURY_FEE_BPS,
                PublishRoyaltySBT,
                { nonce: deployerNonce++ })
        );
        console.log('\t-- moduleGlobals: ', moduleGlobals.address);
        await exportAddress(hre, moduleGlobals, 'ModuleGlobals');
        await exportSubgraphNetworksJson(hre, moduleGlobals, 'ModuleGlobals');

        
        console.log('\n\t-- Deploying metadataDescriptor  --');
        const metadataDescriptor = await deployContract(
            new DerivativeMetadataDescriptor__factory(deployer).deploy(
                moduleGlobals.address,
              { nonce: deployerNonce++ }
            )
        );
        console.log('\t-- metadataDescriptor: ', metadataDescriptor.address);
        await exportAddress(hre, metadataDescriptor, 'MetadataDescriptor');

        // Modules
        console.log('\n\t-- Deploying feeCollectModule --');
        const feeCollectModule = await deployContract(
            new FeeCollectModule__factory(deployer).deploy(
                manager.address, 
                marketPlaceContract.address,
                moduleGlobals.address,
                { nonce: deployerNonce++ })
        );
        console.log('\t-- feeCollectModule: ', feeCollectModule.address);
        await exportAddress(hre, feeCollectModule, 'FeeCollectModule');
        await exportSubgraphNetworksJson(hre, feeCollectModule, 'FeeCollectModule');

        console.log('\n\t-- Deploying publishModule --');
        const publishModule = await deployContract(
            new PublishModule__factory(deployer).deploy(
                manager.address, 
                marketPlaceContract.address,
                moduleGlobals.address,
                { nonce: deployerNonce++ })
        );
        console.log('\t-- publishModule: ', publishModule.address);
        await exportAddress(hre, publishModule, 'PublishModule');
        
        // Currency -ERC20
        console.log('\n\t-- Deploying Currency --');
        const currency = await deployContract(
            new Currency__factory(deployer).deploy({ nonce: deployerNonce++ })
        );

        // FETH
        console.log('\n\t-- Deploying FETH --');


        const fethImpl = await new FETH__factory(deployer).deploy(
            LOCKUP_DURATION
          )
        
         const royaltyRegistry = await new RoyaltyRegistry__factory(deployer).deploy();
        
         const voucherMarketImpl = await new VoucherMarket__factory(deployer).deploy(
            bankTreasuryContract.address,
            fethImpl.address,
            royaltyRegistry.address
          );
        
          let voucherMarketData= voucherMarketImpl.interface.encodeFunctionData("initialize", [
            await governance.getAddress(),
          ]);
        
          const voucherMarketProxy = await new ERC1967Proxy__factory(deployer).deploy(
            voucherMarketImpl.address,
            voucherMarketData
          );
          const voucherMarketContract = new VoucherMarket__factory(deployer).attach(voucherMarketProxy.address);
          console.log("voucherMarketContract.address: ", voucherMarketContract.address);
          await exportAddress(hre, voucherMarketContract, 'VoucherMarket');
          await exportSubgraphNetworksJson(hre, voucherMarketContract, 'VoucherMarket');
          
          
          //feth init
        
          let fethData= fethImpl.interface.encodeFunctionData("initialize", [
            voucherMarketContract.address,
          ]);
        
          const fethProxy = await new ERC1967Proxy__factory(deployer).deploy(
            fethImpl.address,
            fethData
          );
          const feth = new FETH__factory(deployer).attach(fethProxy.address);
          console.log("feth.address: ", feth.address);   
          await exportAddress(hre, feth, 'FETH');
          await exportSubgraphNetworksJson(hre, feth, 'FETH');
          
        
        await waitForTx(
            manager.connect(governance).setGlobalModules(moduleGlobals.address)
        );
  
        console.log('\n\t-- sbtContract set bankTreasuryContract address and INITIAL SUPPLY --');
        await waitForTx(sbtContract.connect(deployer).setBankTreasury(
            bankTreasuryContract.address, 
            INITIAL_SUPPLY
        ));
        let balance =  await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID); 
        console.log('\t-- INITIAL SUPPLY of the first soul bound token id:', balance);
        
        console.log('\n\t-- Whitelisting sbtContract Contract address --');
        const transferValueRole = await sbtContract.TRANSFER_VALUE_ROLE();
        await waitForTx( sbtContract.connect(deployer).grantRole(transferValueRole, manager.address));
        await waitForTx( sbtContract.connect(deployer).grantRole(transferValueRole, publishModule.address));
        await waitForTx( sbtContract.connect(deployer).grantRole(transferValueRole, feeCollectModule.address));
        await waitForTx( sbtContract.connect(deployer).grantRole(transferValueRole, bankTreasuryContract.address));
        await waitForTx( sbtContract.connect(deployer).grantRole(transferValueRole, voucherContract.address));
        await waitForTx( sbtContract.connect(deployer).grantRole(transferValueRole, marketPlaceContract.address));
        
        await waitForTx(
          bankTreasuryContract.connect(deployer).grantFeeModule(feeCollectModule.address)
        );
        await waitForTx(
          bankTreasuryContract.connect(deployer).grantFeeModule(marketPlaceContract.address)
        );

        await waitForTx(
            marketPlaceContract.connect(governance).grantOperator(governance.address)
        );
          
        console.log('\n\t-- Add publishModule,feeCollectModule,template to moduleGlobals whitelists --');
        await waitForTx( moduleGlobals.connect(governance).whitelistPublishModule(publishModule.address, true));
        await waitForTx( moduleGlobals.connect(governance).whitelistCollectModule(feeCollectModule.address, true));
        await waitForTx( moduleGlobals.connect(governance).whitelistTemplate(template.address, true));

        console.log('\n\t-- voucherContract set moduleGlobals address --');
        await waitForTx( voucherContract.connect(deployer).setUserAmountLimit(VOUCHER_AMOUNT_LIMIT));

        console.log('\n\t-- bankTreasuryContract set moduleGlobals and  marketPlace--');
        await waitForTx( bankTreasuryContract.connect(governance).setGlobalModules(moduleGlobals.address));
        await waitForTx( bankTreasuryContract.connect(governance).setFoundationMarket(marketPlaceContract.address));
        
        console.log('\n\t-- marketPlaceContract set moduleGlobals address --');
        await waitForTx( marketPlaceContract.connect(governance).setGlobalModules(moduleGlobals.address));

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
            .whitelistCurrency(sbtContract.address, true)
        );

        console.log('\t-- Whitelisting Currency in Module Globals --');
        await waitForTx(
            moduleGlobals
            .connect(governance)
            .whitelistCurrency(currency.address, true)
        );
    
        console.log('\n\t-- bankTreasuryContract setExchangePrice, 1 Ether = 1 SBT Value');
        await waitForTx( bankTreasuryContract.connect(governance).setExchangePrice(sbtContract.address, 1));
        
        //TODO ether 

        if (await manager.connect(governance).getGlobalModule() == ZERO_ADDRESS) {
            console.log('\n\t ==== error: manager not set ModuleGlobas ====');
        }
        
        if (await bankTreasuryContract.getGlobalModule() == ZERO_ADDRESS) {
            console.log('\n\t ==== error: bankTreasury not set ModuleGlobas ====');
        }
        
        if (await marketPlaceContract.getGlobalModule() == ZERO_ADDRESS) {
            console.log('\n\t ==== error: marketPlace not set ModuleGlobas ====');
        }


   });