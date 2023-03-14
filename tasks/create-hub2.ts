import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

import {
  ModuleGlobals__factory,
  BankTreasury__factory,
  NFTDerivativeProtocolTokenV1__factory,
  Manager__factory,
  Voucher__factory,
  Events__factory,
} from '../typechain';

import { loadContract } from "./config";

import { waitForTx, findEvent} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;


// yarn hardhat --network local create-hub2

task("create-hub2", "create-hub function")
.setAction(async ({}: {}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  
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
  
  // permit userTwo to create a hub
  const THIRD_PROFILE_ID = 3;
  await waitForTx( moduleGlobals.connect(governance).whitelistHubCreator(THIRD_PROFILE_ID, true));

  console.log(
    "\n\t--- moduleGlobals whitelistHubCreator set true for userTwo: ", userTwoAddress
  );
    
  
  const receipt = await waitForTx(
      manager.connect(userTwo).createHub({
        soulBoundTokenId: THIRD_PROFILE_ID,
        name: "bitsoul-user2",
        description: "Hub for user2",
        imageURI: "https://ipfs.io/ipfs/QmVnu7JQVoDRqSgHBzraYp7Hy78HwJtLFi6nUFCowTGdzp/11.png",
      })
  );

  let eventsLib = await new Events__factory(deployer).deploy();
  // console.log('\n\t--- eventsLib address: ', eventsLib.address);

  const event = findEvent(receipt, 'HubCreated', eventsLib);
  console.log(
    "\n\t--- createHub success! Event HubCreated emited ..."
  );

  let hubId = event.args.hubId.toNumber();
  console.log(
    "\t\t--- HubCreated, hubId: ", hubId
  );

  let hubOwner = event.args.hubOwner.toString();
  console.log(
    "\t\t--- HubCreated, hubOwner: ", hubOwner
  );

  // let hubId =1;

  let hubInfo = await manager.connect(userTwo).getHubInfo(hubId);

  console.log(
    "\t\t--- hub info - soulBoundTokenId:  ", hubInfo.soulBoundTokenId.toNumber()
  );
  console.log(
    "\t\t--- hub info - name:  ", hubInfo.name
  );
  console.log(
    "\t\t--- hub info - description:  ", hubInfo.description
  );
  console.log(
    "\t\t--- hub info - imageURI:  ", hubInfo.imageURI
  );


});