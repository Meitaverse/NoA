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
  Events__factory,
} from '../typechain';

import { loadContract } from "./config";

import { waitForTx, findEvent} from './helpers/utils';
import { BigNumber } from "ethers";

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local collect --projectid 27 --publishid 22 --collectorid 2

task("collect", "collect a dNFT function")
.addParam("projectid", "project id ")
.addParam("collectorid", "soul bound token id ")
.addParam("publishid", "publish id")
.setAction(async ({projectid, collectorid, publishid}: {projectid:number, collectorid:number, publishid:number}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  

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

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
    );

    let collector = accounts[collectorid];
    console.log('\n\t-- collector: ', collector.address);
    let balance = await sbt["balanceOf(uint256)"](collectorid);
    if (balance == BigNumber.from(0)) {
      //mint 10000000 Value to user
      await bankTreasury.connect(collector).buySBT(collectorid, {value: 10000000});
    }
    console.log('\t--- balance of collector: ', (await sbt["balanceOf(uint256)"](collectorid)));


    console.log(
      "\n\t--- Collet  ..."
    );

    const receipt = await waitForTx(
      manager.connect(collector).collect({
        publishId: publishid,
        collectorSoulBoundTokenId: collectorid,
        collectUnits: 1,
        data: [],
      })
    );

    let eventsLib = await new Events__factory(deployer).deploy();
    // console.log('\n\t--- eventsLib address: ', eventsLib.address);

    const event = findEvent(receipt, 'DerivativeNFTCollected', eventsLib);
    const projectId = event.args.projectId.toNumber();
    const derivativeNFTAddress = event.args.derivativeNFT;
    const fromSoulBoundTokenId = event.args.fromSoulBoundTokenId.toNumber();
    const toSoulBoundTokenId = event.args.toSoulBoundTokenId.toNumber();
    const tokenId = event.args.tokenId.toNumber();
    const value = event.args.value.toNumber();
    const newTokenId = event.args.newTokenId.toNumber();

    console.log(
      "\n\t--- Event DerivativeNFTCollected emited ..."
    );
    console.log(
      "\t--- DerivativeNFTCollected, projectId: ", projectId
    );
    console.log(
      "\t--- DerivativeNFTCollected, derivativeNFT address: ", derivativeNFTAddress
    );
    console.log(
      "\t--- DerivativeNFTCollected, fromSoulBoundTokenId: ", fromSoulBoundTokenId
    );
    console.log(
      "\t--- DerivativeNFTCollected, toSoulBoundTokenId: ", toSoulBoundTokenId
    );
    console.log(
      "\t--- DerivativeNFTCollected, tokenId: ", tokenId
    );
    console.log(
      "\t--- DerivativeNFTCollected, collect value: ", value
    );
    console.log(
      "\t--- DerivativeNFTCollected, newTokenId: ", newTokenId
    );


    let derivativeNFT: DerivativeNFT;
    derivativeNFT = DerivativeNFT__factory.connect(
      await manager.connect(collector).getDerivativeNFT(projectid),
      collector
    );
      
    console.log('\n\t--- ownerOf newTokenId : ', await derivativeNFT.ownerOf(newTokenId));
    console.log('\t--- balanceOf newTokenId : ', (await derivativeNFT["balanceOf(uint256)"](newTokenId)).toNumber());
    
});