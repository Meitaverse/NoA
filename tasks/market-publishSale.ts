import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { parseEther } from '@ethersproject/units';

import {
  DerivativeNFTV1,
  DerivativeNFTV1__factory,
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
  MarketPlace__factory,
} from '../typechain';

import { loadContract } from "./config";

import { deployContract, waitForTx , ProtocolState, Error} from './helpers/utils';

let runtimeHRE: HardhatRuntimeEnvironment;
let derivativeNFT: DerivativeNFTV1;

// yarn hardhat market-publishSale --nftid 1 --network local

task("market-publishSale", "market place functions")
.addParam("nftid", "derivative nft id to be sale")
.setAction(async ({nftid}: {nftid: number}, hre) =>  {
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


    const FIRST_PROJECT_ID =1; 
    const FIRST_PUBLISH_ID =1; 
    // const FIRST_DNFT_TOKEN_ID=1;

    const SECOND_PROFILE_ID =2;
    const SECOND_DNFT_TOKEN_ID=2;
    
   
    console.log(
      "\n\t--- user publish sale  ..."
    );


    let derivativeNFT: DerivativeNFTV1;
    derivativeNFT = DerivativeNFTV1__factory.connect(
      await manager.connect(user).getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );

    
    //approve marketPlace
    await waitForTx(
      derivativeNFT.connect(user)["approve(address,uint256)"](marketPlace.address, nftid)
    );

    await waitForTx(
      marketPlace.connect(user).publishSale({
        soulBoundTokenId: SECOND_PROFILE_ID,
        projectId: FIRST_PROJECT_ID,
        tokenId: nftid,
        onSellUnits: 10, 
        startTime: 1673236726,
        salePrice: 100,
        priceType: 0,
        min: 0,
        max: 10, 
      })
    );
    
    console.log('\n\t--- ownerOf nftid : ', await derivativeNFT.ownerOf(nftid));
    console.log('\t--- balanceOf nftid : ', (await derivativeNFT["balanceOf(uint256)"](nftid)).toNumber());
    
    console.log('\n\t--- ownerOf second tokenId : ', await derivativeNFT.ownerOf(SECOND_DNFT_TOKEN_ID));
    console.log('\t--- balanceOf second tokenId : ', (await derivativeNFT["balanceOf(uint256)"](SECOND_DNFT_TOKEN_ID)).toNumber());
    
});