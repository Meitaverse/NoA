import { BigNumber } from '@ethersproject/bignumber';
import { parseEther } from '@ethersproject/units';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { 
  ERC20__factory,
  DerivativeNFTV1,
  DerivativeNFTV1__factory,
 } from '../../../typechain';
import { MAX_UINT256, ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';

import { 
  collectReturningTokenId, 
  getTimestamp, 
  matchEvent, 
  waitForTx 
} from '../../helpers/utils';


import {
  abiCoder,
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
  moduleGlobals
  
} from '../../__setup.spec';


import { 
  createProfileReturningTokenId,
  createHubReturningHubId,
  createProjectReturningProjectId,
} from '../../helpers/utils';

let derivativeNFT: DerivativeNFTV1;

makeSuiteCleanRoom('Fee Collect Module', function () {
  const DEFAULT_COLLECT_PRICE = parseEther('10');

  beforeEach(async function () {
    await expect(
      manager.connect(governance).whitelistProfileCreator(userAddress, true)
    ).to.not.be.reverted;

    expect(
      await createProfileReturningTokenId({
          vars: {
          to: userAddress,
          handle: MOCK_PROFILE_HANDLE,
          nickName: NickName,
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
          },
         }) 
      ).to.eq(SECOND_PROFILE_ID);

      expect(await manager.getWalletBySoulBoundTokenId(SECOND_PROFILE_ID)).to.eq(userAddress);


      await expect(
        manager.connect(governance).whitelistProfileCreator(userTwoAddress, true)
      ).to.not.be.reverted;

      // expect(
      //   await createProfileReturningTokenId({
      //       vars: {
      //       to: userTwoAddress,
      //       handle: MOCK_PROFILE_HANDLE,
      //       nickName: NickName3,
      //       imageURI: MOCK_PROFILE_URI,
      //       followModule: ZERO_ADDRESS,
      //       followModuleInitData: [],
      //       followNFTURI: MOCK_FOLLOW_NFT_URI,
      //       },
      //   }) 
      // ).to.eq(THIRD_PROFILE_ID);

      const tokenId = await manager.connect(userTwo).callStatic.createProfile({ 
            to: userTwoAddress,
            handle: MOCK_PROFILE_HANDLE,
            nickName: NickName3,
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
      });
      await expect(manager.connect(userTwo).createProfile({ 
            to: userTwoAddress,
            handle: MOCK_PROFILE_HANDLE,
            nickName: NickName3,
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
      })).to.not.be.reverted;
      expect(tokenId).to.eq(THIRD_PROFILE_ID);

      expect(await manager.getWalletBySoulBoundTokenId(THIRD_PROFILE_ID)).to.eq(userTwoAddress);

      expect(
        await createHubReturningHubId({
          hub: {
            creator: userAddress,
            soulBoundTokenId: SECOND_PROFILE_ID,
            name: "bitsoul",
            description: "Hub for bitsoul",
            image: "image",
          },
        })
    ).to.eq(FIRST_HUB_ID);

    expect(
        await createProjectReturningProjectId({
          project: {
            soulBoundTokenId: SECOND_PROFILE_ID,
            hubId: FIRST_HUB_ID,
            name: "bitsoul",
            description: "Hub for bitsoul",
            image: "image",
            metadataURI: "metadataURI",
            descriptor: metadataDescriptor.address,
          },
        })
    ).to.eq(FIRST_PROJECT_ID);

    derivativeNFT = DerivativeNFTV1__factory.connect(
      await manager.getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );

  });

  context('Negatives', function () {
    context('Publication publish', function () {
      it('user should fail to publish with fee collect module using unwhitelisted currency', async function () {
        const publishModuleinitData = abiCoder.encode(
          ['address', 'uint256'],
          [template.address, DEFAULT_TEMPLATE_NUMBER],
        );

        const collectModuleInitData = abiCoder.encode(
            ['uint256', 'uint16', 'address', 'uint256', 'bool'],
            //userTwoAddress is unwhitelisted currency
            [SECOND_PROFILE_ID, GENESIS_FEE_BPS, userTwoAddress, DEFAULT_COLLECT_PRICE, false]
        );

        await expect(
          manager.connect(user).prePublish({
             soulBoundTokenId: SECOND_PROFILE_ID,
             hubId: FIRST_HUB_ID,
             projectId: FIRST_PROJECT_ID,
             amount: 1,
             name: "Dollar",
             description: "Hand draw",
             materialURIs: [],
             fromTokenIds: [],
             collectModule: feeCollectModule.address,
             collectModuleInitData: collectModuleInitData,
             publishModule: publishModule.address,
             publishModuleInitData: publishModuleinitData,
          })
        ).to.not.be.reverted;

        await expect(
          manager.connect(user).publish(FIRST_PUBLISH_ID)
        ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);

      });

      it('user should fail to publish with fee collect module using zero publishId', async function () {
        const publishModuleinitData = abiCoder.encode(
          ['address', 'uint256'],
          [template.address, DEFAULT_TEMPLATE_NUMBER],
        );

        const collectModuleInitData = abiCoder.encode(
            ['uint256', 'uint16', 'address', 'uint256', 'bool'],
           
            [SECOND_PROFILE_ID, GENESIS_FEE_BPS, ndptAddress, DEFAULT_COLLECT_PRICE, false]
        );

        await expect(
          manager.connect(user).prePublish({
             soulBoundTokenId: SECOND_PROFILE_ID,
             hubId: FIRST_HUB_ID,
             projectId: FIRST_PROJECT_ID,
             amount: 1,
             name: "Dollar",
             description: "Hand draw",
             materialURIs: [],
             fromTokenIds: [],
             collectModule: feeCollectModule.address,
             collectModuleInitData: collectModuleInitData,
             publishModule: publishModule.address,
             publishModuleInitData: publishModuleinitData,
          })
        ).to.not.be.reverted;
        
        await expect(
          manager.connect(user).publish(0)  //0 is publishId
        ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
      });      

      it('user should fail to publish with fee collect module using genesis fee greater than max BPS', async function () {
        const publishModuleinitData = abiCoder.encode(
          ['address', 'uint256'],
          [template.address, DEFAULT_TEMPLATE_NUMBER],
        );

        const collectModuleInitData = abiCoder.encode(
            ['uint256', 'uint16', 'address', 'uint256', 'bool'],
           
            [SECOND_PROFILE_ID, 10000, ndptAddress, DEFAULT_COLLECT_PRICE, false]
        );

        await expect(
          manager.connect(user).prePublish({
             soulBoundTokenId: SECOND_PROFILE_ID,
             hubId: FIRST_HUB_ID,
             projectId: FIRST_PROJECT_ID,
             amount: 1,
             name: "Dollar",
             description: "Hand draw",
             materialURIs: [],
             fromTokenIds: [],
             collectModule: feeCollectModule.address,
             collectModuleInitData: collectModuleInitData,
             publishModule: publishModule.address,
             publishModuleInitData: publishModuleinitData,
          })
        ).to.not.be.reverted;
        
        await expect(
          manager.connect(user).publish(FIRST_PUBLISH_ID) 
        ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
      });      

      it('user should fail to publish with fee collect module with zero amount', async function () {
        const publishModuleinitData = abiCoder.encode(
          ['address', 'uint256'],
          [template.address, DEFAULT_TEMPLATE_NUMBER],
        );

        const collectModuleInitData = abiCoder.encode(
            ['uint256', 'uint16', 'address', 'uint256', 'bool'],
           
            [SECOND_PROFILE_ID, GENESIS_FEE_BPS, ndptAddress, DEFAULT_COLLECT_PRICE, false]
        );

        await expect(
          manager.connect(user).prePublish({
             soulBoundTokenId: SECOND_PROFILE_ID,
             hubId: FIRST_HUB_ID,
             projectId: FIRST_PROJECT_ID,
             amount: 0,
             name: "Dollar",
             description: "Hand draw",
             materialURIs: [],
             fromTokenIds: [],
             collectModule: feeCollectModule.address,
             collectModuleInitData: collectModuleInitData,
             publishModule: publishModule.address,
             publishModuleInitData: publishModuleinitData,
          })
        ).to.be.revertedWith(ERRORS.INVALID_PARAMETER);
        
        // const dNFTTokenId = await manager.connect(user).callStatic.publish(FIRST_PUBLISH_ID);
        // await expect(
        //   manager.connect(user).publish(FIRST_PUBLISH_ID) 
        // ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
      });      

    });

    context('Collecting', function () {
      beforeEach(async function () {
       
        const publishModuleinitData = abiCoder.encode(
          ['address', 'uint256'],
          [template.address, DEFAULT_TEMPLATE_NUMBER],
        );

        const collectModuleInitData = abiCoder.encode(
            ['uint256', 'uint16', 'address', 'uint256', 'bool'],
           
            [SECOND_PROFILE_ID, GENESIS_FEE_BPS, ndptAddress, DEFAULT_COLLECT_PRICE, false]
        );

        await expect(
            manager.connect(user).prePublish({
              soulBoundTokenId: SECOND_PROFILE_ID,
              hubId: FIRST_HUB_ID,
              projectId: FIRST_PROJECT_ID,
              amount: 1,
              name: "Dollar",
              description: "Hand draw",
              materialURIs: [],
              fromTokenIds: [],
              collectModule: feeCollectModule.address,
              collectModuleInitData: collectModuleInitData,
              publishModule: publishModule.address,
              publishModuleInitData: publishModuleinitData,
          })
          ).to.not.be.reverted;

          const dNFTTokenId = await manager.connect(user).callStatic.publish(FIRST_PUBLISH_ID);
          await expect(
            manager.connect(user).publish(FIRST_PUBLISH_ID)
          ).to.not.be.reverted;

          expect(dNFTTokenId).to.eq(FIRST_DNFT_TOKEN_ID);  

          expect(
            await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
          ).to.eq(userAddress);

          expect(
            await derivativeNFT['balanceOf(uint256)'](FIRST_DNFT_TOKEN_ID)
          ).to.eq(1);

          //mint some Values to userTwo
          await manager.connect(governance).mintNDPTValue(THIRD_PROFILE_ID, 1000000000000);
          expect((await ndptContract.balanceOfNDPT(THIRD_PROFILE_ID)).toNumber()).to.eq(1000000000000);

         //userTwo授权给manager合约
          await derivativeNFT['approve(uint256,address,uint256)'](FIRST_DNFT_TOKEN_ID, manager.address, 1);
          
          //查看授权额度是否正确
          expect(
            await derivativeNFT['allowance(uint256,address)'](FIRST_DNFT_TOKEN_ID, manager.address)
          ).to.eq(1);
          
      });

      it('UserTwo should fail to process collect without being the manager', async function () {
        await expect(
          feeCollectModule
            .connect(userTwo)
            .processCollect(SECOND_PROFILE_ID, 4, FIRST_PUBLISH_ID, 1)
        ).to.be.revertedWith(ERRORS.NOT_MANAGER);
      });

      it('Governance should set the treasury fee BPS to zero, user call permit userTwo collecting should not emit a transfer event to the treasury', async function () {
        // await expect(moduleGlobals.connect(governance).setTreasuryFee(0)).to.not.be.reverted;

        /*
        //不开放直接调用transferFrom, 必须通过manager来调用
        const tx = derivativeNFT['transferFrom(uint256,address,uint256)'](FIRST_DNFT_TOKEN_ID, userTwoAddress, 1);
        const receipt = await waitForTx(tx);
        */
          
        expect(
          await collectReturningTokenId({
              vars: {
                publishId: FIRST_PUBLISH_ID,
                collectorSoulBoundTokenId: THIRD_PROFILE_ID,
                collectValue: 1,
              },
          }) 
          ).to.eq(SECOND_DNFT_TOKEN_ID);

   
        // const tx = manager.connect(userTwo).collect(
        //   {
        //     publishId: FIRST_PUBLISH_ID,
        //     collectorSoulBoundTokenId: THIRD_PROFILE_ID,
        //     collectValue: 1,
        //   }
        // );
        // const receipt = await waitForTx(tx);

        expect(
          await derivativeNFT.ownerOf(SECOND_DNFT_TOKEN_ID)
        ).to.eq(userTwoAddress);

        expect(
          await derivativeNFT.connect(userTwo)['balanceOf(uint256)'](SECOND_DNFT_TOKEN_ID)
        ).to.eq(1);

        //After transferFrom, user have zero dNFT
        expect(
          await derivativeNFT['balanceOf(uint256)'](FIRST_DNFT_TOKEN_ID)
        ).to.eq(0);

        // matchEvent(
        //   receipt,
        //   'Transfer',
        //   [userTwoAddress, userAddress, DEFAULT_COLLECT_PRICE],
        //   currency,
        //   currency.address
        // );

      });      

    });

  });

/*
  context('Negatives', function () {
    context('Collecting', function () {
      
      it('UserTwo should mirror the original post, governance should set the treasury fee BPS to zero, userTwo collecting their mirror should not emit a transfer event to the treasury', async function () {
        const secondProfileId = FIRST_PROFILE_ID + 1;
        await expect(
          lensHub.connect(userTwo).createProfile({
            to: userTwoAddress,
            handle: 'usertwo',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).mirror({
            profileId: secondProfileId,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 1,
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: [],
          })
        ).to.not.be.reverted;

        await expect(moduleGlobals.connect(governance).setTreasuryFee(0)).to.not.be.reverted;
        const data = abiCoder.encode(
          ['address', 'uint256'],
          [currency.address, DEFAULT_COLLECT_PRICE]
        );
        await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;

        await expect(currency.mint(userTwoAddress, MAX_UINT256)).to.not.be.reverted;
        await expect(
          currency.connect(userTwo).approve(feeCollectModule.address, MAX_UINT256)
        ).to.not.be.reverted;

        const tx = lensHub.connect(userTwo).collect(secondProfileId, 1, data);
        const receipt = await waitForTx(tx);

        let currencyEventCount = 0;
        for (let log of receipt.logs) {
          if (log.address == currency.address) {
            currencyEventCount++;
          }
        }
        expect(currencyEventCount).to.eq(2);

        const expectedReferralAmount = BigNumber.from(DEFAULT_COLLECT_PRICE)
          .mul(REFERRAL_FEE_BPS)
          .div(BPS_MAX);
        const amount = DEFAULT_COLLECT_PRICE.sub(expectedReferralAmount);

        matchEvent(
          receipt,
          'Transfer',
          [userTwoAddress, userAddress, amount],
          currency,
          currency.address
        );

        matchEvent(
          receipt,
          'Transfer',
          [userTwoAddress, userTwoAddress, expectedReferralAmount],
          currency,
          currency.address
        );
      });

      it('UserTwo should fail to collect without following', async function () {
        const data = abiCoder.encode(
          ['address', 'uint256'],
          [currency.address, DEFAULT_COLLECT_PRICE]
        );
        await expect(
          lensHub.connect(userTwo).collect(FIRST_PROFILE_ID, 1, data)
        ).to.be.revertedWith(ERRORS.FOLLOW_INVALID);
      });

      it('UserTwo should fail to collect passing a different expected price in data', async function () {
        await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;

        const data = abiCoder.encode(
          ['address', 'uint256'],
          [currency.address, DEFAULT_COLLECT_PRICE.div(2)]
        );
        await expect(
          lensHub.connect(userTwo).collect(FIRST_PROFILE_ID, 1, data)
        ).to.be.revertedWith(ERRORS.MODULE_DATA_MISMATCH);
      });

      it('UserTwo should fail to collect passing a different expected currency in data', async function () {
        await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;

        const data = abiCoder.encode(['address', 'uint256'], [userAddress, DEFAULT_COLLECT_PRICE]);
        await expect(
          lensHub.connect(userTwo).collect(FIRST_PROFILE_ID, 1, data)
        ).to.be.revertedWith(ERRORS.MODULE_DATA_MISMATCH);
      });

      it('UserTwo should fail to collect without first approving module with currency', async function () {
        await expect(currency.mint(userTwoAddress, MAX_UINT256)).to.not.be.reverted;

        await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;

        const data = abiCoder.encode(
          ['address', 'uint256'],
          [currency.address, DEFAULT_COLLECT_PRICE]
        );
        await expect(
          lensHub.connect(userTwo).collect(FIRST_PROFILE_ID, 1, data)
        ).to.be.revertedWith(ERRORS.ERC20_INSUFFICIENT_ALLOWANCE);
      });

      it('UserTwo should mirror the original post, fail to collect from their mirror without following the original profile', async function () {
        const secondProfileId = FIRST_PROFILE_ID + 1;
        await expect(
          lensHub.connect(userTwo).createProfile({
            to: userTwoAddress,
            handle: 'usertwo',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).mirror({
            profileId: secondProfileId,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 1,
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: [],
          })
        ).to.not.be.reverted;

        const data = abiCoder.encode(['uint256'], [DEFAULT_COLLECT_PRICE]);
        await expect(lensHub.connect(userTwo).collect(secondProfileId, 1, data)).to.be.revertedWith(
          ERRORS.FOLLOW_INVALID
        );
      });

      it('UserTwo should mirror the original post, fail to collect from their mirror passing a different expected price in data', async function () {
        const secondProfileId = FIRST_PROFILE_ID + 1;
        await expect(
          lensHub.connect(userTwo).createProfile({
            to: userTwoAddress,
            handle: 'usertwo',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).mirror({
            profileId: secondProfileId,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 1,
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: [],
          })
        ).to.not.be.reverted;

        await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;

        const data = abiCoder.encode(
          ['address', 'uint256'],
          [currency.address, DEFAULT_COLLECT_PRICE.div(2)]
        );
        await expect(lensHub.connect(userTwo).collect(secondProfileId, 1, data)).to.be.revertedWith(
          ERRORS.MODULE_DATA_MISMATCH
        );
      });

      it('UserTwo should mirror the original post, fail to collect from their mirror passing a different expected currency in data', async function () {
        const secondProfileId = FIRST_PROFILE_ID + 1;
        await expect(
          lensHub.connect(userTwo).createProfile({
            to: userTwoAddress,
            handle: 'usertwo',
            imageURI: MOCK_PROFILE_URI,
            followModule: ZERO_ADDRESS,
            followModuleInitData: [],
            followNFTURI: MOCK_FOLLOW_NFT_URI,
          })
        ).to.not.be.reverted;
        await expect(
          lensHub.connect(userTwo).mirror({
            profileId: secondProfileId,
            profileIdPointed: FIRST_PROFILE_ID,
            pubIdPointed: 1,
            referenceModuleData: [],
            referenceModule: ZERO_ADDRESS,
            referenceModuleInitData: [],
          })
        ).to.not.be.reverted;

        await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;

        const data = abiCoder.encode(['address', 'uint256'], [userAddress, DEFAULT_COLLECT_PRICE]);
        await expect(lensHub.connect(userTwo).collect(secondProfileId, 1, data)).to.be.revertedWith(
          ERRORS.MODULE_DATA_MISMATCH
        );
      });
    });
  });
*/

/*
  context('Scenarios', function () {
    it('User should post with fee collect module as the collect module and data, correct events should be emitted', async function () {
      const collectModuleInitData = abiCoder.encode(
        ['uint256', 'address', 'address', 'uint16', 'bool'],
        [DEFAULT_COLLECT_PRICE, currency.address, userAddress, REFERRAL_FEE_BPS, true]
      );
      const tx = lensHub.post({
        profileId: FIRST_PROFILE_ID,
        contentURI: MOCK_URI,
        collectModule: feeCollectModule.address,
        collectModuleInitData: collectModuleInitData,
        referenceModule: ZERO_ADDRESS,
        referenceModuleInitData: [],
      });

      const receipt = await waitForTx(tx);

      expect(receipt.logs.length).to.eq(1);
      matchEvent(receipt, 'PostCreated', [
        FIRST_PROFILE_ID,
        1,
        MOCK_URI,
        feeCollectModule.address,
        [collectModuleInitData],
        ZERO_ADDRESS,
        [],
        await getTimestamp(),
      ]);
    });

    it('User should post with the fee collect module as the collect module and data, fetched publication data should be accurate', async function () {
      const collectModuleInitData = abiCoder.encode(
        ['uint256', 'address', 'address', 'uint16', 'bool'],
        [DEFAULT_COLLECT_PRICE, currency.address, userAddress, REFERRAL_FEE_BPS, true]
      );
      await expect(
        lensHub.post({
          profileId: FIRST_PROFILE_ID,
          contentURI: MOCK_URI,
          collectModule: feeCollectModule.address,
          collectModuleInitData: collectModuleInitData,
          referenceModule: ZERO_ADDRESS,
          referenceModuleInitData: [],
        })
      ).to.not.be.reverted;
      const postTimestamp = await getTimestamp();

      const fetchedData = await feeCollectModule.getPublicationData(FIRST_PROFILE_ID, 1);
      expect(fetchedData.amount).to.eq(DEFAULT_COLLECT_PRICE);
      expect(fetchedData.recipient).to.eq(userAddress);
      expect(fetchedData.currency).to.eq(currency.address);
      expect(fetchedData.referralFee).to.eq(REFERRAL_FEE_BPS);
      expect(fetchedData.followerOnly).to.eq(true);
    });

    it('User should post with the fee collect module as the collect module and data, allowing non-followers to collect, user two collects without following, fee distribution is valid', async function () {
      const collectModuleInitData = abiCoder.encode(
        ['uint256', 'address', 'address', 'uint16', 'bool'],
        [DEFAULT_COLLECT_PRICE, currency.address, userAddress, REFERRAL_FEE_BPS, false]
      );
      await expect(
        lensHub.post({
          profileId: FIRST_PROFILE_ID,
          contentURI: MOCK_URI,
          collectModule: feeCollectModule.address,
          collectModuleInitData: collectModuleInitData,
          referenceModule: ZERO_ADDRESS,
          referenceModuleInitData: [],
        })
      ).to.not.be.reverted;

      await expect(currency.mint(userTwoAddress, MAX_UINT256)).to.not.be.reverted;
      await expect(
        currency.connect(userTwo).approve(feeCollectModule.address, MAX_UINT256)
      ).to.not.be.reverted;
      const data = abiCoder.encode(
        ['address', 'uint256'],
        [currency.address, DEFAULT_COLLECT_PRICE]
      );
      await expect(lensHub.connect(userTwo).collect(FIRST_PROFILE_ID, 1, data)).to.not.be.reverted;

      const expectedTreasuryAmount = BigNumber.from(DEFAULT_COLLECT_PRICE)
        .mul(TREASURY_FEE_BPS)
        .div(BPS_MAX);
      const expectedRecipientAmount =
        BigNumber.from(DEFAULT_COLLECT_PRICE).sub(expectedTreasuryAmount);

      expect(await currency.balanceOf(userTwoAddress)).to.eq(
        BigNumber.from(MAX_UINT256).sub(DEFAULT_COLLECT_PRICE)
      );
      expect(await currency.balanceOf(userAddress)).to.eq(expectedRecipientAmount);
      expect(await currency.balanceOf(treasuryAddress)).to.eq(expectedTreasuryAmount);
    });

    it('User should post with the fee collect module as the collect module and data, user two follows, then collects and pays fee, fee distribution is valid', async function () {
      const collectModuleInitData = abiCoder.encode(
        ['uint256', 'address', 'address', 'uint16', 'bool'],
        [DEFAULT_COLLECT_PRICE, currency.address, userAddress, REFERRAL_FEE_BPS, true]
      );
      await expect(
        lensHub.post({
          profileId: FIRST_PROFILE_ID,
          contentURI: MOCK_URI,
          collectModule: feeCollectModule.address,
          collectModuleInitData: collectModuleInitData,
          referenceModule: ZERO_ADDRESS,
          referenceModuleInitData: [],
        })
      ).to.not.be.reverted;

      await expect(currency.mint(userTwoAddress, MAX_UINT256)).to.not.be.reverted;
      await expect(
        currency.connect(userTwo).approve(feeCollectModule.address, MAX_UINT256)
      ).to.not.be.reverted;
      await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
      const data = abiCoder.encode(
        ['address', 'uint256'],
        [currency.address, DEFAULT_COLLECT_PRICE]
      );
      await expect(lensHub.connect(userTwo).collect(FIRST_PROFILE_ID, 1, data)).to.not.be.reverted;

      const expectedTreasuryAmount = BigNumber.from(DEFAULT_COLLECT_PRICE)
        .mul(TREASURY_FEE_BPS)
        .div(BPS_MAX);
      const expectedRecipientAmount =
        BigNumber.from(DEFAULT_COLLECT_PRICE).sub(expectedTreasuryAmount);

      expect(await currency.balanceOf(userTwoAddress)).to.eq(
        BigNumber.from(MAX_UINT256).sub(DEFAULT_COLLECT_PRICE)
      );
      expect(await currency.balanceOf(userAddress)).to.eq(expectedRecipientAmount);
      expect(await currency.balanceOf(treasuryAddress)).to.eq(expectedTreasuryAmount);
    });

    it('User should post with the fee collect module as the collect module and data, user two follows, then collects twice, fee distribution is valid', async function () {
      const collectModuleInitData = abiCoder.encode(
        ['uint256', 'address', 'address', 'uint16', 'bool'],
        [DEFAULT_COLLECT_PRICE, currency.address, userAddress, REFERRAL_FEE_BPS, true]
      );
      await expect(
        lensHub.post({
          profileId: FIRST_PROFILE_ID,
          contentURI: MOCK_URI,
          collectModule: feeCollectModule.address,
          collectModuleInitData: collectModuleInitData,
          referenceModule: ZERO_ADDRESS,
          referenceModuleInitData: [],
        })
      ).to.not.be.reverted;

      await expect(currency.mint(userTwoAddress, MAX_UINT256)).to.not.be.reverted;
      await expect(
        currency.connect(userTwo).approve(feeCollectModule.address, MAX_UINT256)
      ).to.not.be.reverted;
      await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
      const data = abiCoder.encode(
        ['address', 'uint256'],
        [currency.address, DEFAULT_COLLECT_PRICE]
      );
      await expect(lensHub.connect(userTwo).collect(FIRST_PROFILE_ID, 1, data)).to.not.be.reverted;
      await expect(lensHub.connect(userTwo).collect(FIRST_PROFILE_ID, 1, data)).to.not.be.reverted;

      const expectedTreasuryAmount = BigNumber.from(DEFAULT_COLLECT_PRICE)
        .mul(TREASURY_FEE_BPS)
        .div(BPS_MAX);
      const expectedRecipientAmount =
        BigNumber.from(DEFAULT_COLLECT_PRICE).sub(expectedTreasuryAmount);

      expect(await currency.balanceOf(userTwoAddress)).to.eq(
        BigNumber.from(MAX_UINT256).sub(BigNumber.from(DEFAULT_COLLECT_PRICE).mul(2))
      );
      expect(await currency.balanceOf(userAddress)).to.eq(expectedRecipientAmount.mul(2));
      expect(await currency.balanceOf(treasuryAddress)).to.eq(expectedTreasuryAmount.mul(2));
    });

    it('User should post with the fee collect module as the collect module and data, user two mirrors, follows, then collects from their mirror and pays fee, fee distribution is valid', async function () {
      const secondProfileId = FIRST_PROFILE_ID + 1;
      const collectModuleInitData = abiCoder.encode(
        ['uint256', 'address', 'address', 'uint16', 'bool'],
        [DEFAULT_COLLECT_PRICE, currency.address, userAddress, REFERRAL_FEE_BPS, true]
      );

      await expect(
        lensHub.post({
          profileId: FIRST_PROFILE_ID,
          contentURI: MOCK_URI,
          collectModule: feeCollectModule.address,
          collectModuleInitData: collectModuleInitData,
          referenceModule: ZERO_ADDRESS,
          referenceModuleInitData: [],
        })
      ).to.not.be.reverted;

      await expect(
        lensHub.connect(userTwo).createProfile({
          to: userTwoAddress,
          handle: 'usertwo',
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.not.be.reverted;
      await expect(
        lensHub.connect(userTwo).mirror({
          profileId: secondProfileId,
          profileIdPointed: FIRST_PROFILE_ID,
          pubIdPointed: 1,
          referenceModuleData: [],
          referenceModule: ZERO_ADDRESS,
          referenceModuleInitData: [],
        })
      ).to.not.be.reverted;

      await expect(currency.mint(userTwoAddress, MAX_UINT256)).to.not.be.reverted;
      await expect(
        currency.connect(userTwo).approve(feeCollectModule.address, MAX_UINT256)
      ).to.not.be.reverted;
      await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
      const data = abiCoder.encode(
        ['address', 'uint256'],
        [currency.address, DEFAULT_COLLECT_PRICE]
      );
      await expect(lensHub.connect(userTwo).collect(secondProfileId, 1, data)).to.not.be.reverted;

      const expectedTreasuryAmount = BigNumber.from(DEFAULT_COLLECT_PRICE)
        .mul(TREASURY_FEE_BPS)
        .div(BPS_MAX);
      const expectedReferralAmount = BigNumber.from(DEFAULT_COLLECT_PRICE)
        .sub(expectedTreasuryAmount)
        .mul(REFERRAL_FEE_BPS)
        .div(BPS_MAX);
      const expectedReferrerAmount = BigNumber.from(MAX_UINT256)
        .sub(DEFAULT_COLLECT_PRICE)
        .add(expectedReferralAmount);
      const expectedRecipientAmount = BigNumber.from(DEFAULT_COLLECT_PRICE)
        .sub(expectedTreasuryAmount)
        .sub(expectedReferralAmount);

      expect(await currency.balanceOf(userTwoAddress)).to.eq(expectedReferrerAmount);
      expect(await currency.balanceOf(userAddress)).to.eq(expectedRecipientAmount);
      expect(await currency.balanceOf(treasuryAddress)).to.eq(expectedTreasuryAmount);
    });

    it('User should post with the fee collect module as the collect module and data, with no referral fee, user two mirrors, follows, then collects from their mirror and pays fee, fee distribution is valid', async function () {
      const secondProfileId = FIRST_PROFILE_ID + 1;
      const collectModuleInitData = abiCoder.encode(
        ['uint256', 'address', 'address', 'uint16', 'bool'],
        [DEFAULT_COLLECT_PRICE, currency.address, userAddress, 0, true]
      );

      await expect(
        lensHub.post({
          profileId: FIRST_PROFILE_ID,
          contentURI: MOCK_URI,
          collectModule: feeCollectModule.address,
          collectModuleInitData: collectModuleInitData,
          referenceModule: ZERO_ADDRESS,
          referenceModuleInitData: [],
        })
      ).to.not.be.reverted;

      await expect(
        lensHub.connect(userTwo).createProfile({
          to: userTwoAddress,
          handle: 'usertwo',
          imageURI: MOCK_PROFILE_URI,
          followModule: ZERO_ADDRESS,
          followModuleInitData: [],
          followNFTURI: MOCK_FOLLOW_NFT_URI,
        })
      ).to.not.be.reverted;
      await expect(
        lensHub.connect(userTwo).mirror({
          profileId: secondProfileId,
          profileIdPointed: FIRST_PROFILE_ID,
          pubIdPointed: 1,
          referenceModuleData: [],
          referenceModule: ZERO_ADDRESS,
          referenceModuleInitData: [],
        })
      ).to.not.be.reverted;

      await expect(currency.mint(userTwoAddress, MAX_UINT256)).to.not.be.reverted;
      await expect(
        currency.connect(userTwo).approve(feeCollectModule.address, MAX_UINT256)
      ).to.not.be.reverted;
      await expect(lensHub.connect(userTwo).follow([FIRST_PROFILE_ID], [[]])).to.not.be.reverted;
      const data = abiCoder.encode(
        ['address', 'uint256'],
        [currency.address, DEFAULT_COLLECT_PRICE]
      );
      await expect(lensHub.connect(userTwo).collect(secondProfileId, 1, data)).to.not.be.reverted;

      const expectedTreasuryAmount = BigNumber.from(DEFAULT_COLLECT_PRICE)
        .mul(TREASURY_FEE_BPS)
        .div(BPS_MAX);
      const expectedRecipientAmount =
        BigNumber.from(DEFAULT_COLLECT_PRICE).sub(expectedTreasuryAmount);

      expect(await currency.balanceOf(userTwoAddress)).to.eq(
        BigNumber.from(MAX_UINT256).sub(DEFAULT_COLLECT_PRICE)
      );
      expect(await currency.balanceOf(userAddress)).to.eq(expectedRecipientAmount);
      expect(await currency.balanceOf(treasuryAddress)).to.eq(expectedTreasuryAmount);
    });
  });
*/
});
