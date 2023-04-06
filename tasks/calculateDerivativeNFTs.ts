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
} from '../typechain';

import { loadContract } from "./config";

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local calculateDerivativeNFTs --projectend 100

task("calculateDerivativeNFTs", "calculate DerivativeNFT contract addresses function")
.addParam("projectend", "project end number")
.setAction(async ({projectend}: {projectend: number}, hre) =>  {
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



  const projectIdStart = 1;

  const derivativeNFTAddresses = await manager.calculateDerivativeNFTAddress(projectIdStart, projectend);
  console.log('Derivative NFT Addresses:');
  for (let i = projectIdStart; i < projectend; i++) {
    // console.log(`\t DerivativeNFT-${i+1}: ${derivativeNFTAddresses[i]}`);
        let projectContractName:string;
        if (i == projectIdStart)
            projectContractName = "DerivativeNFT";
        else 
            projectContractName = `DerivativeNFT-${i}`;

        console.log(`\t--- projectContractName: ${projectContractName}  ${derivativeNFTAddresses[i]}` );


  }



  });