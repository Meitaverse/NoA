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
  Events__factory,
} from '../typechain';

import { loadContract } from "./config";

import { waitForTx, findEvent} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local publish2 --projectid 2

task("publish2", "publish function")
.addParam("projectid", "project id to publish")
.setAction(async ({projectid}: {projectid: number}, hre) =>  {
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


  console.log('\n\t-- sbt: ', sbt.address);
  console.log('\t-- feeCollectModule: ', feeCollectModule.address);
  console.log('\t-- publishModule: ', publishModule.address);
  console.log('\t-- template: ', template.address);


    let abiCoder = ethers.utils.defaultAbiCoder;
    const PROFILE_ID = 6; 
    const SECOND_HUB_ID = 2; 
    const DEFAULT_COLLECT_PRICE = 10;
    const Default_royaltyBasisPoints = 50; //
    const GENESIS_FEE_BPS = 100;
    const DEFAULT_TEMPLATE_NUMBER = 1;

    const collectModuleInitData = abiCoder.encode(
        ['uint256', 'uint16', 'uint16'],
        [DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints, 0]
    );

    const publishModuleinitData = abiCoder.encode(
        ['address', 'uint256'],
        [template.address, DEFAULT_TEMPLATE_NUMBER],
    );
    console.log("\n\t -- publishModuleinitData: ", publishModuleinitData);
    
    const FIRST_PROFILE_ID =1;
    let balance_bank =(await sbt["balanceOf(uint256)"](FIRST_PROFILE_ID));
    console.log('\n\t--- balance of bank : ', balance_bank);

 
    let balance =(await sbt["balanceOf(uint256)"](PROFILE_ID)).toNumber();
    if (balance == 0) {
      //mint 10000000 Value to userTwo
      await bankTreasury.connect(userTwo).buySBT(PROFILE_ID, {value: 100000000});
    }
    console.log('\t--- balance of userTwo: ', (await sbt["balanceOf(uint256)"](PROFILE_ID)).toNumber());
    
    // console.log({
    //   soulBoundTokenId: PROFILE_ID,
    //   hubId: SECOND_HUB_ID,
    //   projectId: projectid,
    //   currency: sbt.address,
    //   amount: "1",
    //   salePrice: "1",
    //   royaltyBasisPoints: "1",
    //   name: "Dollar6", //MUST different!!!
    //   description: "Hand draw6",
    //   canCollect: true,
    //   materialURIs: [],
    //   fromTokenIds: [],  //Set empty for genesis.
    //   collectModule: feeCollectModule.address,
    //   collectModuleInitData: "0x000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000000000000000000000000000000000000",
    //   publishModule: publishModule.address,
    //   publishModuleInitData: publishModuleinitData,
    // });
/*

*/
    const receipt = await waitForTx(
      manager.connect(userTwo).prePublish({
        soulBoundTokenId: 6,
        hubId: 2,
        projectId: "5",
        currency: "0x82e01223d51eb87e16a03e24687edf0f294da6f1",
        amount: "1",
        salePrice: "1",
        royaltyBasisPoints: "1",
        name: "Dollar62231231",
        description: "Hand draw62123123",
        canCollect: true,
        materialURIs: [],
        fromTokenIds: [],
        collectModule: "0x1fa02b2d6a771842690194cf62d91bdd92bfe28d",
        collectModuleInitData:
          "0x000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000000000000000000000000000000000000",
        publishModule: "0xdbc43ba45381e02825b14322cddd15ec4b3164e6",
        publishModuleInitData:
          "0x0000000000000000000000008f86403a4de0bb5791fa46b8e795c547942fe4cf0000000000000000000000000000000000000000000000000000000000000001",
      })
    );

    let eventsLib = await new Events__factory(deployer).deploy();

    const event = findEvent(receipt, 'PublishPrepared', eventsLib);
    const NEW_PUBLISH_ID = event.args.publishId.toNumber();
    const previousPublishId = event.args.previousPublishId.toNumber();
    console.log(
      "\n\t--- prePublish success! Event PublishPrepared emited ..."
    );
    console.log(
      "\t\t--- new publishId: ", NEW_PUBLISH_ID
    );
    console.log(
      "\t\t--- previousPublishId: ", previousPublishId
    );


    let publishInfo = await manager.connect(userTwo).getPublishInfo(NEW_PUBLISH_ID);

    console.log(
      "\n\t--- soulBoundTokenId: ", publishInfo.publication.soulBoundTokenId.toNumber()
    );
    console.log(
      "\t--- hubId: ", publishInfo.publication.hubId.toNumber()
    );
    console.log(
      "\t--- projectId: ", publishInfo.publication.projectId.toNumber()
    );
    console.log(
      "\t--- amount: ", publishInfo.publication.amount.toNumber()
    );
    console.log(
      "\t--- name: ", publishInfo.publication.name
    );
    console.log(
      "\t--- description: ", publishInfo.publication.description
    );
    console.log(
      "\t--- salePrice: ", publishInfo.publication.salePrice.toNumber()
    );
    console.log(
      "\t--- royaltyBasisPoints: ", publishInfo.publication.royaltyBasisPoints
    );

    //updatePublish
/*
    await waitForTx(
      manager.connect(user).updatePublish(
        NEW_PUBLISH_ID,
        DEFAULT_COLLECT_PRICE + 10,
        50 + 50,
        11,
        "USA Dollar",
        "Hand draw USD",
        [],
        [],
      )
    );
    console.log(
      "\n\t--- After update publish..."
    );

    publishInfo = await manager.connect(user).getPublishInfo(FIRST_PUBLISH_ID);
    console.log(
      "\n\t--- salePrice: ", publishInfo.publication.salePrice
    );
    console.log(
      "\t--- royaltyBasisPoints: ", publishInfo.publication.royaltyBasisPoints
    );
    console.log(
      "\t--- amount: ", publishInfo.publication.amount
    );
    console.log(
      "\t--- name: ", publishInfo.publication.name
    );
    console.log(
      "\t--- description: ", publishInfo.publication.description
    );
*/

/*
    console.log(
      "\n\t--- Publish  ..."
    );

    const receipt2 =  await waitForTx(
      manager.connect(userTwo).publish(
        NEW_PUBLISH_ID,
      )
    );
    const event2 = findEvent(receipt2, 'PublishCreated', eventsLib);
    
    const amount = event2.args.amount.toNumber();
    console.log(
      "\n\t--- publish success! Event PublishCreated emited ..."
    );
    console.log(
      "\t\t---amount: ", amount
    );

    const event3 = findEvent(receipt2, 'PublishMinted', eventsLib);
    const newTokenId = event3.args.newTokenId.toNumber();
    console.log(
          "\t\t---newTokenId: ", newTokenId
        );

    balance_bank =(await sbt["balanceOf(uint256)"](FIRST_PROFILE_ID));
    console.log('\n\t--- balance of bank : ', balance_bank);

    let balance_left =(await sbt["balanceOf(uint256)"](THIRD_PROFILE_ID)).toNumber();
    console.log('\t--- balance of userTwo after publish : ', balance_left);
    
    let derivativeNFT: DerivativeNFT;
    derivativeNFT = DerivativeNFT__factory.connect(
      await manager.connect(userTwo).getDerivativeNFT(projectid),
      userTwo
      );
      
    console.log('\n\t--- ownerOf newTokenId : ', await derivativeNFT.ownerOf(newTokenId));
    console.log('\t--- balanceOf newTokenId : ', (await derivativeNFT["balanceOf(uint256)"](newTokenId)).toNumber());

    */

  });