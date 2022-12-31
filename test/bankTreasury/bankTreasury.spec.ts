import { BigNumber } from '@ethersproject/bignumber';
import { parseEther } from '@ethersproject/units';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { 
  ERC20__factory,
  DerivativeNFTV1,
  DerivativeNFTV1__factory,
 } from '../../typechain';
import { MAX_UINT256, ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';

import { 
  collectReturningTokenId, 
  getTimestamp, 
  matchEvent, 
  waitForTx 
} from '../helpers/utils';


import {
  abiCoder,
  INITIAL_SUPPLY,
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
  ndptContract,
  metadataDescriptor,
  ndptAddress,
  publishModule,
  feeCollectModule,
  template,
  receiverMock,
  moduleGlobals,
  bankTreasuryContract,
  deployer,
  voucherContract
  
} from '../__setup.spec';


import { 
  createProfileReturningTokenId,
  createHubReturningHubId,
  createProjectReturningProjectId,
} from '../helpers/utils';

let derivativeNFT: DerivativeNFTV1;
const FIRST_VOUCHER_TOKEN_ID = 1;
const SECOND_VOUCHER_TOKEN_ID = 2;

makeSuiteCleanRoom('Fee Collect Module', function () {
  const DEFAULT_COLLECT_PRICE = parseEther('10');

  beforeEach(async function () {
    await expect(
      manager.connect(governance).whitelistProfileCreator(userAddress, true)
    ).to.not.be.reverted;

    expect(
      await createProfileReturningTokenId({
          sender: user,
          vars: {
          to: userAddress,
          nickName: NickName,
          imageURI: MOCK_PROFILE_URI,
          },
         }) 
      ).to.eq(SECOND_PROFILE_ID);

    expect(
      await createProfileReturningTokenId({
          sender: userTwo,
          vars: {
          to: userTwoAddress,
          nickName: NickName3,
          imageURI: MOCK_PROFILE_URI,
          },
         }) 
      ).to.eq(THIRD_PROFILE_ID);

      expect(await manager.getWalletBySoulBoundTokenId(FIRST_PROFILE_ID)).to.eq(ndptContract.address);
      expect(await manager.getWalletBySoulBoundTokenId(SECOND_PROFILE_ID)).to.eq(userAddress);
      expect(await manager.getWalletBySoulBoundTokenId(THIRD_PROFILE_ID)).to.eq(userTwoAddress);
  });

  context('BankTreasury', function () {
    context('Negatives', function () {
      it('User should fail to exchange Voucher NDPT using none exists Voucher card', async function () {
        
        await expect(
          bankTreasuryContract.connect(user).exchangeVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
        ).to.be.revertedWith(ERRORS.VOUCHER_NOT_EXISTS);

      });

      it('User should fail to exchange Voucher NDPT using a used Voucher card', async function () {
        await expect(
          voucherContract.generateVoucher(0, userAddress)
        ).to.not.be.reverted;

        await expect(
          bankTreasuryContract.connect(user).exchangeVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
        ).to.not.be.reverted;

        await expect(
          bankTreasuryContract.connect(user).exchangeVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
        ).to.be.revertedWith(ERRORS.VOUCHER_IS_USED);

      });

      it('User should fail to exchange Voucher NDPT using a none owned of Voucher card', async function () {
        await expect(
          voucherContract.generateVoucher(0, userAddress)
        ).to.not.be.reverted;

        await expect(
          bankTreasuryContract.connect(userTwo).exchangeVoucher(FIRST_VOUCHER_TOKEN_ID, THIRD_PROFILE_ID)
        ).to.be.revertedWith(ERRORS.NOT_OWNER_VOUCHER);

        // await expect(
        //   bankTreasuryContract.exchangeVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
        // ).to.be.revertedWith(ERRORS.VOUCHER_IS_USED);

      });

    });

    context('Exchange', function () {
        it('User should receive NDPT after withdrawERC3525', async function () {
          expect((await ndptContract.balanceOfNDPT(FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY);
          expect((await ndptContract.balanceOfNDPT(SECOND_PROFILE_ID)).toNumber()).to.eq(0);
          
          await expect(
            bankTreasuryContract.withdrawERC3525(SECOND_PROFILE_ID, 1)
          ).to.not.be.reverted;

          expect((await ndptContract.balanceOfNDPT(FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY-1);
          expect((await ndptContract.balanceOfNDPT(SECOND_PROFILE_ID)).toNumber()).to.eq(1);

        });

        it('User should exchange Voucher NDPT', async function () {
          expect((await ndptContract.balanceOfNDPT(FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY);
          expect((await ndptContract.balanceOfNDPT(SECOND_PROFILE_ID)).toNumber()).to.eq(0);
          
          await expect(
            voucherContract.generateVoucher(0, userAddress)
          ).to.not.be.reverted;

         let voucherData = await voucherContract.getVoucher(FIRST_VOUCHER_TOKEN_ID);

          expect(voucherData.tokenId).to.eq(FIRST_VOUCHER_TOKEN_ID);
          expect(voucherData.ndptValue).to.eq(100);
          expect(voucherData.isUsed).to.eq(false);

          await expect(
            bankTreasuryContract.connect(user).exchangeVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
          ).to.not.be.reverted;

          expect((await ndptContract.balanceOfNDPT(SECOND_PROFILE_ID)).toNumber()).to.eq(100);
        });

        it('Voucher transfer to a new user, and new owner should exchange Voucher NDPT', async function () {
          expect((await ndptContract.balanceOfNDPT(FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY);
          expect((await ndptContract.balanceOfNDPT(SECOND_PROFILE_ID)).toNumber()).to.eq(0);
          
          await expect(
            voucherContract.generateVoucher(0, userAddress)
          ).to.not.be.reverted;

         let voucherData = await voucherContract.getVoucher(FIRST_VOUCHER_TOKEN_ID);

          expect(voucherData.tokenId).to.eq(FIRST_VOUCHER_TOKEN_ID);
          expect(voucherData.ndptValue).to.eq(100);
          expect(voucherData.isUsed).to.eq(false);

          await voucherContract.connect(user).safeTransferFrom(
            userAddress, 
            userTwoAddress, 
            FIRST_VOUCHER_TOKEN_ID,
            100,
            []
            );

          expect(await voucherContract.balanceOf(userAddress, FIRST_VOUCHER_TOKEN_ID)).to.eq(0);  
          expect(await voucherContract.balanceOf(userTwoAddress, FIRST_VOUCHER_TOKEN_ID)).to.eq(100);  

          await expect(
            bankTreasuryContract.connect(userTwo).exchangeVoucher(FIRST_VOUCHER_TOKEN_ID, THIRD_PROFILE_ID)
          ).to.not.be.reverted;

          expect((await ndptContract.balanceOfNDPT(THIRD_PROFILE_ID)).toNumber()).to.eq(100);

          let voucherData2 = await voucherContract.getVoucher(FIRST_VOUCHER_TOKEN_ID);

          expect(voucherData2.tokenId).to.eq(FIRST_VOUCHER_TOKEN_ID);
          expect(voucherData2.ndptValue).to.eq(100);
          expect(voucherData2.isUsed).to.eq(true);
        });
  

    });



  });

});
