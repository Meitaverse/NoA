import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { parseEther } from '@ethersproject/units';

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

import { waitForTx } from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local buy --sbtid 3 --nftid 2 --price 120

task("buy", "buy a dNFT to market place function")
.addParam("sbtid", "soul bound token id ")
.addParam("nftid", "nft id")
.addParam("price", "buy price")
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
    let balance = await sbt["balanceOf(uint256)"](sbtid);

    console.log('\t--- balance of buyer: ', balance.toNumber());


    const FIRST_PROJECT_ID = 1; 
   
    console.log(
      "\n\t--- buy  ..."
    );

    let derivativeNFT: DerivativeNFT;
    derivativeNFT = DerivativeNFT__factory.connect(
      await manager.connect(buyer).getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );

    let freeBalance =  await bankTreasury['balanceOf(address,uint256)'](sbt.address, sbtid)
   
    if (freeBalance.eq(0)) {

        // @notice MUST deposit SBT value into bank treasury before buy
        await bankTreasury.connect(buyer).deposit(
          sbtid,
          sbt.address,
          10000
        );

        freeBalance =  await bankTreasury['balanceOf(address,uint256)'](sbt.address, sbtid)
    }
   
    console.log(
      "\n\t--- freeBalance of buyer:", freeBalance
    );

    const buyPrice = await market.getBuyPrice(derivativeNFT.address, nftid);
    
    console.log(
      "\n\t--- buyPrice.seller: ", buyPrice.seller
    );
    
    console.log(
      "\t--- buyPrice.salePrice: ", buyPrice.salePrice
    );
    console.log(
      "\t--- buyPrice.units: ", buyPrice.units
    );

    console.log(
      "\t--- buyPrice.amount: ", buyPrice.amount
    );

  const receipt = await waitForTx(
      market.connect(buyer).buy(
        sbtid,
        derivativeNFT.address, 
        nftid, 
        price,
        0
  ));


});