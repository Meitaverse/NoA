import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

import {
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
  MarketPlace__factory,
  DerivativeNFTV1,
  DerivativeNFTV1__factory,
} from '../typechain';

import { loadContract } from "./config";

import { deployContract, waitForTx , ProtocolState, Error} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;


// yarn hardhat add-market --network local

task("add-market", "add-market function")
.setAction(async ({}: {}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  //治理合约地址
  const user = accounts[2];
  const userTwo = accounts[3];
  const userThree = accounts[4];

  const userAddress = user.address;
  const userTwoAddress = userTwo.address;
  const userThreeAddress = userThree.address;

  const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
  const manager = await loadContract(hre, Manager__factory, "Manager");
  const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
  const marketPlace = await loadContract(hre, MarketPlace__factory, "MarketPlace");
  const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
  const voucher = await loadContract(hre, Voucher__factory, "Voucher");
  const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");
  const metadataDescriptor = await loadContract(hre, DerivativeMetadataDescriptor__factory, "MetadataDescriptor");

  console.log('\t-- deployer: ', deployer.address);
  console.log('\t-- governance: ', governance.address);
  console.log('\t-- user: ', user.address);
  console.log('\t-- userTwo: ', userTwo.address);
  console.log('\t-- userThree: ', userThree.address);

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
    );
  
    const SECOND_PROFILE_ID =2; 
    const FIRST_HUB_ID =1; 
    // await waitForTx(
    //     manager.connect(user).createProject({
    //       soulBoundTokenId: SECOND_PROFILE_ID,
    //       hubId: FIRST_HUB_ID,
    //       name: "bitsoul",
    //       description: "Hub for bitsoul",
    //       image: "image",
    //       metadataURI: "metadataURI",
    //       descriptor: metadataDescriptor.address,
    //       defaultRoyaltyPoints: 0,
    //       feeShareType: 0,  
    //     })
    // );

    const FIRST_PROJECT_ID =1;

    // let projectInfo = await manager.connect(user).getProjectInfo(FIRST_PROJECT_ID);
    // console.log(
    //   "\n\t--- projectInfo info - hubId: ", projectInfo.hubId.toNumber()
    // );
    // console.log(
    //   "\t--- projectInfo info - soulBoundTokenId: ", projectInfo.soulBoundTokenId.toNumber()
    // );
    // console.log(
    //   "\t--- projectInfo info - name: ", projectInfo.name
    // );
    // console.log(
    //   "\t--- projectInfo info - description: ", projectInfo.description
    // );
    // console.log(
    //   "\t--- projectInfo info - image: ", projectInfo.image
    // );
    // console.log(
    //   "\t--- projectInfo info - metadataURI: ", projectInfo.metadataURI
    // );
    // console.log(
    //   "\t--- projectInfo info - descriptor: ", projectInfo.descriptor
    // );
    // console.log(
    //   "\t--- projectInfo info - defaultRoyaltyPoints: ", projectInfo.defaultRoyaltyPoints.toNumber()
    // );
    // console.log(
    //   "\t--- projectInfo info - feeShareType: ", projectInfo.feeShareType
    // );

    let derivativeNFT: DerivativeNFTV1;

    derivativeNFT = DerivativeNFTV1__factory.connect(
      await manager.connect(user).getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );

    console.log(
      "\n\t---derivativeNFT: ", derivativeNFT.address
    );

    //addMarket
    await waitForTx(
      marketPlace.connect(governance).addMarket(
         derivativeNFT.address,
        0,
        0,
        50
        )
    );
    
    let marketInfo = await marketPlace.connect(user).getMarketInfo(derivativeNFT.address);
    console.log('\n\t--- marketInfo.isValid : ', marketInfo.isValid);
    console.log('\n\t--- marketInfo.feePayType : ', marketInfo.feePayType);
    console.log('\n\t--- marketInfo.feeShareType : ', marketInfo.feeShareType);
    console.log('\n\t--- marketInfo.royaltyBasisPoints : ', marketInfo.royaltyBasisPoints);


      
    const FIRST_DNFT_TOKEN_ID = 1;
    console.log('\n\t--- ownerOf FIRST_DNFT_TOKEN_ID : ', await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID));
    console.log('\t--- balanceOf FIRST_DNFT_TOKEN_ID : ', (await derivativeNFT["balanceOf(uint256)"](FIRST_DNFT_TOKEN_ID)).toNumber());
    
});