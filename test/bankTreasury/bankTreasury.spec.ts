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
  voucherContract
  
} from '../__setup.spec';


import { 
  createProfileReturningTokenId,
} from '../helpers/utils';

let derivativeNFT: DerivativeNFT;
const FIRST_VOUCHER_TOKEN_ID = 1;
const SECOND_VOUCHER_TOKEN_ID = 2;

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
    context('Negatives', function () {
      it('User should fail to exchange Voucher SBT using none exists Voucher card', async function () {
        
        await expect(
          bankTreasuryContract.connect(user).exchangeVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
        ).to.be.revertedWith(ERRORS.VOUCHER_NOT_EXISTS);
        // await bankTreasuryContract.connect(user).exchangeVoucher(
        //   FIRST_VOUCHER_TOKEN_ID, 
        //   SECOND_PROFILE_ID
        // );

      });

      it('User should fail to exchange Voucher SBT using a used Voucher card', async function () {
        await expect(
          voucherContract.connect(deployer).generateVoucher(1, userAddress)
        ).to.not.be.reverted;


        await expect(
          bankTreasuryContract.connect(user).exchangeVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
        ).to.not.be.reverted;

        await expect(
          bankTreasuryContract.connect(user).exchangeVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
        ).to.be.revertedWith(ERRORS.VOUCHER_IS_USED);

      });

      it('User should fail to exchange Voucher SBT using a none owned of Voucher card', async function () {
        await expect(
          voucherContract.connect(deployer).generateVoucher(1, userAddress)
        ).to.not.be.reverted;

        await expect(
          bankTreasuryContract.connect(userTwo).exchangeVoucher(FIRST_VOUCHER_TOKEN_ID, THIRD_PROFILE_ID)
        ).to.be.revertedWith(ERRORS.NOT_OWNER_VOUCHER);

      });

    });

    context('Exchange', function () {
      
        it('User should deposited after user call tranferFrom to treasury', async function () {

          //mint some Values to user
          await manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, 10000);

          expect((await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY);
          expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(10000);
          
          await sbtContract.connect(user)['transferFrom(uint256,uint256,uint256)'](SECOND_PROFILE_ID, FIRST_PROFILE_ID, 6000);

          expect((await bankTreasuryContract.balanceOf(SECOND_PROFILE_ID)).toNumber()).to.eq(6000);

          expect((await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY + 6000);
          expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(4000);

        });
      
        it('User should receive SBT after withdrawERC3525', async function () {

          //mint some Values to user
          await manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, 10000);

          expect((await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY);
          expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(10000);
          
          await sbtContract.connect(user)['transferFrom(uint256,uint256,uint256)'](SECOND_PROFILE_ID, FIRST_PROFILE_ID, 6000);
          
          await expect(
            bankTreasuryContract.connect(user).withdrawERC3525(SECOND_PROFILE_ID, 500)
          ).to.not.be.reverted;

          expect((await bankTreasuryContract.balanceOf(SECOND_PROFILE_ID)).toNumber()).to.eq(5500);

          expect((await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY + 5500);
          expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(4500);

        });
        

        it('User should exchange Voucher SBT', async function () {
          expect((await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY);
          expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(0);
          
          await expect(
            voucherContract.connect(deployer).generateVoucher(1, userAddress)
          ).to.not.be.reverted;

         let voucherData = await voucherContract.getVoucherData(FIRST_VOUCHER_TOKEN_ID);

          expect(voucherData.tokenId).to.eq(FIRST_VOUCHER_TOKEN_ID);
          expect(voucherData.sbtValue).to.eq(100);
          expect(voucherData.isUsed).to.eq(false);

          await expect(
            bankTreasuryContract.connect(user).exchangeVoucher(FIRST_VOUCHER_TOKEN_ID, SECOND_PROFILE_ID)
          ).to.not.be.reverted;

          expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(100);
        });

        it('Voucher transfer to a new user, and new owner should exchange Voucher SBT', async function () {
          expect((await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY);
          expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(0);
          
          await expect(
            voucherContract.connect(deployer).generateVoucher(1, userAddress)
          ).to.not.be.reverted;

         let voucherData = await voucherContract.getVoucherData(FIRST_VOUCHER_TOKEN_ID);

          expect(voucherData.tokenId).to.eq(FIRST_VOUCHER_TOKEN_ID);
          expect(voucherData.sbtValue).to.eq(100);
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

          expect((await sbtContract['balanceOf(uint256)'](THIRD_PROFILE_ID)).toNumber()).to.eq(100);

          let voucherData2 = await voucherContract.getVoucherData(FIRST_VOUCHER_TOKEN_ID);

          expect(voucherData2.tokenId).to.eq(FIRST_VOUCHER_TOKEN_ID);
          expect(voucherData2.sbtValue).to.eq(100);
          expect(voucherData2.isUsed).to.eq(true);
        });
  
    });

    context('Voucher generate', function () {
        
      it('User should success mint a ERC1155 NFT and transfer SBT to bank treasury', async function () {
        expect((await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY);
        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(0);
        //mint 100Value to user
        await manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, 100);
        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(100);

        expect(await manager.getWalletBySoulBoundTokenId(SECOND_PROFILE_ID)).to.eq(userAddress);

        const tx  = await voucherContract.connect(user).mintNFT(
          SECOND_PROFILE_ID,
          100,
          userAddress,
        );
        console.log('mintNFT ok');

        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(0);
        expect((await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY + 100);
       
      });

    
      it('Should faild to mint a ERC1155 NFT when balance of user is less than 100', async function () {
        expect((await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY);
        
        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(0);

        await expect(
          voucherContract.connect(user).mintNFT(
            SECOND_PROFILE_ID,
            100,
            userAddress,
          )
        ).to.be.revertedWith(ERRORS.ERC3525_INSUFFICIENT_BALANCE);

        expect((await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY);
        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(0);
       

      });

      it('Should faild to mint a ERC1155 NFT when amount is zero', async function () {
        expect((await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY);
        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(0);
        //mint 100Value to user
        await manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, 100);
        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(100);

               
        await expect(
          voucherContract.connect(user).mintNFT(
            SECOND_PROFILE_ID,
            0,
            userAddress,
          )
        ).to.be.revertedWith(ERRORS.AmountSBT_Is_Zero);

        expect((await sbtContract['balanceOf(uint256)'](FIRST_PROFILE_ID)).toNumber()).to.eq(INITIAL_SUPPLY);
        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(100);
       

      });

    });

  });

});
