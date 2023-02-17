import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

import {
  DerivativeNFT,
  DerivativeNFT__factory,
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

import { waitForTx} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local acceptOffer --sbtid 2  --fromsbtid 3 --nftid 1

task("acceptOffer", "acceptOffer a dNFT to market place function")
.addParam("sbtid", "soul bound token id ")
.addParam("fromsbtid", "from soul bound token id ")
.addParam("nftid", "nft id")
.addParam("price", "sale price")
.setAction(async ({sbtid, fromsbtid, nftid, price}: {sbtid:number, fromsbtid:number, nftid:number, price:number}, hre) =>  {
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

    let seller = accounts[sbtid];
    let offerFrom = accounts[fromsbtid];

    console.log('\n\t-- seller: ', seller.address);
    console.log('\n\t-- offerFrom: ', offerFrom.address);

    let balance = (await sbt["balanceOf(uint256)"](sbtid)).toNumber();
    console.log('\t--- balance of seller: ', balance);

    const FIRST_PROJECT_ID = 1; 
   
    console.log(
      "\n\t--- acceptOffer  ..."
    );

    let derivativeNFT: DerivativeNFT;
    derivativeNFT = DerivativeNFT__factory.connect(
      await manager.connect(seller).getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );

    await derivativeNFT.connect(seller).setApprovalForAll(market.address, true);

    let units = await derivativeNFT['balanceOf(uint256)'](nftid)

    const receipt = await waitForTx(
        market.connect(seller).acceptOffer(
          sbtid,
          derivativeNFT.address, 
          nftid,
          offerFrom.address,
          price * units.toNumber() //minAmount
    ));

});