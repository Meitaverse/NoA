import { AbiCoder } from '@ethersproject/abi';
import { parseEther } from '@ethersproject/units';
import '@nomiclabs/hardhat-ethers';
import { expect, use } from 'chai';
import { solidity } from 'ethereum-waffle';
import { BytesLike, Contract, Signer, Wallet } from 'ethers';
import { ethers } from "hardhat";

import {
  ERC1967Proxy__factory,
  // ApprovalFollowModule,
  // ApprovalFollowModule__factory,
  // CollectNFT__factory,
  Currency,
  Currency__factory,
  // FreeCollectModule,
  // FreeCollectModule__factory,
  Events,
  Events__factory,
  FeeCollectModule,
  FeeCollectModule__factory,
  // FeeFollowModule,
  // FeeFollowModule__factory,
  // FollowerOnlyReferenceModule,
  // FollowerOnlyReferenceModule__factory,
  // FollowNFT__factory,
  Helper,
  Helper__factory,
  InteractionLogic__factory,
  PublishLogic__factory,
  // LensHub,
  // LensHub__factory,
  // LimitedFeeCollectModule,
  // LimitedFeeCollectModule__factory,
  // LimitedTimedFeeCollectModule,
  // LimitedTimedFeeCollectModule__factory,
  // MockFollowModule,
  // MockFollowModule__factory,
  // MockReferenceModule,
  // MockReferenceModule__factory,
  ModuleGlobals,
  ModuleGlobals__factory,
  // ProfileTokenURILogic__factory,
  // PublishingLogic__factory,
  // RevertCollectModule,
  // RevertCollectModule__factory,
  // TimedFeeCollectModule,
  // TimedFeeCollectModule__factory,
  TransparentUpgradeableProxy__factory,
  // LensPeriphery,
  // LensPeriphery__factory,
  // ProfileFollowModule,
  // ProfileFollowModule__factory,
  // FollowNFT,
  // CollectNFT,
  // RevertFollowModule,
  // RevertFollowModule__factory,
  ERC3525ReceiverMock,
  ERC3525ReceiverMock__factory,
  GovernorContract,
  GovernorContract__factory,
  BankTreasury,
  BankTreasury__factory,
  DerivativeNFTV1,
  DerivativeNFTV1__factory,
  Incubator,
  Incubator__factory,
  NFTDerivativeProtocolTokenV1,
  NFTDerivativeProtocolTokenV2,
  NFTDerivativeProtocolTokenV1__factory,
  NFTDerivativeProtocolTokenV2__factory,
  Manager,
  Manager__factory,
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

use(solidity);

export const NUM_CONFIRMATIONS_REQUIRED = 3;
export const CURRENCY_MINT_AMOUNT = parseEther('100');
export const BPS_MAX = 10000;
export const TREASURY_FEE_BPS = 50;
export const PublishRoyalty = 100;
export const REFERRAL_FEE_BPS = 250;
export const MAX_PROFILE_IMAGE_URI_LENGTH = 6000;
export const NDPT_NAME = 'NFT Derivative Protocol Token';
export const NDPT_SYMBOL = 'NDPT';
export const NDPT_DECIMALS = 18;
export const MOCK_PROFILE_HANDLE = 'plant1ghost.eth';
export const LENS_PERIPHERY_NAME = 'LensPeriphery';
export const FIRST_PROFILE_ID = 1;
export const MOCK_URI = 'https://ipfs.io/ipfs/QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR';
export const OTHER_MOCK_URI = 'https://ipfs.io/ipfs/QmSfyMcnh1wnJHrAWCBjZHapTS859oNSsuDFiAPPdAHgHP';
export const MOCK_PROFILE_URI =
  'https://ipfs.io/ipfs/Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu';
export const MOCK_FOLLOW_NFT_URI =
  'https://ipfs.fleek.co/ipfs/ghostplantghostplantghostplantghostplantghostplantghostplan';

export const  RECEIVER_MAGIC_VALUE = '0x009ce20b';
export const TreasuryFee = 50; 

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
export let testWallet: Wallet;
// export let lensHubImpl: LensHub;
// export let lensHub: LensHub;
export let managerImpl: Manager;
export let manager: Manager;
export let currency: Currency;
export let abiCoder: AbiCoder;
export let mockModuleData: BytesLike;
// export let hubLibs: LensHubLibraryAddresses;
export let managerLibs: ManagerLibraryAddresses;
export let eventsLib: Events;
export let moduleGlobals: ModuleGlobals;
export let helper: Helper;
// export let lensPeriphery: LensPeriphery;
// export let followNFTImpl: FollowNFT;
// export let collectNFTImpl: CollectNFT;
export let receiverMock: ERC3525ReceiverMock
export let bankTreasuryImpl: BankTreasury
export let bankTreasuryContract: BankTreasury
export let ndptImpl: NFTDerivativeProtocolTokenV1;
export let ndptContract: NFTDerivativeProtocolTokenV1;
export let derivativeNFTV1Impl: DerivativeNFTV1;
export let incubatorImpl: Incubator;

export let receiverMockAddress: string;
export let ndptAddress: string;
export let bankTreasuryAddress: string;
export let derivativeNFTV1ImplAddress: string;
export let incubatorImplAddress: string;
export let managerAddress: string;
// export let version: Number;

/* Modules */

// Collect
export let feeCollectModule: FeeCollectModule;
// export let timedFeeCollectModule: TimedFeeCollectModule;
// export let freeCollectModule: FreeCollectModule;
// export let revertCollectModule: RevertCollectModule;
// export let limitedFeeCollectModule: LimitedFeeCollectModule;
// export let limitedTimedFeeCollectModule: LimitedTimedFeeCollectModule;

// Follow
// export let approvalFollowModule: ApprovalFollowModule;
// export let profileFollowModule: ProfileFollowModule;
// export let feeFollowModule: FeeFollowModule;
// export let revertFollowModule: RevertFollowModule;
// export let mockFollowModule: MockFollowModule;

// Reference
// export let followerOnlyReferenceModule: FollowerOnlyReferenceModule;
// export let mockReferenceModule: MockReferenceModule;

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
  userThree = accounts[4];
  governance = accounts[3];

  deployerAddress = await deployer.getAddress();
  userAddress = await user.getAddress();
  userTwoAddress = await userTwo.getAddress();
  userThreeAddress = await userThree.getAddress();
  governanceAddress = await governance.getAddress();
  mockModuleData = abiCoder.encode(['uint256'], [1]);
  // Deployment
  helper = await new Helper__factory(deployer).deploy();


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
  // nonce + 2 is impl
  // nonce + 3 is manager proxy

  const managerProxyAddress = computeContractAddress(deployerAddress, nonce + 3); //'0x' + keccak256(RLP.encode([deployerAddress, hubProxyNonce])).substr(26);

  receiverMock = await new ERC3525ReceiverMock__factory(deployer).deploy(RECEIVER_MAGIC_VALUE, Error.None);
  receiverMockAddress = receiverMock.address;

  bankTreasuryImpl = await new BankTreasury__factory(deployer).deploy();

  ndptImpl = await new NFTDerivativeProtocolTokenV1__factory(deployer).deploy();
  let initializeNDPTData = ndptImpl.interface.encodeFunctionData("initialize", [
      NDPT_NAME, 
      NDPT_SYMBOL, 
      NDPT_DECIMALS,
      managerProxyAddress,
      bankTreasuryImpl.address,
  ]);
  const ndptProxy = await new ERC1967Proxy__factory(deployer).deploy(
    ndptImpl.address,
    initializeNDPTData
  );
  ndptContract = new NFTDerivativeProtocolTokenV1__factory(deployer).attach(ndptProxy.address);
  ndptAddress = ndptContract.address;
  
  let initializeData = bankTreasuryImpl.interface.encodeFunctionData("initialize", [
    managerProxyAddress,
    governanceAddress,
    TreasuryFee,
   [userAddress, userTwoAddress, userThreeAddress],
   NUM_CONFIRMATIONS_REQUIRED  //All full signed 
  ]);

  const bankTreasuryProxy = await new ERC1967Proxy__factory(deployer).deploy(
    bankTreasuryImpl.address,
    initializeData
  );
  bankTreasuryContract = new BankTreasury__factory(deployer).attach(bankTreasuryProxy.address);
  bankTreasuryAddress = bankTreasuryContract.address;

  derivativeNFTV1Impl = await new DerivativeNFTV1__factory(deployer).deploy(managerProxyAddress, ndptContract.address);
  derivativeNFTV1ImplAddress = derivativeNFTV1Impl.address;

  incubatorImpl = await new Incubator__factory(deployer).deploy(managerProxyAddress, ndptContract.address);
  incubatorImplAddress = incubatorImpl.address;

  managerImpl = await new Manager__factory(managerLibs, deployer).deploy(
    derivativeNFTV1ImplAddress,
    incubatorImplAddress,
    receiverMockAddress,
  );

  let data = managerImpl.interface.encodeFunctionData('initialize', [
    governanceAddress,
    ndptAddress,
    bankTreasuryImpl.address
  ]);

  let proxy = await new TransparentUpgradeableProxy__factory(deployer).deploy(
    managerImpl.address,
    deployerAddress,
    data
  );

  // Connect the manager proxy to the Manager factory and the user for ease of use.
  manager = Manager__factory.connect(proxy.address, user);
  managerAddress = manager.address;

  // Currency
  currency = await new Currency__factory(deployer).deploy();

  moduleGlobals = await new ModuleGlobals__factory(deployer).deploy(
    ndptAddress,
    governanceAddress,
    bankTreasuryImpl.address,
    TREASURY_FEE_BPS,
    PublishRoyalty
  );
  
  await expect(manager.connect(governance).setState(ProtocolState.Unpaused)).to.not.be.reverted;
  await expect(
    manager.connect(governance).whitelistProfileCreator(userAddress, true)
  ).to.not.be.reverted;
  await expect(
    manager.connect(governance).whitelistProfileCreator(userTwoAddress, true)
  ).to.not.be.reverted;
  await expect(
    manager.connect(governance).whitelistProfileCreator(userThreeAddress, true)
  ).to.not.be.reverted;
  await expect(
    manager.connect(governance).whitelistProfileCreator(testWallet.address, true)
  ).to.not.be.reverted;

  expect(bankTreasuryContract).to.not.be.undefined;
  expect(ndptContract).to.not.be.undefined;
  expect(receiverMock).to.not.be.undefined;
  expect(derivativeNFTV1Impl).to.not.be.undefined;
  expect(incubatorImpl).to.not.be.undefined;
  expect(manager).to.not.be.undefined;
  expect(currency).to.not.be.undefined;

  expect((await manager.version()).toNumber()).to.eq(1);
  expect(await manager.NDPT()).to.eq(ndptContract.address);
  expect((await ndptContract.version()).toNumber()).to.eq(1);
  expect((await ndptContract.getManager()).toUpperCase()).to.eq(managerProxyAddress.toUpperCase());
  expect((await ndptContract.getBankTreasury()).toUpperCase()).to.eq(bankTreasuryImpl.address.toUpperCase());

  // Event library deployment is only needed for testing and is not reproduced in the live environment
  eventsLib = await new Events__factory(deployer).deploy();
});
