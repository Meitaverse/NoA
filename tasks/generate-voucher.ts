import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from 'hardhat/types';

import {
  ModuleGlobals__factory,
  BankTreasury__factory,
  NFTDerivativeProtocolTokenV1__factory,
  Manager__factory,
  Voucher__factory,
} from '../typechain';

import { loadContract } from "./config";

import { waitForTx, findEvent} from './helpers/utils';

export let runtimeHRE: HardhatRuntimeEnvironment;

// yarn hardhat --network local generate-voucher --sbtid 2 --amount 1000

task("generate-voucher", "generate-voucher function")
.addParam("sbtid", "account id to collect ,from 2 to 4")
.addParam("amount", "amount of voucher value")
.setAction(async ({sbtid, amount}: {sbtid : number, amount : number}, hre) =>  {
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
  if (balance.eq(0)) {
    //mint 10000000 Value to profileCreator
    await bankTreasury.connect(operator).buySBT(sbtid, {value: 10000000});
  }

  
  await sbt.connect(operator).setApprovalForAll(voucher.address, true);
  await voucher.connect(operator).setApprovalForAll(bankTreasury.address, true);

  const receipt = await waitForTx(
      voucher.connect(operator).mintBaseNew(sbtid, [await operator.getAddress()], [amount], [''])
  );

  const event = findEvent(receipt, 'GenerateVoucher', voucher);

  let voucher_tokenId = event.args.tokenIds[0];
  console.log('\n\t-- voucher_tokenId: ', voucher_tokenId);

  // await  bankTreasury.connect(operator).depositFromVoucher(voucher_tokenId, sbtid);

  
  balance = await sbt['balanceOf(uint256)'](sbtid);
  console.log('\n\t-- new balance: ', balance);
  let voucherAmount = await voucher.connect(operator)['balanceOf(address,uint256)'](await operator.getAddress(), voucher_tokenId);
  console.log('\n\t-- voucherAmount: ', voucherAmount);

});