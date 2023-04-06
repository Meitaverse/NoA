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
  Events__factory,
} from '../typechain';

import { loadContract } from "./config";

import { exportSubgraphNetworksJson } from "./subgraph";

import { waitForTx, findEvent} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;


// yarn hardhat --network local create-project --name bitsoultai2 --accountid 2 --hubid 1 --profileid 2

task("create-project", "create-project function")
.addParam("name", "unique project name")
.addParam("accountid", "account id")
.addParam("hubid", "hubid owned by the project")
.addParam("profileid", "profileid")
.setAction(async ({name, hubid,accountid,profileid}: {name: string, hubid: number,accountid:number,profileid:number}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  

  const user = accounts[accountid];


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

  console.log(
      "\t--- ModuleGlobals governance address: ", await moduleGlobals.getGovernance()
    );
  
    
    const receipt = await waitForTx(
        manager.connect(user).createProject({
          soulBoundTokenId: profileid,
          hubId: hubid,
          name: name, 
          description: "Hub for bitsoul",
          image: "image",
          metadataURI: "metadataURI",
          descriptor: metadataDescriptor.address,
          defaultRoyaltyPoints: 0,
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

    // let projectContractName:string;
    // if (projectId == 1)
    //   projectContractName = "DerivativeNFT";
    // else 
    //   projectContractName = `DerivativeNFT-${projectId}`;

    // await exportSubgraphNetworksJson(hre, derivativeNFT, projectContractName);

 
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