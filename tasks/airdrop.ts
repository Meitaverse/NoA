import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

import {
  FeeCollectModule__factory,
  ModuleGlobals__factory,
  BankTreasury__factory,
  NFTDerivativeProtocolTokenV1__factory,
  Manager__factory,
  Voucher__factory,
  Template__factory,
  PublishModule__factory,
  Events__factory,
} from '../typechain';

import { loadContract } from "./config";

import {  waitForTx, findEvent} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local airdrop --nftid 1

task("airdrop", "airdrop array of dNFTs to many users function")
.addParam("nftid", "derivative nft id to collect")
.setAction(async ({nftid}: {nftid: number}, hre) =>  {
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
  const feeCollectModule = await loadContract(hre, FeeCollectModule__factory, "FeeCollectModule");
  const publishModule = await loadContract(hre, PublishModule__factory, "PublishModule");
  const template = await loadContract(hre, Template__factory, "Template");

  console.log('\t-- deployer: ', deployer.address);
  console.log('\t-- governance: ', governance.address);
  console.log('\t-- user: ', user.address);
  console.log('\t-- userTwo: ', userTwo.address);
  console.log('\t-- userThree: ', userThree.address);

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
    );
    let ownerid = 2;
    let owner = user;
    console.log('\n\t-- owner: ', owner.address);


    const FIRST_PUBLISH_ID =1; 
   
    console.log(
      "\n\t--- Airdrop to [userTwo(3), userThree(4)] ..."
    );

    const receipt =  await waitForTx(
      manager.connect(owner).airdrop({
        publishId: FIRST_PUBLISH_ID,
        ownershipSoulBoundTokenId: ownerid,
        toSoulBoundTokenIds: [3, 4], //userTwo, userThree
        tokenId: nftid,
        values: [1, 2],
      })
    );

    //
    let eventsLib = await new Events__factory(deployer).deploy();
    // console.log('\n\t--- eventsLib address: ', eventsLib.address);

    const event = findEvent(receipt, 'DerivativeNFTAirdroped', eventsLib);
    const newTokenIds = event.args.newTokenIds;
    console.log(
      "\n\t--- airdrop success! Event DerivativeNFTAirdroped emited ..."
    );
    
    console.log(
      "\t\t--- newTokenIds:", newTokenIds
    );

});