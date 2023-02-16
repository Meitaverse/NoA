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
  Events__factory,
} from '../typechain';

import { loadContract } from "./config";

import { deployContract, waitForTx , ProtocolState, Error, findEvent} from './helpers/utils';
import { ContractTransaction } from "@ethersproject/contracts";

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local transfer-voucher --fromsbtid 2 --tosbtid 3 --voucherid 1

task("transfer-voucher", "transfer-voucher function")
.addParam("fromsbtid", "account id to tranfrer ,from 2 to 4")
.addParam("tosbtid", "account id to receive ,from 2 to 4")
.addParam("voucherid", "the voucher id")
.setAction(async ({fromsbtid, tosbtid, voucherid}: {fromsbtid : number, tosbtid : number, voucherid : number}, hre) =>  {
  runtimeHRE = hre;
  const ethers = hre.ethers;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const governance = accounts[1];  
  const user = accounts[2];
  const userTwo = accounts[3];
  const userThree = accounts[4];
  const userFour = accounts[5];
  const userFive = accounts[6];


  const managerImpl = await loadContract(hre, Manager__factory, "ManagerImpl");
  const manager = await loadContract(hre, Manager__factory, "Manager");
  const bankTreasury = await loadContract(hre, BankTreasury__factory, "BankTreasury");
  const sbt = await loadContract(hre, NFTDerivativeProtocolTokenV1__factory, "SBT");
  const voucher = await loadContract(hre, Voucher__factory, "Voucher");
  const moduleGlobals = await loadContract(hre, ModuleGlobals__factory, "ModuleGlobals");

  // console.log('\t-- deployer: ', deployer.address);
  // console.log('\t-- governance: ', governance.address);
  // console.log('\t-- user: ', user.address);
  // console.log('\t-- userTwo: ', userTwo.address);
  // console.log('\t-- userThree: ', userThree.address);
  // console.log('\t-- userFour: ', userFour.address);

  let from = accounts[fromsbtid];
  let to = accounts[tosbtid];

  let voucherAmount = await voucher.connect(from)['balanceOf(address,uint256)'](from.address, voucherid);

  if (voucherAmount.eq(0)) {
    console.log('\n\t-- voucherAmount is zero or not owner ');
    return 
  }

  console.log('\n\t-- voucherAmount: ', voucherAmount);


  const receipt = await waitForTx(
      voucher.connect(from).safeTransferFrom(from.address, to.address, voucherid, voucherAmount, [])
  );

  // const event = findEvent(receipt, 'TransferSingle', voucher);

  // let newOwner = event.args.wallet;
  // console.log('\n\t-- newOwner: ', newOwner.address);

  // voucherAmount = await voucher['balanceOf(address,uint256)'](newOwner.address, voucherid);
  // console.log('\n\t-- new voucherAmount of newOwner: ', voucherAmount);


});