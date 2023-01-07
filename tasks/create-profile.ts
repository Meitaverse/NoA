import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

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

import { loadContract } from "./config";

import { deployContract, waitForTx , ProtocolState, Error} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat create-profile --accountid 2 --network local

task("create-profile", "create-profile function")
.addParam("accountid", "account id to collect ,from 2 to 4")
.setAction(async ({accountid}: {accountid : number}, hre) =>  {
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

  const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
  const manager = await loadContract(hre, Manager__factory, "Manager");
  const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
  const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
  const voucher = await loadContract(hre, Voucher__factory, "Voucher");
  const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");

  console.log('\t-- deployer: ', deployer.address);
  console.log('\t-- governance: ', governance.address);
  console.log('\t-- user: ', user.address);
  console.log('\t-- userTwo: ', userTwo.address);
  console.log('\t-- userThree: ', userThree.address);

  let profileCreator = accounts[accountid];
  console.log('\t-- profileCreator: ', profileCreator.address);

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
    );
  
  // full-deploy had called.
  //  await waitForTx( moduleGlobals.connect(governance).whitelistProfileCreator(user.address, true));

    console.log(
      "\n\t--- moduleGlobals isWhitelistProfileCreator address: ", await moduleGlobals.isWhitelistProfileCreator(profileCreator.address)
    );
      
    await waitForTx(
        manager.connect(profileCreator).createProfile({
          wallet: profileCreator.address,
          nickName: 'user' + `${accountid}`,
          imageURI: 'https://ipfs.io/ipfs/QmVnu7JQVoDRqSgHBzraYp7Hy78HwJtLFi6nUFCowTGdzp/' + `${accountid}` + '.png',
        })
    );

    console.log(
      "\n\t--- soulBoundToken address: ", await manager.connect(user).getWalletBySoulBoundTokenId(accountid)
    );
  

});