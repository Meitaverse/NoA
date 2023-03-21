
import '@nomiclabs/hardhat-ethers';
import { hexlify, keccak256, parseEther, RLP } from 'ethers/lib/utils';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { task } from 'hardhat/config';
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
    PublishModule__factory,
    FeeCollectModule__factory,
    TimeLock__factory,
    InteractionLogic__factory,
    PublishLogic__factory,
    ModuleGlobals__factory,
    TransparentUpgradeableProxy__factory,
    ERC3525ReceiverMock__factory,
    BankTreasury__factory,
    DerivativeNFT__factory,
    Manager__factory,
    DerivativeMetadataDescriptor__factory,
    Template__factory,
    MarketPlace__factory,
    SBTMetadataDescriptor__factory,
    Currency__factory,
    FETH__factory,
    RoyaltyRegistry__factory,
    VoucherMarket__factory,
    MarketPlace,
} from '../typechain';
import { deployContract, deployWithVerify, waitForTx, ProtocolState, Error, ZERO_ADDRESS} from './helpers/utils';
import { ManagerLibraryAddresses } from '../typechain/factories/contracts/Manager__factory';

import { DataTypes } from '../typechain/contracts/modules/template/Template';
import { BigNumber } from 'ethers';
  

  const MARKET_MAX_DURATION = 86400000; //1000 days in seconds
  const TREASURY_FEE_BPS = 500;
  const RECEIVER_MAGIC_VALUE = '0x009ce20b';
  const FIRST_PROFILE_ID = 1; 
  const INITIAL_SUPPLY:BigNumber = BigNumber.from(100000000);  //SBT ininital supply, 100000000 * 1e18
  const VOUCHER_AMOUNT_LIMIT = parseEther("0.001");  
  const SBT_NAME = 'Bitsoul Protocol';
  const SBT_SYMBOL = 'SOUL';
  const SBT_DECIMALS = 18;
  const MARKET_DURATION = 86400; // default: 24h in seconds
  const LOCKUP_DURATION = 86400; //24h in seconds
  const NUM_CONFIRMATIONS_REQUIRED = 3;
  const PublishRoyaltySBT = 100;
  
  let managerLibs: ManagerLibraryAddresses;

  export let runtimeHRE: HardhatRuntimeEnvironment;
  
  // yarn testnet-full-deploy-verify

  task('testnet-full-deploy-verify', 'deploys the entire Bitsoul Protocol').setAction(async ({}, hre) => {
        // Note that the use of these signers is a placeholder and is not meant to be used in
        // production.
        runtimeHRE = hre;
        const ethers = hre.ethers;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        const governance = accounts[1];  
        const user = accounts[2];
        const userTwo = accounts[3];
        const userThree = accounts[4];
        const admin = accounts[5];

        const proxyAdminAddress = deployer.address;

        // Nonce management in case of deployment issues
        // let deployerNonce = await ethers.provider.getTransactionCount(deployer.address);
        let deployerNonce = await ethers.provider.getTransactionCount(admin.address);

        //Template
        let canvas: DataTypes.CanvasDataStruct = {width:800, height:600};
        let watermark: DataTypes.CanvasDataStruct = {width:200, height:300};
        let position: DataTypes.PositionStruct = {x:400, y: 0};

        console.log('\t-- deployer: ', deployer.address);
        
        let deployerBalance  = await hre.ethers.provider.getBalance(deployer.address);
        if (deployerBalance.eq(0)) {
           console.log('\t\t Failed!!! Balance of deployer is 0');
           return
        } else {
          console.log('\t-- Balance of deployer:', deployerBalance);
        }

        console.log('\t-- governance: ', governance.address);
        let governanceBalance  = await hre.ethers.provider.getBalance(governance.address)
        if (governanceBalance.eq(0)) {
           console.log('\t\t Failed!!! Balance of governance is 0');
           return
        }else {
          console.log('\t-- Balance of governance:', governanceBalance);
        }

        console.log('\t-- user: ', user.address);
        console.log('\t-- userTwo: ', userTwo.address);
        console.log('\t-- userThree: ', userThree.address);

        console.log('\n\t-- Deploying template  --');
        const template = await deployWithVerify(
            new Template__factory(deployer).deploy(
                1,
                "WaterMark",
                "Descript for this template",
                "Image",
                canvas,
                watermark,
                position,
              { nonce: deployerNonce++ }
            ),
            [
                1,
                "WaterMark",
                "Descript for this template",
                "Image",
                canvas,
                watermark,
                position
            ],
            'contracts/modules/Template.sol:Template'
        );
        console.log('\t-- template: ', template.address);
        await exportAddress(hre, template, 'Template');

        console.log('\n\t-- Deploying timeLock  --');
        const timeLock = await deployWithVerify(
            new TimeLock__factory(deployer).deploy(
                MIN_DELAY, 
                [], 
                [], 
                deployer.address,
                { nonce: deployerNonce++ }
            ),
            [
                MIN_DELAY, 
                [], 
                [], 
                deployer.address,
            ],
            'contracts/TimeLock.sol:TimeLock'
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
        

        const managerImpl = await deployWithVerify(
            new Manager__factory(managerLibs, deployer).deploy(
                
                { nonce: deployerNonce++,}
            ),
            [
                derivativeNFTImplAddress, 
                receiverMock.address,
            ],
            'contracts/Manager.sol:Manager'
        );
        console.log('\t-- managerImpl address: ', managerImpl.address);

        await exportAddress(hre, managerImpl, 'ManagerImpl');

        console.log('\n\t-- Deploying derivativeNFT Implementations --');
        await deployContract(
          new DerivativeNFT__factory(deployer).deploy(
            managerProxyAddress, 
            { nonce: deployerNonce++ }
          )
        );

        console.log('\n\t-- Deploying Manager --');

        let data = managerImpl.interface.encodeFunctionData('initialize', [
            derivativeNFTImplAddress, 
            receiverMock.address,
            governance.address
          ]);

        let proxy = await deployContract(
            new TransparentUpgradeableProxy__factory(deployer).deploy(
                managerImpl.address,
                admin.address,
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

        const sbtImpl = await hre.ethers.getContractFactory('NFTDerivativeProtocolTokenV1');
        deployerNonce++;

        let sbtContract = await hre.upgrades.deployProxy(
        sbtImpl, 
        [
            SBT_NAME, 
            SBT_SYMBOL, 
            SBT_DECIMALS,
            manager.address,
            governance.address,
            sbtMetadataDescriptor.address,
        ], 
        {
            initializer: "initialize"
        }
        )
        await sbtContract.deployed();

        deployerNonce++;
        deployerNonce++;

        console.log('\t-- sbtContract: ', sbtContract.address);
        await exportAddress(hre, sbtContract, 'SBT');
        await exportSubgraphNetworksJson(hre, sbtContract, 'SBT');

        //governor
        const governorImpl = await hre.ethers.getContractFactory('GovernorContract');
        deployerNonce++;
    
        let governorContract = await hre.upgrades.deployProxy(
            governorImpl, 
            [
            governance.address,
            sbtContract.address,
            timeLock.address,
            QUORUM_PERCENTAGE, 
            VOTING_PERIOD,
            VOTING_DELAY,
            ], 
            {
                initializer: "initialize"
            }
        )
        await governorContract.deployed();
        deployerNonce++;

        console.log("\t-- governorContract address: ", governorContract.address);
        await exportAddress(hre, governorContract, 'GovernorContract');
        await exportSubgraphNetworksJson(hre, governorContract, 'GovernorContract');


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

        //voucher
        console.log('\n\t-- Deploying voucher --');
        const voucherImpl = await hre.ethers.getContractFactory('Voucher');
        deployerNonce++;
 
        let voucherContract = await hre.upgrades.deployProxy(
          voucherImpl, 
          [
            sbtContract.address, 
            bankTreasuryContract.address, 
            "Voucher Bitsoul",
            "Voucher",
          ], 
          {
            initializer: "initialize"
          }
        )
        await voucherContract.deployed();
        deployerNonce++;      

        console.log('\t-- voucherContract: ', voucherContract.address);
        await exportAddress(hre, voucherContract, 'Voucher');
        await exportSubgraphNetworksJson(hre, voucherContract, 'Voucher');

        console.log('\n\t-- Deploying market place --');
       /*
        const marketPlaceImpl = await deployWithVerify(
            new MarketPlace__factory(deployer).deploy
                (

                    { nonce: deployerNonce++ }
                ),
                [
                    bankTreasuryContract.address,
                    MARKET_DURATION,
                ],
                'contracts/MarketPlace.sol:MarketPlace'
        );

        let initializeDataMarket = marketPlaceImpl.interface.encodeFunctionData("initialize", [
          governance.address,
          MARKET_DURATION,
          bankTreasuryContract.address,
        ]);
      
        const marketPlaceProxy = await new ERC1967Proxy__factory(deployer).deploy(
            marketPlaceImpl.address,
            initializeDataMarket,
            { nonce: deployerNonce++ }
        );
        const marketPlaceContract = new MarketPlace__factory(deployer).attach(marketPlaceProxy.address);
        */
        const marketPlaceImpl = await hre.ethers.getContractFactory('MarketPlace');
        deployerNonce++;
        
        const marketPlaceContract = await hre.upgrades.deployProxy(marketPlaceImpl, [
          governance.address,,
          MARKET_MAX_DURATION,
          bankTreasuryContract.address,
        ], {
          initializer: "initialize"
        }) as MarketPlace;
      
        await marketPlaceContract.deployed()
        deployerNonce++;
      
        console.log('\t-- marketPlaceContract: ', marketPlaceContract.address);
        await exportAddress(hre, marketPlaceContract, 'MarketPlace');
        await exportSubgraphNetworksJson(hre, marketPlaceContract, 'MarketPlace');

        console.log('\n\t-- Deploying moduleGlobals --');
        const moduleGlobals = await deployWithVerify(
            new ModuleGlobals__factory(deployer).deploy
            (
                manager.address,
                sbtContract.address,
                governance.address,
                bankTreasuryContract.address,
                marketPlaceContract.address,
                voucherContract.address,
                TREASURY_FEE_BPS,
                PublishRoyaltySBT,
                { nonce: deployerNonce++ }
            ),
            [
                manager.address,
                sbtContract.address,
                governance.address,
                bankTreasuryContract.address,
                marketPlaceContract.address,
                voucherContract.address,
                TREASURY_FEE_BPS,
                PublishRoyaltySBT,
            ],
            'contracts/modules/ModuleGlobals.sol:ModuleGlobals'
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
            LOCKUP_DURATION,
            { nonce: deployerNonce++ }
          )
        
         const royaltyRegistry = await new RoyaltyRegistry__factory(deployer).deploy({ nonce: deployerNonce++ });
        
         const voucherMarketImpl = await new VoucherMarket__factory(deployer).deploy(
            bankTreasuryContract.address,
            fethImpl.address,
            royaltyRegistry.address,
            { nonce: deployerNonce++ }
          );
        
          let voucherMarketData= voucherMarketImpl.interface.encodeFunctionData("initialize", [
            await governance.getAddress(),
          ]);
        
          const voucherMarketProxy = await new ERC1967Proxy__factory(deployer).deploy(
            voucherMarketImpl.address,
            voucherMarketData,
            { nonce: deployerNonce++ }
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
            fethData,
            { nonce: deployerNonce++ }
          );

          const feth = new FETH__factory(deployer).attach(fethProxy.address);
          console.log("feth.address: ", feth.address);   
          await exportAddress(hre, feth, 'FETH');
          await exportSubgraphNetworksJson(hre, feth, 'FETH');
          
        
        await waitForTx(
            manager.connect(governance).setGlobalModules(moduleGlobals.address)
        );

        await waitForTx(
            manager.connect(governance).setSBT(sbtContract.address)
        );
      
        await waitForTx(
            manager.connect(governance).setVoucher(voucherContract.address)
        );

        await waitForTx(
            manager.connect(governance).setTreasury(bankTreasuryContract.address)
        );
      
        await waitForTx(
            manager.connect(governance).setMarket(marketPlaceContract.address)
        );
      
  
        console.log('\n\t-- sbtContract set bankTreasuryContract address and INITIAL SUPPLY --');
        await waitForTx(sbtContract.connect(deployer).setBankTreasury(
            bankTreasuryContract.address, 
            INITIAL_SUPPLY
        ));
        let balance =  await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID); 
        console.log('\t-- INITIAL SUPPLY of the first soul bound token id:', balance);
        
        console.log('\n\t-- Whitelisting sbtContract Contract address --');
        // const transferValueRole = await sbtContract.TRANSFER_VALUE_ROLE();
        await waitForTx( sbtContract.connect(governance).grantTransferRole( manager.address));
        await waitForTx( sbtContract.connect(governance).grantTransferRole( publishModule.address));
        await waitForTx( sbtContract.connect(governance).grantTransferRole( feeCollectModule.address));
        await waitForTx( sbtContract.connect(governance).grantTransferRole( bankTreasuryContract.address));
        await waitForTx( sbtContract.connect(governance).grantTransferRole( voucherContract.address));
        await waitForTx( sbtContract.connect(governance).grantTransferRole( marketPlaceContract.address));
        
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
        // Admins can register extensions
        await waitForTx( voucherContract.connect(deployer).approveAdmin(governance.address) );

        console.log('\n\t-- bankTreasuryContract set moduleGlobals and  marketPlace--');
        await waitForTx( bankTreasuryContract.connect(governance).setGlobalModules(moduleGlobals.address));
        await waitForTx( bankTreasuryContract.connect(governance).setFoundationMarket(marketPlaceContract.address));
        
        console.log('\n\t-- marketPlaceContract set moduleGlobals address --');
        await waitForTx( marketPlaceContract.connect(governance).setGlobalModules(moduleGlobals.address));

        console.log('\n\t-- manager set Protocol state to unpaused --');
        await waitForTx( manager.connect(governance).setState(ProtocolState.Unpaused));

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
    
        console.log('\n\t-- bankTreasuryContract setExchangePrice, 1 Ether = 1000 SBT Value');
        await waitForTx( bankTreasuryContract.connect(governance).setExchangePrice(sbtContract.address, 1, 1000));
        
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