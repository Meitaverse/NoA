import '@nomiclabs/hardhat-ethers';
import { hexlify, keccak256, RLP } from 'ethers/lib/utils';
import fs from 'fs';
import { task } from 'hardhat/config';
// import { readFile, writeFile } from "fs/promises";
import { exportAddress } from "./config";

import {
    ERC1967Proxy__factory,
    Currency,
    Currency__factory,
    Events,
    Events__factory,
    PublishModule,
    PublishModule__factory,
    FeeCollectModule,
    FeeCollectModule__factory,
    Helper,
    Helper__factory,
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
    DerivativeNFTV1,
    DerivativeNFTV1__factory,
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
  } from '../typechain';
  import { deployContract, waitForTx , ProtocolState, Error} from './helpers/utils';
  import { ManagerLibraryAddresses } from '../typechain/factories/contracts/Manager__factory';
  
  import { DataTypes } from '../typechain/contracts/modules/template/Template';
  
  const TREASURY_FEE_BPS = 50;
  const  RECEIVER_MAGIC_VALUE = '0x009ce20b';
  const TreasuryFee = 50; 
  const FIRST_PROFILE_ID = 1; //金库
  const INITIAL_SUPPLY = 1000000;  //NDPT初始发行总量
  const VOUCHER_AMOUNT_LIMIT = 100;  //用户用NDP兑换Voucher的最低数量 
  
  
  const NDPT_NAME = 'NFT Derivative Protocol';
  const NDPT_SYMBOL = 'NDP';
  const NDPT_DECIMALS = 18;
  
  
  const NUM_CONFIRMATIONS_REQUIRED = 3;
  const PublishRoyaltyNDPT = 100;
  
  let managerLibs: ManagerLibraryAddresses;

   task('full-deploy', 'deploys the entire NFT Derivative Protocol').setAction(async ({}, hre) => {
        // Note that the use of these signers is a placeholder and is not meant to be used in
        // production.
        const ethers = hre.ethers;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        const governance = accounts[1];  //治理合约地址
        const user = accounts[2];
        const userTwo = accounts[3];
        const userThree = accounts[4];

        const proxyAdminAddress = deployer.address;
        const profileCreatorAddress = deployer.address;

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

        console.log('\n\t-- Deploying metadataDescriptor  --');
        const metadataDescriptor = await deployContract(
            new DerivativeMetadataDescriptor__factory(deployer).deploy(
              { nonce: deployerNonce++ }
            )
        );
        console.log('\t-- metadataDescriptor: ', metadataDescriptor.address);

        console.log('\n\t-- Deploying receiver  --');
        const receiverMock = await deployContract(
            new ERC3525ReceiverMock__factory(deployer).deploy(
                RECEIVER_MAGIC_VALUE, 
                Error.None,
              { nonce: deployerNonce++ }
            )
        );
        console.log('\t-- receiverMock: ', receiverMock.address);
    
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

        console.log('\n\t-- Deploying derivativeNFT Implementations --');
        await deployContract(
          new DerivativeNFTV1__factory(deployer).deploy(managerProxyAddress, { nonce: deployerNonce++ })
        );

        console.log('\n\t-- Deploying Manager address --');

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
       
        console.log('\t-- manager proxy: ', proxy.address);

        // Connect the manager proxy to the Manager factory and the governance for ease of use.
        const manager = Manager__factory.connect(proxy.address, governance);

        console.log('\t-- manager: ', manager.address);
    
        console.log('\n\t-- Deploying voucher --');
        const voucherImpl = await deployContract(
            new Voucher__factory(deployer).deploy({ nonce: deployerNonce++ })
        );

        let initializeVoucherData = voucherImpl.interface.encodeFunctionData("initialize", [
            "https://api.bitsoul.xyz/v1/metadata/",
        ]);
        const voucherProxy = await new ERC1967Proxy__factory(deployer).deploy(
            voucherImpl.address,
            initializeVoucherData,
            { nonce: deployerNonce++ }
        );
        const voucherContract = new Voucher__factory(deployer).attach(voucherProxy.address);
        console.log('\t-- voucherContract: ', voucherContract.address);

        console.log('\n\t-- Deploying NDP --');
        const ndptImpl = await deployContract(
            new NFTDerivativeProtocolTokenV1__factory(deployer).deploy({ nonce: deployerNonce++ })
        );

        let initializeNDPTData = ndptImpl.interface.encodeFunctionData("initialize", [
            NDPT_NAME, 
            NDPT_SYMBOL, 
            NDPT_DECIMALS,
            manager.address,
        ]);
        const ndptProxy = await new ERC1967Proxy__factory(deployer).deploy(
            ndptImpl.address,
            initializeNDPTData,
            { nonce: deployerNonce++ }
        );
        const ndptContract = new NFTDerivativeProtocolTokenV1__factory(deployer).attach(ndptProxy.address);
        console.log('\t-- ndptContract: ', ndptContract.address);

        console.log('\n\t-- Deploying bank treasury --');
        const soulBoundTokenIdOfBankTreaury = 1;
        const bankTreasuryImpl = await deployContract(
            new BankTreasury__factory(deployer).deploy({ nonce: deployerNonce++ })
        );

        let initializeData = bankTreasuryImpl.interface.encodeFunctionData("initialize", [
          governance.address,
          soulBoundTokenIdOfBankTreaury,
          [user.address, userTwo.address, userThree.address],
          NUM_CONFIRMATIONS_REQUIRED  //All full signed 
        ]);
      
        const bankTreasuryProxy = await new ERC1967Proxy__factory(deployer).deploy(
          bankTreasuryImpl.address,
          initializeData,
          { nonce: deployerNonce++ }
        );
        const bankTreasuryContract = new BankTreasury__factory(deployer).attach(bankTreasuryProxy.address);
        console.log('\t-- bankTreasuryContract: ', bankTreasuryContract.address);

        console.log('\n\t-- Deploying moduleGlobals --');
        const moduleGlobals = await deployContract(
            new ModuleGlobals__factory(deployer).deploy(
                manager.address,
                ndptContract.address,
                governance.address,
                bankTreasuryContract.address,
                voucherContract.address,
                TREASURY_FEE_BPS,
                PublishRoyaltyNDPT,
                { nonce: deployerNonce++ })
        );
        console.log('\t-- moduleGlobals: ', moduleGlobals.address);
        
        // Modules
        console.log('\n\t-- Deploying feeCollectModule --');
        const feeCollectModule = await deployContract(
            new FeeCollectModule__factory(deployer).deploy(
                manager.address, 
                moduleGlobals.address,
                { nonce: deployerNonce++ })
        );
        console.log('\t-- feeCollectModule: ', feeCollectModule.address);

        console.log('\n\t-- Deploying publishModule --');
        const publishModule = await deployContract(
            new PublishModule__factory(deployer).deploy(
                manager.address, 
                moduleGlobals.address,
                ndptContract.address,
                { nonce: deployerNonce++ })
        );
        console.log('\t-- publishModule: ', publishModule.address);


        await waitForTx(
            manager.connect(governance).setGlobalModule(moduleGlobals.address)
        );
  
        console.log('\n\t-- ndptContract set bankTreasuryContract address and INITIAL SUPPLY --');
        await waitForTx(ndptContract.connect(deployer).setBankTreasury(
            bankTreasuryContract.address, 
            INITIAL_SUPPLY
        ));
        let balance =  await ndptContract.balanceOfNDPT(FIRST_PROFILE_ID)
        console.log('\t-- INITIAL SUPPLY of the first soul bound token id:', balance.toNumber());
        
        console.log('\n\t-- Whitelisting ndptContract Contract address --');
        await waitForTx( ndptContract.connect(deployer).whitelistContract(publishModule.address, true));
        await waitForTx( ndptContract.connect(deployer).whitelistContract(feeCollectModule.address, true));
        await waitForTx( ndptContract.connect(deployer).whitelistContract(bankTreasuryContract.address, true));
        await waitForTx( ndptContract.connect(deployer).whitelistContract(voucherContract.address, true));
            
        console.log('\n\t-- voucherContract set moduleGlobals address --');
        await waitForTx( voucherContract.connect(deployer).setGlobalModule(moduleGlobals.address));
        await waitForTx( voucherContract.connect(deployer).setUserAmountLimit(moduleGlobals.address));
      
        console.log('\n\t-- bankTreasuryContract set moduleGlobals address --');
        await waitForTx( bankTreasuryContract.connect(governance).setGlobalModule(moduleGlobals.address));

        console.log('\n\t-- manager set Protocol state to unpaused --');
        await waitForTx( manager.connect(governance).setState(ProtocolState.Unpaused));

        console.log('\n\t-- moduleGlobals set whitelistProfileCreator --');
        await waitForTx( moduleGlobals.connect(governance).whitelistProfileCreator(user.address, true));
        await waitForTx( moduleGlobals.connect(governance).whitelistProfileCreator(userTwo.address, true));
        await waitForTx( moduleGlobals.connect(governance).whitelistProfileCreator(userThree.address, true));

   });