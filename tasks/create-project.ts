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
  DerivativeNFT,
  DerivativeNFT__factory,
  Events__factory,
} from '../typechain';

import { loadContract } from "./config";

import { exportSubgraphNetworksJson } from "./subgraph";

import { deployContract, waitForTx , ProtocolState, Error, findEvent} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;


// yarn hardhat --network local create-project --name bitsoul2

task("create-project", "create-project function")
.addParam("name", "unique project name")
.setAction(async ({name}: {name: string}, hre) =>  {
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
  
    const SECOND_PROFILE_ID =2; 
    const FIRST_HUB_ID =1; 
    const receipt = await waitForTx(
        manager.connect(user).createProject({
          soulBoundTokenId: SECOND_PROFILE_ID,
          hubId: FIRST_HUB_ID,
          name: name, 
          description: "Hub for bitsoul",
          image: "image",
          metadataURI: "metadataURI",
          descriptor: metadataDescriptor.address,
          permitByHubOwner: false
        })
    );


    let eventsLib = await new Events__factory(deployer).deploy();
    // console.log('\n\t--- eventsLib address: ', eventsLib.address);

    const event = findEvent(receipt, 'DerivativeNFTDeployed', eventsLib);
    console.log(
      "\n\t--- createProject success! Event DerivativeNFTDeployed emited ..."
    );

    let projectId = event.args.projectId.toNumber();
    console.log('\n\t---projectid: ', projectId);
   
  
    let projectInfo = await manager.connect(user).getProjectInfo(projectId);
    console.log(
      "\n\t--- projectInfo info - hubId: ", projectInfo.hubId.toNumber()
    );
    console.log(
      "\t--- projectInfo info - soulBoundTokenId: ", projectInfo.soulBoundTokenId.toNumber()
    );
    console.log(
      "\t--- projectInfo info - name: ", projectInfo.name
    );
    console.log(
      "\t--- projectInfo info - description: ", projectInfo.description
    );
    console.log(
      "\t--- projectInfo info - image: ", projectInfo.image
    );
    console.log(
      "\t--- projectInfo info - metadataURI: ", projectInfo.metadataURI
    );
    console.log(
      "\t--- projectInfo info - descriptor: ", projectInfo.descriptor
    );

    let derivativeNFT: DerivativeNFT;

    derivativeNFT = DerivativeNFT__factory.connect(
      await manager.connect(user).getDerivativeNFT(projectId),
      user
    );

    console.log('\t---derivativeNFT address: ',  derivativeNFT.address);

    let projectContractName:string;
    if (projectId == 1)
      projectContractName = "DerivativeNFT";
    else 
      projectContractName = `DerivativeNFT-${projectId}`;

    await exportSubgraphNetworksJson(hre, derivativeNFT, projectContractName);


    //addMarket
    let feeCollectModuleAddress = "0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44";
    
    await waitForTx(
      marketPlace.connect(governance).addMarket(
        derivativeNFT.address,
        projectId,
        feeCollectModuleAddress,
        0,
        0,
        50,
        )
    );
    
    let marketInfo = await marketPlace.connect(user).getMarketInfo(derivativeNFT.address);
    console.log('\n\t--- marketInfo.isOpen : ', marketInfo.isOpen);
    console.log('\n\t--- marketInfo.collectModule : ', marketInfo.collectModule);
    console.log('\n\t--- marketInfo.feePayType : ', marketInfo.feePayType);
    console.log('\n\t--- marketInfo.feeShareType : ', marketInfo.feeShareType);
    console.log('\n\t--- marketInfo.royaltyBasisPoints : ', marketInfo.royaltySharesPoints);


    
});