import { AbiCoder } from '@ethersproject/abi';
import '@nomiclabs/hardhat-ethers';
import { expect, use } from 'chai';
import { solidity } from 'ethereum-waffle';
import { BigNumber, BytesLike, Contract, Signer, Wallet } from 'ethers';
import { ethers } from "hardhat";
import {
  MIN_DELAY,
  QUORUM_PERCENTAGE,
  VOTING_PERIOD,
  VOTING_DELAY,
} from "../helper-hardhat-config"

import {
  ERC1967Proxy__factory,
  Box,
  Box__factory,
  TimeLock,
  TimeLock__factory,
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
  MultirecipientFeeCollectModule,
  MultirecipientFeeCollectModule__factory,
  MarketLogic,
  MarketLogic__factory,
  FETH,
  FETH__factory,
  MarketPlace,
  MarketPlace__factory,
  VoucherMarket,
  VoucherMarket__factory,
  SBTMetadataDescriptor,
  SBTMetadataDescriptor__factory,
  Currency,
  Currency__factory,

  RoyaltyRegistry,
  RoyaltyRegistry__factory,
} from '../typechain';

import { ManagerLibraryAddresses } from '../typechain/factories/contracts/Manager__factory';

import { FAKE_PRIVATEKEY, ZERO_ADDRESS } from './helpers/constants';
import {
  computeContractAddress,
  ProtocolState,
  Error,
  revertToSnapshot,
  takeSnapshot,
} from './helpers/utils';

// import {
//   CanvasDataStruct, PositionStruct
// } from '../typechain/Template';

import { DataTypes } from '../typechain/contracts/modules/template/Template';
import { MarketPlaceLibraryAddresses } from '../typechain/factories/contracts/MarketPlace__factory';

use(solidity);

export const NUM_CONFIRMATIONS_REQUIRED = 3;
export const BPS_MAX = 10000;
export const TREASURY_FEE_BPS = 500;
export const PublishRoyaltySBT = 100;
export const GENESIS_FEE_BPS = 100; //genesis Fee
export const MAX_PROFILE_IMAGE_URI_LENGTH = 6000;
export const SBT_NAME = 'NFT Derivative Protocol Token';
export const SBT_SYMBOL = 'SBT';
export const SBT_DECIMALS = 18;
export const MOCK_PROFILE_HANDLE = 'plant1ghost.eth';
export const LENS_PERIPHERY_NAME = 'LensPeriphery';
export const FIRST_PROFILE_ID = 1; 
export const SECOND_PROFILE_ID = 2;
export const THIRD_PROFILE_ID = 3;
export const FOUR_PROFILE_ID = 4;
export const FIRST_HUB_ID = 1;
export const FIRST_PROJECT_ID = 1;
export const FIRST_PUBLISH_ID = 1;
export const FIRST_DNFT_TOKEN_ID = 1;
export const SECOND_DNFT_TOKEN_ID = 2;
export const MOCK_URI = 'https://ipfs.io/ipfs/QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR';
export const OTHER_MOCK_URI = 'https://ipfs.io/ipfs/QmSfyMcnh1wnJHrAWCBjZHapTS859oNSsuDFiAPPdAHgHP';
export const MOCK_PROFILE_URI =
  'https://ipfs.io/ipfs/Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu';
export const MOCK_FOLLOW_NFT_URI =
  'https://ipfs.fleek.co/ipfs/ghostplantghostplantghostplantghostplantghostplantghostplan';

export const  RECEIVER_MAGIC_VALUE = '0x009ce20b';
export const MARKET_MAX_DURATION = 86400000; //1000 days in seconds
export const LOCKUP_DURATION = 86400; //24h in seconds

export const INITIAL_SUPPLY:BigNumber = BigNumber.from(1000000000);  //SBT初始发行总量, 1000000000 * 1e18
export const VOUCHER_AMOUNT_LIMIT = 100;  //用户用SBT兑换Voucher的最低数量 

export const DEFAULT_COLLECT_PRICE = 10;
export const DEFAULT_TEMPLATE_NUMBER = 1;
export const NickName = 'BitsoulUser';
export const NickName2 = 'BitsoulUser2';
export const NickName3 = 'BitsoulUser3';

export let accounts: Signer[];
export let deployer: Signer;
export let user: Signer;
export let userTwo: Signer;
export let userThree: Signer;
export let governance: Signer;
export let deployerAddress: string;
export let userAddress: string;
export let userTwoAddress: string;
export let userThreeAddress: string;
export let governanceAddress: string;
export let governorContract: GovernorContract;
export let testWallet: Wallet;
export let managerImpl: Manager;
export let manager: Manager;
export let currency: Currency;
export let box: Box;
export let timeLock: TimeLock;
export let abiCoder: AbiCoder;
export let mockModuleData: BytesLike;
export let managerLibs: ManagerLibraryAddresses;
export let eventsLib: Events;
export let moduleGlobals: ModuleGlobals;
export let helper: Helper;
export let receiverMock: ERC3525ReceiverMock
export let bankTreasuryImpl: BankTreasury
export let bankTreasuryContract: BankTreasury
export let marketLibs:MarketPlaceLibraryAddresses
export let marketPlaceImpl: MarketPlace
export let marketPlaceContract: MarketPlace
export let voucherMarketImpl: VoucherMarket
export let voucherMarketContract: VoucherMarket
export let sbtImpl: NFTDerivativeProtocolTokenV1;
export let sbtContract: NFTDerivativeProtocolTokenV1;
export let derivativeNFTImpl: DerivativeNFT;
export let metadataDescriptor: DerivativeMetadataDescriptor;
export let sbtMetadataDescriptor: SBTMetadataDescriptor;

export let fethImpl: FETH
export let feth: FETH;
export let royaltyRegistry: RoyaltyRegistry;

export let voucherImpl: Voucher;
export let voucherContract: Voucher

/* Modules */
//Publish
export let publishModule: PublishModule;
// Collect
export let feeCollectModule: FeeCollectModule;
// MultiRoyalties
export let multirecipientFeeCollectModule: MultirecipientFeeCollectModule;

//Template
export let template: Template;

export function makeSuiteCleanRoom(name: string, tests: () => void) {
  describe(name, () => {
    beforeEach(async function () {
      await takeSnapshot();
    });
    tests();
    afterEach(async function () {
      await revertToSnapshot();
    });
  });
}

before(async function () {
  abiCoder = ethers.utils.defaultAbiCoder;
  testWallet = new ethers.Wallet(FAKE_PRIVATEKEY).connect(ethers.provider);
  accounts = await ethers.getSigners();
  deployer = accounts[0];
  user = accounts[1];
  userTwo = accounts[2];
  governance = accounts[3];
  userThree = accounts[4];

  deployerAddress = await deployer.getAddress();
  userAddress = await user.getAddress();
  userTwoAddress = await userTwo.getAddress();
  userThreeAddress = await userThree.getAddress();
  governanceAddress = await governance.getAddress();
  console.log("deployer address: ", deployerAddress);
  console.log("user address: ", userAddress);
  console.log("userTwo address: ", userTwoAddress);
  console.log("userThree address: ", userThreeAddress);
  console.log("governance address: ", governanceAddress);

  mockModuleData = abiCoder.encode(['uint256'], [1]);



  // Deployment
  helper = await new Helper__factory(deployer).deploy();

  //Template
 let canvas: DataTypes.CanvasDataStruct = {width:800, height:600};
 let watermark: DataTypes.CanvasDataStruct = {width:200, height:300};
 let position: DataTypes.PositionStruct = {x:400, y: 0};

  template = await new Template__factory(deployer).deploy(
    1,
    "WaterMark",
    "descript for this template",
    "image",
    canvas,
    watermark,
    position,
  );

  // Currency
  currency = await new Currency__factory(deployer).deploy();
  
  box = await new Box__factory(deployer).deploy();
  console.log("box address: ", box.address);

  timeLock = await new TimeLock__factory(deployer).deploy(MIN_DELAY, [], [], deployerAddress);
  console.log("timeLock address: ", timeLock.address);


  receiverMock = await new ERC3525ReceiverMock__factory(deployer).deploy(RECEIVER_MAGIC_VALUE, Error.None);

  const interactionLogic = await new InteractionLogic__factory(deployer).deploy();
  const publishLogic = await new PublishLogic__factory(deployer).deploy();
  managerLibs = {
    'contracts/libraries/InteractionLogic.sol:InteractionLogic': interactionLogic.address,
    'contracts/libraries/PublishLogic.sol:PublishLogic': publishLogic.address,
  };
  

  // Here, we pre-compute the nonces and addresses used to deploy the contracts.
  const nonce = await deployer.getTransactionCount();
  // nonce + 0 is impl
  // nonce + 1 is impl
  // nonce + 2 is manager proxy

  const managerProxyAddress = computeContractAddress(deployerAddress, nonce + 2); //'0x' + keccak256(RLP.encode([deployerAddress, hubProxyNonce])).substr(26);
  console.log("managerProxyAddress: ", managerProxyAddress);

  derivativeNFTImpl = await new DerivativeNFT__factory(deployer).deploy(
    managerProxyAddress
  );

  managerImpl = await new Manager__factory(managerLibs, deployer).deploy(
    derivativeNFTImpl.address,
    receiverMock.address,
  );

  let data = managerImpl.interface.encodeFunctionData('initialize', [
    governanceAddress
  ]);
  
  let proxy = await new TransparentUpgradeableProxy__factory(deployer).deploy(
    managerImpl.address,
    deployerAddress,
    data
  );

  // Connect the manager proxy to the Manager factory, must connect by user, not deployer
  manager = Manager__factory.connect(proxy.address, user);
  
  console.log("manager.address: ", manager.address);

  //SBT descriptor
  sbtMetadataDescriptor = await new SBTMetadataDescriptor__factory(deployer).deploy(
    manager.address
  );

  sbtImpl = await new NFTDerivativeProtocolTokenV1__factory(deployer).deploy();
  let initializeSBTData = sbtImpl.interface.encodeFunctionData("initialize", [
      SBT_NAME, 
      SBT_SYMBOL, 
      SBT_DECIMALS,
      manager.address,
      sbtMetadataDescriptor.address,
  ]);
  const sbtProxy = await new ERC1967Proxy__factory(deployer).deploy(
    sbtImpl.address,
    initializeSBTData
  );
  sbtContract = new NFTDerivativeProtocolTokenV1__factory(deployer).attach(sbtProxy.address);
  console.log("sbtContract.address: ", sbtContract.address);


  voucherImpl = await new Voucher__factory(deployer).deploy( sbtContract.address );
  let initializeVoucherData = voucherImpl.interface.encodeFunctionData("initialize", [
     "Voucher Bitsoul",
     "Voucher"
  ]);
  const voucherProxy = await new ERC1967Proxy__factory(deployer).deploy(
    voucherImpl.address,
    initializeVoucherData
  );
  voucherContract = new Voucher__factory(deployer).attach(voucherProxy.address);
  console.log("voucherContract.address: ", voucherContract.address);


  const governorImpl = await new GovernorContract__factory(deployer).deploy();
  let initializeDataGovrnor = governorImpl.interface.encodeFunctionData("initialize", [
    sbtContract.address,
    timeLock.address,
    QUORUM_PERCENTAGE, 
    VOTING_PERIOD,
    VOTING_DELAY,
  ]);

  const gonvernorProxy = await new ERC1967Proxy__factory(deployer).deploy(
    governorImpl.address,
    initializeDataGovrnor
    );
  governorContract = new GovernorContract__factory(deployer).attach(gonvernorProxy.address);
  console.log("governorContract address: ", governorContract.address);
  
  const soulBoundTokenIdOfBankTreaury = FIRST_PROFILE_ID;
  bankTreasuryImpl = await new BankTreasury__factory(deployer).deploy(
  );
  let initializeData = bankTreasuryImpl.interface.encodeFunctionData("initialize", [
    deployerAddress,
    governanceAddress,
    soulBoundTokenIdOfBankTreaury,
    [userAddress, userTwoAddress, userThreeAddress],
    NUM_CONFIRMATIONS_REQUIRED,  //All full signed 
    LOCKUP_DURATION
  ]);

  const bankTreasuryProxy = await new ERC1967Proxy__factory(deployer).deploy(
    bankTreasuryImpl.address,
    initializeData
  );
  bankTreasuryContract = new BankTreasury__factory(deployer).attach(bankTreasuryProxy.address);
  console.log("bankTreasuryContract.address: ", bankTreasuryContract.address);
  
  //market place

  const marketLogic = await new MarketLogic__factory(deployer).deploy();
  marketLibs = {
    'contracts/libraries/MarketLogic.sol:MarketLogic': marketLogic.address,
  };
  marketPlaceImpl = await new MarketPlace__factory(marketLibs, deployer).deploy(
    bankTreasuryContract.address,
    MARKET_MAX_DURATION
  );
  let marketPlaceData = marketPlaceImpl.interface.encodeFunctionData("initialize", [
    governanceAddress,
  ]);

  const marketPlaceProxy = await new ERC1967Proxy__factory(deployer).deploy(
    marketPlaceImpl.address,
    marketPlaceData
  );
  marketPlaceContract = new MarketPlace__factory(marketLibs, deployer).attach(marketPlaceProxy.address);
  console.log("marketPlaceContract.address: ", marketPlaceContract.address);
  

  moduleGlobals = await new ModuleGlobals__factory(deployer).deploy(
    manager.address,
    sbtContract.address,
    governanceAddress,
    bankTreasuryContract.address,
    marketPlaceContract.address,
    voucherContract.address,
    TREASURY_FEE_BPS,
    PublishRoyaltySBT
  );
  console.log("moduleGlobals.address: ", moduleGlobals.address);
  
  // Modules
  feeCollectModule = await new FeeCollectModule__factory(deployer).deploy(
    manager.address, 
    marketPlaceContract.address,
    moduleGlobals.address
  );

  publishModule = await new PublishModule__factory(deployer).deploy(
    manager.address, 
    marketPlaceContract.address,
    moduleGlobals.address
  );

  multirecipientFeeCollectModule = await new MultirecipientFeeCollectModule__factory(deployer).deploy(
    manager.address, 
    marketPlaceContract.address,
    moduleGlobals.address
  );

  //DerivativeNFT descriptor
  metadataDescriptor = await new DerivativeMetadataDescriptor__factory(deployer).deploy(
    moduleGlobals.address
  );

  fethImpl = await new FETH__factory(deployer).deploy(
    LOCKUP_DURATION
  )

  royaltyRegistry = await new RoyaltyRegistry__factory(deployer).deploy();

  voucherMarketImpl = await new VoucherMarket__factory(deployer).deploy(
    bankTreasuryContract.address,
    fethImpl.address,
    royaltyRegistry.address
  );

  let voucherMarketData= voucherMarketImpl.interface.encodeFunctionData("initialize", [
    governanceAddress,
  ]);

  const voucherMarketProxy = await new ERC1967Proxy__factory(deployer).deploy(
    voucherMarketImpl.address,
    voucherMarketData
  );
  voucherMarketContract = new VoucherMarket__factory(deployer).attach(voucherMarketProxy.address);
  console.log("voucherMarketContract.address: ", voucherMarketContract.address);
  
  //feth init

  let fethData= fethImpl.interface.encodeFunctionData("initialize", [
    voucherMarketContract.address,
  ]);

  const fethProxy = await new ERC1967Proxy__factory(deployer).deploy(
    fethImpl.address,
    fethData
  );
  feth = new FETH__factory(deployer).attach(fethProxy.address);
  console.log("feth.address: ", feth.address);


  expect(bankTreasuryContract).to.not.be.undefined;
  expect(marketPlaceContract).to.not.be.undefined;
  expect(sbtContract).to.not.be.undefined;
  expect(receiverMock).to.not.be.undefined;
  expect(derivativeNFTImpl).to.not.be.undefined;
  expect(manager).to.not.be.undefined;
  expect(timeLock).to.not.be.undefined;
  expect(governorContract).to.not.be.undefined;
  expect(metadataDescriptor).to.not.be.undefined;
  expect(feeCollectModule).to.not.be.undefined;
  expect(publishModule).to.not.be.undefined;
  expect(moduleGlobals).to.not.be.undefined;
  expect(feth).to.not.be.undefined;
  expect(royaltyRegistry).to.not.be.undefined;
  expect(voucherMarketContract).to.not.be.undefined;


  // Add to module whitelist
  await expect(
    moduleGlobals.connect(governance).whitelistPublishModule(publishModule.address, true)
  ).to.not.be.reverted;

  await expect(
    moduleGlobals.connect(governance).whitelistCollectModule(feeCollectModule.address, true)
  ).to.not.be.reverted;    

  await expect(
    moduleGlobals.connect(governance).whitelistTemplate(template.address, true)
  ).to.not.be.reverted;    

  // Whitelist the currency
  console.log('\n\t-- Whitelisting SBT and Currency ERC20 contract in Module Globals --');
  await expect(
      moduleGlobals
      .connect(governance)
      .whitelistCurrency(sbtContract.address, true)
  ).to.not.be.reverted;    

  await expect(
      moduleGlobals
      .connect(governance)
      .whitelistCurrency(currency.address, true)
  ).to.not.be.reverted;    

  expect((await moduleGlobals.getSBT()).toUpperCase()).to.eq(sbtContract.address.toUpperCase());


  //manager set moduleGlobals
  await manager.connect(governance).setGlobalModules(moduleGlobals.address);
  console.log('manager setGlobalModules ok ');

  await bankTreasuryContract.connect(governance).setGlobalModules(moduleGlobals.address);
  console.log('bankTreasuryContract setGlobalModules ok ');

  await bankTreasuryContract.connect(governance).setFoundationMarket(marketPlaceContract.address);
  console.log('bankTreasuryContract setFoundationMarket ok ');
  
  await marketPlaceContract.connect(governance).setGlobalModules(moduleGlobals.address);
  console.log('marketPlaceContract setGlobalModules ok ');
  
  await expect(sbtContract.connect(deployer).setBankTreasury(
    bankTreasuryContract.address, 
    INITIAL_SUPPLY
  )).to.not.be.reverted;
  
  const transferValueRole = await sbtContract.TRANSFER_VALUE_ROLE();

  await expect(
    sbtContract.connect(deployer).grantRole(transferValueRole, manager.address)
  ).to.not.be.reverted;
  
  await expect(
    sbtContract.connect(deployer).grantRole(transferValueRole, publishModule.address)
  ).to.not.be.reverted;

  await expect(
    sbtContract.connect(deployer).grantRole(transferValueRole, feeCollectModule.address)
  ).to.not.be.reverted;
  
  await expect(
    sbtContract.connect(deployer).grantRole(transferValueRole, multirecipientFeeCollectModule.address)
  ).to.not.be.reverted;
  await expect(
    sbtContract.connect(deployer).grantRole(transferValueRole, bankTreasuryContract.address)
  ).to.not.be.reverted;
  await expect(
    sbtContract.connect(deployer).grantRole(transferValueRole, voucherContract.address)
  ).to.not.be.reverted;
  await expect(
    sbtContract.connect(deployer).grantRole(transferValueRole, marketPlaceContract.address)
  ).to.not.be.reverted;

  await expect(
    bankTreasuryContract.connect(deployer).grantFeeModule(feeCollectModule.address)
  ).to.not.be.reverted;
  
  await expect(
    bankTreasuryContract.connect(deployer).grantFeeModule(marketPlaceContract.address)
  ).to.not.be.reverted;

  await expect(
    bankTreasuryContract.connect(governance).setExchangePrice(sbtContract.address, 1)
  ).to.not.be.reverted;
  console.log('bankTreasuryContract setExchangePrice ok, 1 Ether = 1 SBT Value');


  await expect(
    marketPlaceContract.connect(governance).grantOperator(governanceAddress)
  ).to.not.be.reverted;


  await expect(voucherContract.connect(deployer).setUserAmountLimit(VOUCHER_AMOUNT_LIMIT)).to.not.be.reverted;

  await expect(manager.connect(governance).setState(ProtocolState.Unpaused)).to.not.be.reverted;
  
  await expect(
    moduleGlobals.connect(governance).whitelistProfileCreator(userAddress, true)
  ).to.not.be.reverted;
  await expect(
    moduleGlobals.connect(governance).whitelistProfileCreator(userTwoAddress, true)
  ).to.not.be.reverted;
  await expect(
    moduleGlobals.connect(governance).whitelistProfileCreator(userThreeAddress, true)
  ).to.not.be.reverted;
  await expect(
    moduleGlobals.connect(governance).whitelistProfileCreator(testWallet.address, true)
  ).to.not.be.reverted;

  await expect(
    moduleGlobals.connect(governance).whitelistHubCreator(SECOND_PROFILE_ID, true)
  ).to.not.be.reverted;


  expect((await manager.version()).toNumber()).to.eq(1);

  expect(await manager.getWalletBySoulBoundTokenId(FIRST_PROFILE_ID)).to.eq(bankTreasuryContract.address);

  expect((await derivativeNFTImpl.MANAGER()).toUpperCase()).to.eq(manager.address.toUpperCase());

  expect((await sbtContract.version()).toNumber()).to.eq(1);
  // expect((await sbtContract.getManager()).toUpperCase()).to.eq(manager.address.toUpperCase());
  console.log('sbtContract getManager ok ');
  
  expect((await bankTreasuryContract.getManager()).toUpperCase()).to.eq(manager.address.toUpperCase());
  console.log('bankTreasuryContract getManager ok ');

  expect((await bankTreasuryContract.getSBT()).toUpperCase()).to.eq(sbtContract.address.toUpperCase());
  
  expect((await moduleGlobals.getPublishCurrencyTax())).to.eq(PublishRoyaltySBT);

  // Event library deployment is only needed for testing and is not reproduced in the live environment
  eventsLib = await new Events__factory(deployer).deploy();
  console.log('eventsLib address: ', eventsLib.address);
});
