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


// yarn hardhat create-hub --network local
task("create-hub", "create-hub function")
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

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
    );
  
   // permit user to create a hub
   const SECOND_PROFILE_ID =2;
   await waitForTx( moduleGlobals.connect(governance).whitelistHubCreator(SECOND_PROFILE_ID, true));

    console.log(
      "\n\t--- moduleGlobals whitelistHubCreator set true for user: ", userAddress
    );
      
    await waitForTx(
        manager.connect(user).createHub({
          soulBoundTokenId: SECOND_PROFILE_ID,
          name: "bitsoul",
          description: "Hub for bitsoul",
          imageURI: "https://ipfs.io/ipfs/QmVnu7JQVoDRqSgHBzraYp7Hy78HwJtLFi6nUFCowTGdzp/11.png",
        })
    );

    let hubInfo = await manager.connect(user).getHubInfo(1);

    console.log(
      "\n\t--- hub info - soulBoundTokenId:  ", hubInfo.soulBoundTokenId.toNumber()
    );
    console.log(
      "\t--- hub info - name:  ", hubInfo.name
    );
    console.log(
      "\t--- hub info - description:  ", hubInfo.description
    );
    console.log(
      "\t--- hub info - imageURI:  ", hubInfo.imageURI
    );


});