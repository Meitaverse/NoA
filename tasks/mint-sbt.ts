import '@nomiclabs/hardhat-ethers';
import { hexlify, keccak256, RLP } from 'ethers/lib/utils';
import { task } from 'hardhat/config';
import { exportAddress, loadContract } from "./config";
import { exportSubgraphNetworksJson } from "./subgraph";

import {
    MIN_DELAY,
    QUORUM_PERCENTAGE,
    VOTING_PERIOD,
    VOTING_DELAY,
  } from "../helper-hardhat-config"

import {
    ERC1967Proxy__factory,
    PublishModule__factory,
    FeeCollectModule__factory,
    TimeLock__factory,
    InteractionLogic__factory,
    PublishLogic__factory,
    ModuleGlobals__factory,
    TransparentUpgradeableProxy__factory,
    ERC3525ReceiverMock__factory,
    GovernorContract__factory,
    BankTreasury__factory,
    DerivativeNFT__factory,
    NFTDerivativeProtocolTokenV1__factory,
    Manager__factory,
    Voucher__factory,
    DerivativeMetadataDescriptor__factory,
    Template__factory,
    MarketPlace__factory,
    SBTMetadataDescriptor__factory,
    MarketLogic__factory,
    Currency__factory,
    FETH__factory,
    RoyaltyRegistry__factory,
    VoucherMarket__factory,
    SBTLogic__factory,
    NFTDerivativeProtocolTokenV2,
    NFTDerivativeProtocolTokenV2__factory,
  } from '../typechain';
  import { deployContract, waitForTx , ProtocolState, Error, ZERO_ADDRESS} from './helpers/utils';
  import { ManagerLibraryAddresses } from '../typechain/factories/contracts/Manager__factory';
  
  import { DataTypes } from '../typechain/contracts/modules/template/Template';
  import { MarketPlaceLibraryAddresses } from '../typechain/factories/contracts/MarketPlace__factory';
  import { NFTDerivativeProtocolTokenV1LibraryAddresses } from '../typechain/factories/contracts/NFTDerivativeProtocolTokenV1__factory';
import { BigNumber } from 'ethers';
  
  const TREASURY_FEE_BPS = 500;
  const RECEIVER_MAGIC_VALUE = '0x009ce20b';
  const FIRST_PROFILE_ID = 1; 
  export const INITIAL_SUPPLY:BigNumber = BigNumber.from(100000000);  //SBT ininital supply, 100000000 * 1e18
  const VOUCHER_AMOUNT_LIMIT = 100;  
  const SBT_NAME = 'Bitsoul Protocol';
  const SBT_SYMBOL = 'SOUL';
  const SBT_DECIMALS = 18;
  const MARKET_DURATION = 1200; // default: 24h in seconds
  const LOCKUP_DURATION = 86400; //24h in seconds
  const NUM_CONFIRMATIONS_REQUIRED = 3;
  const PublishRoyaltySBT = 100;
  
  let managerLibs: ManagerLibraryAddresses;
  export let sbtLibs: NFTDerivativeProtocolTokenV1LibraryAddresses;


  // yarn hardhat --network local mint-sbt

  task('mint-sbt', 'mint sbt to treasury').setAction(async ({}, hre) => {
        // Note that the use of these signers is a placeholder and is not meant to be used in
        // production.
        const ethers = hre.ethers;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        const governance = accounts[1];  
        const user = accounts[2];
        const userTwo = accounts[3];
        const userThree = accounts[4];

        const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
        const manager = await loadContract(hre, Manager__factory, "Manager");
        const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
        const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
        const voucher = await loadContract(hre, Voucher__factory, "Voucher");
        const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");

        console.log('\n\t ---- version: ', await  sbt.version());

        let balance = await sbt['balanceOf(uint256)'](1);
        console.log('\n\t ---- balance of treasury: ', balance);


        await waitForTx(sbt.connect(deployer).setBankTreasury(
          bankTreasury.address, 
          50000000
      ));


        balance = await sbt['balanceOf(uint256)'](1);
        console.log('\n\t ---- balance of treasury: ', balance);
  

  });