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

// yarn hardhat --network local publish --projectid 1

task("publish", "publish function")
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

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
    );
  
    let abiCoder = ethers.utils.defaultAbiCoder;
    const SECOND_PROFILE_ID =2; 
    const FIRST_HUB_ID =1; 
    const DEFAULT_COLLECT_PRICE = 10;
    const Default_royaltyBasisPoints = 50; //
    const GENESIS_FEE_BPS = 100;
    const DEFAULT_TEMPLATE_NUMBER = 1;
    const collectLimitPerAddress = 0; //每个地址最多可以收藏多少个， 0 - unlimited
    
    const date = new Date(); // 创建一个 Date 对象
    const utcTimestamp = Math.floor(date.getTime() / 1000); // 获取 UTC 时间戳（单位为秒）

    const collectModuleInitData = abiCoder.encode(
        ['uint256', 'uint16', 'uint16', 'uint32'],
        [DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints, collectLimitPerAddress, utcTimestamp]
    );

    const publishModuleinitData = abiCoder.encode(
        ['address', 'uint256'],
        [template.address, DEFAULT_TEMPLATE_NUMBER],
    );
    
    const FIRST_PROFILE_ID =1;
    let balance_bank =(await sbt["balanceOf(uint256)"](FIRST_PROFILE_ID));
    console.log('\n\t--- balance of bank : ', balance_bank);

 
    let balance =(await sbt["balanceOf(uint256)"](SECOND_PROFILE_ID)).toNumber();
    if (balance == 0) {
      //mint 10000000 Value to user
      await bankTreasury.connect(user).buySBT(SECOND_PROFILE_ID, {value: 100000000});
    }
    console.log('\t--- balance of user: ', (await sbt["balanceOf(uint256)"](SECOND_PROFILE_ID)).toNumber());

    const receipt = await waitForTx(
      manager.connect(user).prePublish({
        soulBoundTokenId: SECOND_PROFILE_ID,
        hubId: FIRST_HUB_ID,
        projectId: projectid,
        currency: sbt.address, //SOUL / WETH
        amount: 11,
        salePrice: DEFAULT_COLLECT_PRICE,
        royaltyBasisPoints: GENESIS_FEE_BPS,
        name: "Dollar",
        description: "Hand draw",
        canCollect: true, //是否可以收藏， false - 不可以收藏, true - 可以收藏
        materialURIs: [],
        fromTokenIds: [],
        collectModule: feeCollectModule.address,
        collectModuleInitData: collectModuleInitData,
        publishModule: publishModule.address,
        publishModuleInitData: publishModuleinitData,
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


    let publishInfo = await manager.connect(user).getPublishInfo(NEW_PUBLISH_ID);

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


    console.log(
      "\n\t--- Publish  ..."
    );

    const receipt2 =  await waitForTx(
      manager.connect(user).publish(
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

    let balance_left =(await sbt["balanceOf(uint256)"](SECOND_PROFILE_ID)).toNumber();
    console.log('\t--- balance of user after publish : ', balance_left);
    
    let derivativeNFT: DerivativeNFT;
    derivativeNFT = DerivativeNFT__factory.connect(
      await manager.connect(user).getDerivativeNFT(projectid),
      user
      );
      
    console.log('\n\t--- ownerOf newTokenId : ', await derivativeNFT.ownerOf(newTokenId));
    console.log('\t--- balanceOf newTokenId : ', (await derivativeNFT["balanceOf(uint256)"](newTokenId)).toNumber());

  });