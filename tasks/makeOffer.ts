import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { parseEther } from '@ethersproject/units';

import {
  DerivativeNFT,
  DerivativeNFT__factory,
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
  PublishModule__factory,
  Events__factory,
  MarketPlace__factory,
} from '../typechain';

import { loadContract } from "./config";

import { deployContract, waitForTx , ProtocolState, Error, findEvent} from './helpers/utils';
import { ContractTransaction } from "ethers";
import { market } from "../typechain/contracts";

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local makeOffer --sbtid 3 --nftid 1 --price 100

task("makeOffer", "makeOffer a dNFT to market place function")
.addParam("sbtid", "soul bound token id ")
.addParam("nftid", "nft id")
.addParam("price", "offer price")
.setAction(async ({sbtid, nftid, price}: {sbtid:number, nftid:number, price:number}, hre) =>  {
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

    let buyer = accounts[sbtid];
    console.log('\n\t-- buyer: ', buyer.address);


    const FIRST_PROJECT_ID = 1; 
   
    console.log(
      "\n\t--- makeOffer  ..."
    );

    let derivativeNFT: DerivativeNFT;
    derivativeNFT = DerivativeNFT__factory.connect(
      await manager.connect(buyer).getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );

    await derivativeNFT.connect(buyer).setApprovalForAll(market.address, true);

    let units = await derivativeNFT['balanceOf(uint256)'](nftid)

    const receipt = await waitForTx(
        market.connect(buyer).makeOffer(
        {
            soulBoundTokenIdBuyer: sbtid,
            derivativeNFT: derivativeNFT.address, 
            tokenId: nftid, 
            currency: sbt.address,
            amount: price * units.toNumber(),
            soulBoundTokenIdReferrer:0,
        }
    ));

    let balance =(await sbt["balanceOf(uint256)"](sbtid)).toNumber();
    console.log('\t--- balance of buyer: ', balance);

    const escrowBalance = await bankTreasury['escrowBalanceOf(address,uint256)'](sbt.address, sbtid)
    console.log('\n\t escrowBalance:', escrowBalance)

});