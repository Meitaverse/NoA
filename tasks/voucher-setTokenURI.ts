import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import { loadContract } from "./config";

import {
    PublishModule__factory,
    FeeCollectModule__factory,
    ModuleGlobals__factory,
    BankTreasury__factory,
    NFTDerivativeProtocolTokenV1__factory,
    Manager__factory,
    Voucher__factory,
    Template__factory,
    MarketPlace__factory,
    Currency__factory,
  } from '../typechain';
  import { waitForTx , ProtocolState, Error, ZERO_ADDRESS} from './helpers/utils';
  
  
  const FIRST_PROFILE_ID = 1; 
  const VOUCHER_AMOUNT_LIMIT = 100;  

  // yarn setup-mumbai
  // yarn hardhat --network local voucher-setTokenURI --tokenid 1 --uri https://nftstorage.link/ipfs/bafybeiej6hnolqihsh7pg22xe4gaf3dlf4qgvfzhenkuwcy67rwmma7bfq

  task('voucher-setTokenURI', 'voucher setTokenURI')
  .addParam("tokenid", "which token id to set uri")
  .addParam("uri", "uri")
  .setAction(async ({tokenid, uri}: {tokenid : number, uri: string}, hre) =>  {
        const ethers = hre.ethers;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        const governance = accounts[1];  
        const user = accounts[2];
        const userTwo = accounts[3];
        const userThree = accounts[4];
        const deployer2 = accounts[5];

        const proxyAdminAddress = deployer.address;

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
        const currency = await loadContract(hre, Currency__factory, "Currency");
      
        let admins = await voucher.getAdmins();
        console.log('\n\t-- admins: ', admins);

        //"https://nftstorage.link/ipfs/bafybeiej6hnolqihsh7pg22xe4gaf3dlf4qgvfzhenkuwcy67rwmma7bfq"
        await waitForTx( 
          voucher.connect(governance)['setTokenURI(uint256,string)']
          (
            tokenid, 
            uri
          )
        );

        let _uri = await voucher.uri(1);
        console.log('\n\t-- uri: ', _uri);

   });