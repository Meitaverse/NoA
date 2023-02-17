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
  MarketPlace__factory,
} from '../typechain';

import { loadContract } from "./config";

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local getReserveAuction --auctionid 3

task("getReserveAuction", "getReserveAuction a dNFT to market place function")
.addParam("auctionid", "auction id")
.setAction(async ({auctionid}: {auctionid:number}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  
  const user = accounts[2];
  const userTwo = accounts[3];
  const userThree = accounts[4];
  const userFour = accounts[5];

  const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
  const manager = await loadContract(hre, Manager__factory, "Manager");
  const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
  const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
  const market = await loadContract(hre, MarketPlace__factory, "MarketPlace");
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
  console.log('\t-- userFour: ', userFour.address);

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
    );

    let info = await market.getReserveAuction(auctionid);
    console.log('\n\t getReserveAuction:')
    console.log('\t\t--- oulBoundTokenId:', info.soulBoundTokenId)
    console.log('\t\t--- derivativeNFT:', info.derivativeNFT)
    console.log('\t\t--- projectId:', info.projectId)
    console.log('\t\t--- publishId:', info.publishId)
    console.log('\t\t--- tokenId:', info.tokenId)
    console.log('\t\t--- units:', info.units)
    console.log('\t\t--- seller:', info.seller)
    console.log('\t\t--- units:', info.units)
    console.log('\t\t--- duration:', info.duration)
    console.log('\t\t--- extensionDuration:', info.extensionDuration)
    console.log('\t\t--- endTime:', info.endTime)
    console.log('\t\t--- bidder:', info.bidder)
    console.log('\t\t--- soulBoundTokenIdBidder:', info.soulBoundTokenIdBidder)
    console.log('\t\t--- amount:', info.amount)    
    

});
