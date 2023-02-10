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
  Events__factory,
} from '../typechain';

import { loadContract } from "./config";

import { deployContract, waitForTx , ProtocolState, Error, findEvent} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local update-profile --accountid 2 --nickname alice

task("update-profile", "update-profile function")
.addParam("accountid", "account id to collect ,from 2 to 4")
.addParam("nickname", "new nickname")
.setAction(async ({accountid}: {accountid : number}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  
  const user = accounts[2];
  const userTwo = accounts[3];
  const userThree = accounts[4];
  const userFour = accounts[5];
  const userFive = accounts[6];


  const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
  const manager = await loadContract(hre, Manager__factory, "Manager");
  const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
  const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
  const voucher = await loadContract(hre, Voucher__factory, "Voucher");
  const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");

  // console.log('\t-- deployer: ', deployer.address);
  // console.log('\t-- governance: ', governance.address);
  // console.log('\t-- user: ', user.address);
  // console.log('\t-- userTwo: ', userTwo.address);
  // console.log('\t-- userThree: ', userThree.address);
  // console.log('\t-- userFour: ', userFour.address);

  let profileCreator = accounts[accountid];
  console.log('\n\t-- profileCreator: ', profileCreator.address);

  //add profile creator to whilelist
   await waitForTx( moduleGlobals.connect(governance).whitelistProfileCreator(profileCreator.address, true));

  console.log(
    "\n\t--- moduleGlobals isWhitelistProfileCreator address: ", await moduleGlobals.isWhitelistProfileCreator(profileCreator.address)
  );
      
  const receipt = await waitForTx(
      sbt.connect(profileCreator).updateProfile(
        accountid,
        'user' + `${accountid}`,
        'https://ipfs.io/ipfs/QmVnu7JQVoDRqSgHBzraYp7Hy78HwJtLFi6nUFCowTGdzp/' + `${accountid}` + '.png',
      )
  );


  let eventsLib = await new Events__factory(deployer).deploy();
  // console.log('\n\t--- eventsLib address: ', eventsLib.address);

  const event = findEvent(receipt, 'ProfileCreated', eventsLib);
  console.log(
    "\n\t--- CreateProfile success! Event ProfileCreated emited ..."
  );
  console.log(
    "\t\t--- ProfileCreated, soulBoundTokenId: ", event.args.soulBoundTokenId.toNumber()
  );
  console.log(
    "\t\t--- ProfileCreated, creator: ", event.args.creator
  );
  console.log(
    "\t\t--- ProfileCreated, wallet: ", event.args.wallet
  );
  console.log(
    "\t\t--- ProfileCreated, nickName: ", event.args.nickName
  );
  console.log(
    "\t\t--- ProfileCreated, imageURI: ", event.args.imageURI
  );

  let balance = await sbt["balanceOf(uint256)"](event.args.soulBoundTokenId);
  if (balance.eq(0)) {
    //mint 10000000 Value to profileCreator
    await bankTreasury.connect(profileCreator).buySBT(event.args.soulBoundTokenId, {value: 10000000});
  }

  balance = await sbt["balanceOf(uint256)"](event.args.soulBoundTokenId);
  console.log(
    "\n\t--- balanceOf profileCreator: ", balance
  );
});