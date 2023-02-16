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

// yarn hardhat --network local deposit-voucher --sbtid 2 --voucherid 10

task("deposit-voucher", "deposit-voucher function")
.addParam("sbtid", "account id to collect ,from 2 to 4")
.addParam("voucherid", "the voucher id")
.setAction(async ({sbtid, voucherid}: {sbtid : number, voucherid : number}, hre) =>  {
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

  let operator = accounts[sbtid];
  let balance = await sbt['balanceOf(uint256)'](sbtid);
  console.log('\n\t-- balance: ', balance);

  let voucherAmount = await voucher.connect(operator)['balanceOf(address,uint256)'](await operator.getAddress(), voucherid);

  if (voucherAmount.eq(0)) {
    console.log('\n\t-- voucherAmount is zero or not owner ');
    return 
  }

  console.log('\n\t-- voucherAmount: ', voucherAmount);

  //TODO
  if (await voucher.isApprovedForAll(bankTreasury.address, await operator.getAddress())) {
    console.log('\n\t--  operator set approved for ', bankTreasury.address);
  } else {
    await voucher.connect(operator).setApprovalForAll(bankTreasury.address, true);
  }
  
  const receipt = await waitForTx(
      bankTreasury.connect(operator).depositFromVoucher(voucherid, sbtid)
  );

  let eventsLib = await new Events__factory(deployer).deploy();
  const event = findEvent(receipt, 'VoucherDeposited', eventsLib);

  let sbtValue = event.args.sbtValue;
  console.log('\n\t-- sbtValue: ', sbtValue);

  balance = await sbt['balanceOf(uint256)'](sbtid);
  console.log('\n\t-- new balance: ', balance);


          
  voucherAmount = await voucher.connect(operator)['balanceOf(address,uint256)'](await operator.getAddress(), voucherid);
  if (voucherAmount.eq(0)) {
    console.log('\n\t-- voucher is used');

  }

});