import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

import {
  ModuleGlobals__factory,
  BankTreasury__factory,
  NFTDerivativeProtocolTokenV1__factory,
  Manager__factory,
  Voucher__factory,
  DerivativeMetadataDescriptor__factory,
  MarketPlace__factory,
  DerivativeNFT,
  DerivativeNFT__factory,
} from '../typechain';

import { loadContract } from "./config";

import { waitForTx } from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;


// yarn hardhat --network local add-market

task("add-market", "add-market function")
.setAction(async ({}: {}, hre) =>  {
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

  await waitForTx(
      marketPlace.connect(governance).grantOperator(governance.address)
  );

    const SECOND_PROFILE_ID =2; 
    const FIRST_HUB_ID =1; 


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

    let derivativeNFT: DerivativeNFT;

    derivativeNFT = DerivativeNFT__factory.connect(
      await manager.connect(user).getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );

    console.log(
      "\n\t---derivativeNFT: ", derivativeNFT.address
    );

    /*
    //addMarket
    let feeCollectModuleAddress = "0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44";
    await waitForTx(
      marketPlace.connect(governance).addMarket(
        derivativeNFT.address,
        FIRST_PROJECT_ID,
        feeCollectModuleAddress,
        0,
        0,
        50,
        )
    );
    */
    let marketInfo = await marketPlace.connect(user).getMarketInfo(derivativeNFT.address);
    console.log('\n\t--- marketInfo.isOpen : ', marketInfo.isOpen);
    console.log('\n\t--- marketInfo.collectModule : ', marketInfo.collectModule);
    console.log('\n\t--- marketInfo.feePayType : ', marketInfo.feePayType);
    console.log('\n\t--- marketInfo.feeShareType : ', marketInfo.feeShareType);
    console.log('\n\t--- marketInfo.royaltyBasisPoints : ', marketInfo.royaltySharesPoints);

    
});