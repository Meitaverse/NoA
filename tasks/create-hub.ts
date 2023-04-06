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


// yarn hardhat --network local create-hub --accountid 2 --profileid 2

task("create-hub", "create-hub function")
.addParam("accountid", "account id to collect ,from 2 to 9")
.addParam("profileid", "profileid")
.setAction(async ({accountid,profileid}: {accountid : number, profileid: number}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  
  const hubOwner = accounts[accountid];
  const hubOwnerAddress = hubOwner.address;

  const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
  const manager = await loadContract(hre, Manager__factory, "Manager");
  const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
  const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
  const voucher = await loadContract(hre, Voucher__factory, "Voucher");
  const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");

  console.log('\t-- deployer: ', deployer.address);
  console.log('\t-- governance: ', governance.address);
  console.log('\t-- v: ', hubOwner.address);

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
  );
  
  // permit user to create a hub
  await waitForTx( moduleGlobals.connect(governance).whitelistHubCreator(profileid, true));

  console.log(
    "\n\t--- moduleGlobals whitelistHubCreator set true for user: ", hubOwnerAddress
  );
    
  
  const receipt = await waitForTx(
      manager.connect(hubOwner).createHub({
        soulBoundTokenId: profileid,
        name: "bitsoul",
        description: "Hub for bitsoul",
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


  // let hubId =1;

  let hubInfo = await manager.connect(hubOwner).getHubInfo(hubId);

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