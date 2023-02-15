import { BigNumber } from '@ethersproject/bignumber';
import { parseEther } from '@ethersproject/units';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';

import { 
  ERC20__factory,
  DerivativeNFT,
  DerivativeNFT__factory,
 } from '../../typechain';
import { MAX_UINT256, ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import { TransactionReceipt, TransactionResponse } from '@ethersproject/providers';

import { 
  collectReturningTokenId, 
  getTimestamp, 
  matchEvent, 
  waitForTx 
} from '../helpers/utils';


import {
  abiCoder,
  INITIAL_SUPPLY,
  VOUCHER_AMOUNT_LIMIT,
  FIRST_PROFILE_ID,
  SECOND_PROFILE_ID,
  THIRD_PROFILE_ID,
  FOUR_PROFILE_ID,
  FIRST_HUB_ID,
  FIRST_PROJECT_ID,
  FIRST_DNFT_TOKEN_ID,
  SECOND_DNFT_TOKEN_ID,
  FIRST_PUBLISH_ID,
  GENESIS_FEE_BPS,
  DEFAULT_COLLECT_PRICE,
  DEFAULT_TEMPLATE_NUMBER,
  NickName,
  NickName3,
  governance,
  manager,
  makeSuiteCleanRoom,
  MAX_PROFILE_IMAGE_URI_LENGTH,
  mockModuleData,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  userAddress,
  user,
  userTwo,
  userTwoAddress,
  sbtContract,
  metadataDescriptor,
  publishModule,
  feeCollectModule,
  template,
  receiverMock,
  moduleGlobals,
  bankTreasuryContract,
  deployer,
  voucherContract,
  currency
  
} from '../__setup.spec';

import { 
  createProfileReturningTokenId,
} from '../helpers/utils';
import { ContractTransaction, ethers } from 'ethers';

let derivativeNFT: DerivativeNFT;
const FIRST_VOUCHER_TOKEN_ID = 1;
const SECOND_VOUCHER_TOKEN_ID = 2;
let receipt: TransactionReceipt;
let original_balance = 10000;
let balance = 500;

makeSuiteCleanRoom('Bank Treasury', function () {

  beforeEach(async function () {
 
    expect(
      await createProfileReturningTokenId({
          sender: user,
          vars: {
          wallet: userAddress,
          nickName: NickName,
          imageURI: MOCK_PROFILE_URI,
          },
         }) 
      ).to.eq(SECOND_PROFILE_ID);

    expect(
      await createProfileReturningTokenId({
          sender: userTwo,
          vars: {
          wallet: userTwoAddress,
          nickName: NickName3,
          imageURI: MOCK_PROFILE_URI,
          },
         }) 
      ).to.eq(THIRD_PROFILE_ID);

      expect(await manager.getWalletBySoulBoundTokenId(SECOND_PROFILE_ID)).to.eq(userAddress);
      expect(await manager.getWalletBySoulBoundTokenId(THIRD_PROFILE_ID)).to.eq(userTwoAddress);

  });

  context('BankTreasury', function () {
    
  
    context('Withdraw all avaliable earnest funds', function () {
      beforeEach(async () => {
        //user buy some SBT Values 
        await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});

        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(original_balance);
        
        await bankTreasuryContract.connect(user).deposit(
          SECOND_PROFILE_ID,
          sbtContract.address,
          balance
        );
        expect(await bankTreasuryContract['balanceOf(address,uint256)'](sbtContract.address, SECOND_PROFILE_ID)).to.eq(balance);
        
        receipt = await waitForTx(
           bankTreasuryContract.connect(user).withdraw(
            SECOND_PROFILE_ID, 
            sbtContract.address, 
            balance
          ) 
        );

      });

      it("Emits WithdrawnEarnestFunds", async () => {
         matchEvent(
          receipt,
          'WithdrawnEarnestFunds',
          [
            SECOND_PROFILE_ID, 
            userAddress,
            sbtContract.address,
            balance
          ],
        );

      });

      it("Balance of SBT ", async () => {
        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(original_balance);
      });

      it("Has no SBT remaining", async () => {
        const balanceOf = await bankTreasuryContract.balanceOf(sbtContract.address, SECOND_PROFILE_ID);
        expect(balanceOf).to.eq(0);
      });

      it("Cannot withdraw again", async () => {
        // await bankTreasuryContract.connect(user).withdraw(
        //   SECOND_PROFILE_ID, 
        //   sbtContract.address,
        //   balance
        // );
        await expect(bankTreasuryContract.connect(user).withdraw(
          SECOND_PROFILE_ID, 
          sbtContract.address,
          balance)
        ).to.be.revertedWith("Insufficient_Available_Funds");
      });

    });
    
    context('Withdraw a part of earnest funds', function () {
      beforeEach(async () => {
        //user buy some SBT Values 
        await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});

        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(original_balance);
        
        await bankTreasuryContract.connect(user).deposit(
          SECOND_PROFILE_ID,
          sbtContract.address,
          original_balance
        );
        expect(await bankTreasuryContract['balanceOf(address,uint256)'](sbtContract.address, SECOND_PROFILE_ID)).to.eq(original_balance);
        
        
        receipt = await waitForTx(
           bankTreasuryContract.connect(user).withdraw(
            SECOND_PROFILE_ID, 
            sbtContract.address, 
            balance
          ) 
        );

      });

      it("Emits WithdrawnEarnestFunds", async () => {
         matchEvent(
          receipt,
          'WithdrawnEarnestFunds',
          [
            SECOND_PROFILE_ID, 
            userAddress,
            sbtContract.address,
            balance
          ],
        );
      });

      it("Balance of SBT ", async () => {
        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(balance);
      });

      it("Has SBT remaining", async () => {
        const balanceOf = await bankTreasuryContract.balanceOf(sbtContract.address, SECOND_PROFILE_ID);
        expect(balanceOf).to.eq(original_balance - balance);
      });

      it("Can withdraw again", async () => {
        await expect(
          bankTreasuryContract.connect(user).withdraw(
            SECOND_PROFILE_ID, 
            sbtContract.address, 
            balance
          ) 
        ).to.not.be.reverted;
      });

    });

    context('Negatives', function () {
      beforeEach(async () => {
        //user buy some SBT Values 
        await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});
        
      });



      it('User should fail to exchange Voucher SBT using none exists Voucher card', async function () {
        
        await expect(
          bankTreasuryContract.connect(user).depositFromVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
        ).to.be.reverted;

      });

      it('User should fail to exchange Voucher SBT using a used Voucher card', async function () {

        await expect(
          voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [original_balance], [''])
        ).to.not.be.reverted;

        await expect(
          bankTreasuryContract.connect(user).depositFromVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
        ).to.not.be.reverted;

        //use again
        await expect(
          bankTreasuryContract.connect(user).depositFromVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
        ).to.be.reverted;

      });

      it('User should fail to exchange Voucher SBT using a none owned of Voucher card', async function () {

        await expect(
          voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [100], [''])
        ).to.not.be.reverted;

        await expect(
          bankTreasuryContract.connect(userTwo).depositFromVoucher(FIRST_VOUCHER_TOKEN_ID, THIRD_PROFILE_ID)
        ).to.be.reverted;

      });

    });

    context('deposit', function () {
        beforeEach(async () => {
          //user buy some SBT Values 
          await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});
                    
        });
        
        it('User should deposited after user call tranferFrom to treasury', async function () {

          // let totalSupply:BigNumber = await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID);
         
          // let balance = INITIAL_SUPPLY.mul(BigNumber.from('10').pow(18)).sub(original_balance);

          // expect(totalSupply).to.deep.equal(balance);


          await bankTreasuryContract.connect(user).deposit(
            SECOND_PROFILE_ID,
            sbtContract.address,
            6000
          );
          expect(await bankTreasuryContract['balanceOf(address,uint256)'](sbtContract.address, SECOND_PROFILE_ID)).to.eq(6000);
          
          expect((await bankTreasuryContract.balanceOf(sbtContract.address, SECOND_PROFILE_ID)).toNumber()).to.eq(6000);

          expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(4000);

        });

        it('User should use SBT Value to mint Voucher', async function () {

          await expect(
            voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [100], [''])
          ).to.not.be.reverted;

         let sbtValue = await voucherContract.balanceOf(userAddress, FIRST_VOUCHER_TOKEN_ID);

          expect(sbtValue).to.eq(100);

          await expect(
            bankTreasuryContract.connect(user).depositFromVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
          ).to.not.be.reverted;

          expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(original_balance);
        });

        it('Voucher transfer to a new user, and new owner should exchange Voucher SBT', async function () {

          await expect(
            voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [100], [''])
          ).to.not.be.reverted;

         let sbtValue = await voucherContract.balanceOf(userAddress, FIRST_VOUCHER_TOKEN_ID);

          expect(sbtValue).to.eq(100);

          await voucherContract.connect(user).safeTransferFrom(
            userAddress, 
            userTwoAddress, 
            FIRST_VOUCHER_TOKEN_ID,
            100,
            []
            );

          expect(await voucherContract.balanceOf(userAddress, FIRST_VOUCHER_TOKEN_ID)).to.eq(0);  
          expect(await voucherContract.balanceOf(userTwoAddress, FIRST_VOUCHER_TOKEN_ID)).to.eq(100);  

          await voucherContract.connect(userTwo).setApprovalForAll(bankTreasuryContract.address, true);
          
          await expect(
            bankTreasuryContract.connect(userTwo).depositFromVoucher(FIRST_VOUCHER_TOKEN_ID, THIRD_PROFILE_ID)
          ).to.not.be.reverted;

          expect((await sbtContract['balanceOf(uint256)'](THIRD_PROFILE_ID)).toNumber()).to.eq(100);

 
        });
  
    });

    

  });

});
