import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { 
  ManagerImpl_ADDRESS, 
  Manager_ADDRESS, 
  Bank_Treasury_ADDRESS, 
  NDP_ADDRESS,
  Voucher_ADDRESS,
  ModuleGlobals_ADDRESS,
 } from './addresses';

import {
  FeeCollectModule,
  FeeCollectModule__factory,
  PublishLogic__factory,
  ModuleGlobals,
  ModuleGlobals__factory,
  TransparentUpgradeableProxy__factory,
  BankTreasury,
  BankTreasury__factory,
  NFTDerivativeProtocolTokenV1,
  NFTDerivativeProtocolTokenV1__factory,
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

export let runtimeHRE: HardhatRuntimeEnvironment;

task("create-profile", "create-profile function")
// .addParam("manager", "address of manager")
.setAction(async ({}: {}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  //治理合约地址
  const user = accounts[2];
  const userTwo = accounts[3];
  const userThree = accounts[4];

  const userAddress = user.address;
  const userTwoAddress = userTwo.address;
  const userThreeAddress = userThree.address;

  const managerImpl = await ethers.getContractAt("Manager", ManagerImpl_ADDRESS);
  const manager = Manager__factory.connect(Manager_ADDRESS, governance);
  const bankTreasury = await ethers.getContractAt("BankTreasury", Bank_Treasury_ADDRESS);
  const ndp = await ethers.getContractAt("NFTDerivativeProtocolTokenV1", NDP_ADDRESS);
  const voucher = await ethers.getContractAt("Voucher", Voucher_ADDRESS);
  const moduleGlobals = await ethers.getContractAt("ModuleGlobals", ModuleGlobals_ADDRESS);
  
  console.log('\t-- deployer: ', deployer.address);
  console.log('\t-- governance: ', governance.address);
  console.log('\t-- user: ', user.address);
  console.log('\t-- userTwo: ', userTwo.address);
  console.log('\t-- userThree: ', userThree.address);

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
    );
  
  // full-deploy had called.
  //  await waitForTx( moduleGlobals.connect(governance).whitelistProfileCreator(user.address, true));

    console.log(
      "\n\t--- moduleGlobals isWhitelistProfileCreator userAddress: ", await moduleGlobals.isWhitelistProfileCreator(userAddress)
    );
      
    await waitForTx(
        manager.connect(user).createProfile({
          wallet: userAddress,
          nickName: 'user1',
          imageURI: 'https://ipfs.io/ipfs/QmVnu7JQVoDRqSgHBzraYp7Hy78HwJtLFi6nUFCowTGdzp/1.png',
        })
    );

    console.log(
      "\n\t--- soulBoundToken:2 address: ", await manager.getWalletBySoulBoundTokenId(2)
    );
  

});