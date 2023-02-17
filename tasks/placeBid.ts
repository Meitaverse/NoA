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
  MarketPlace__factory,
} from '../typechain';

import { loadContract } from "./config";

import { waitForTx, findEvent} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local placeBid --sbtid 3 --auctionid 1 --amount 110

task("placeBid", "placeBid a dNFT to market place function")
.addParam("sbtid", "soul bound token id ")
.addParam("auctionid", "auction id")
.addParam("amount", "amount for place bid")
.setAction(async ({sbtid, auctionid, amount}: {sbtid:number, auctionid:number, amount:number}, hre) =>  {
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

    let bidder = accounts[sbtid];
    console.log('\n\t-- bidder: ', bidder.address);

    let freeBalance =  await bankTreasury['balanceOf(address,uint256)'](sbt.address, sbtid)
   
    if (freeBalance.eq(0)) {

        // @notice MUST deposit SBT value into bank treasury before buy
        await bankTreasury.connect(bidder).deposit(
          sbtid,
          sbt.address,
          10000
        );

        freeBalance =  await bankTreasury['balanceOf(address,uint256)'](sbt.address, sbtid)
    }
   
    console.log(
      "\n\t--- freeBalance of bidder:", freeBalance
    );

    
    console.log(
      "\n\t--- placeBid  ..."
    );

    const receipt = await waitForTx(
        market.connect(bidder).placeBid(
            sbtid,
            auctionid,
            amount, //new total amount to bid
            0, //Referrer id
    ));

    let eventsLib = await new Events__factory(deployer).deploy();
    const event = findEvent(receipt, 'ReserveAuctionBidPlaced', eventsLib);
    console.log(
      "\n\t--- placeBid success! Event ReserveAuctionBidPlaced emited ..."
    );
    
    console.log(
      "\t\t--- auction id:",  event.args.auctionid
    );
    console.log(
      "\t\t--- bidder:",  event.args.bidder
    );
    console.log(
      "\t\t--- amount:",  event.args.amount
    );
    console.log(
        "\t\t--- endTime:", event.args.endTime
      );
  
});
