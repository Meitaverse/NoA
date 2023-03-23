import { BigNumber } from '@ethersproject/bignumber';
import { parseEther } from '@ethersproject/units';
import '@nomiclabs/hardhat-ethers';
import { TransactionReceipt, TransactionResponse } from '@ethersproject/providers';
import { expect } from 'chai';
import { 
  ERC20__factory,
  DerivativeNFT,
  DerivativeNFT__factory,
 } from '../../../typechain';
import { MAX_UINT256, ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';

import { 
  createProfileReturningTokenId,
  createHubReturningHubId,
  createProjectReturningProjectId,
  matchEvent,
  getTimestamp, 
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
  bankTreasuryContract,
  marketPlaceContract
} from '../../__setup.spec';
import { getEarnestFundsExpectedExpiration } from '../../helpers/earnestFunds';

let derivativeNFT: DerivativeNFT;

const Default_royaltyBasisPoints = 50; //
const SALE_PRICE = 100;
const INITIAL_EARNESTFUNDS = 10000;

let receipt: TransactionReceipt;
let expiry: number;

makeSuiteCleanRoom('Market Place', function () {

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
             
      //user buy some SBT Values 
      await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: INITIAL_EARNESTFUNDS * 10});
      await bankTreasuryContract.connect(user).deposit(
        SECOND_PROFILE_ID,
        sbtContract.address,
        INITIAL_EARNESTFUNDS
      );

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

      await bankTreasuryContract.connect(userTwo).buySBT(THIRD_PROFILE_ID, {value: INITIAL_EARNESTFUNDS * 10});
      
      // @notice MUST deposit SBT value into bank treasury before buy
      await bankTreasuryContract.connect(userTwo).deposit(
        THIRD_PROFILE_ID,
        sbtContract.address,
        1100
      );
      
      expect(
        await bankTreasuryContract['balanceOf(address,uint256)'](
            sbtContract.address, 
            THIRD_PROFILE_ID)
       ).to.eq(1100);
      
      expect(
        await createHubReturningHubId({
          sender: user,
          hub: {
            soulBoundTokenId: SECOND_PROFILE_ID,
            name: "bitsoul",
            description: "Hub for bitsoul",
            imageURI: "image",
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
            defaultRoyaltyPoints: 0,
            permitByHubOwner: false
          },
        })
    ).to.eq(FIRST_PROJECT_ID);
    
    let projectInfo = await manager.connect(user).getProjectInfo(FIRST_PROJECT_ID);
    expect(projectInfo.soulBoundTokenId).to.eq(SECOND_PROFILE_ID);
    expect(projectInfo.hubId).to.eq(FIRST_HUB_ID);
    expect(projectInfo.name).to.eq("bitsoul");
    expect(projectInfo.description).to.eq("Hub for bitsoul");
    expect(projectInfo.image).to.eq("image");
    expect(projectInfo.metadataURI).to.eq("metadataURI");
    expect(projectInfo.descriptor.toUpperCase()).to.eq(metadataDescriptor.address.toUpperCase());

    derivativeNFT = DerivativeNFT__factory.connect(
      await manager.getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );
      
    await expect(
        marketPlaceContract.connect(governance).addMarket(
          derivativeNFT.address,
          FIRST_PROJECT_ID,
          feeCollectModule.address,
          0,
          0,
          50,
        )
    ).to.not.be.reverted;

    const publishModuleinitData = abiCoder.encode(
      ['address', 'uint256'],
      [template.address, DEFAULT_TEMPLATE_NUMBER],
    );

    const collectLimitPerAddress = 0; // 0 表示不限制每个地址能collect的次数

    const utcTimestamp = 0

    const collectModuleInitData = abiCoder.encode(
        ['uint256', 'uint16', 'uint16', 'uint32'],
        [DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints, collectLimitPerAddress, utcTimestamp]
    );

    await expect(
        manager.connect(user).prePublish({
          soulBoundTokenId: SECOND_PROFILE_ID,
          hubId: FIRST_HUB_ID,
          projectId: FIRST_PROJECT_ID,
          currency: sbtContract.address,
          amount: 11,
          salePrice: DEFAULT_COLLECT_PRICE,
          royaltyBasisPoints: Default_royaltyBasisPoints,              
          name: "Dollar",
          description: "Hand draw",
          canCollect: true,
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

      // approval market contract
      await derivativeNFT.connect(user).setApprovalForAll(marketPlaceContract.address, true);
      
  });


  context('On `makeOffer`', function () {
    beforeEach(async function () {
        receipt = await waitForTx(
            marketPlaceContract.connect(userTwo).makeOffer(
            {
                soulBoundTokenIdBuyer: THIRD_PROFILE_ID,
                derivativeNFT: derivativeNFT.address, 
                tokenId: FIRST_DNFT_TOKEN_ID, 
                currency: sbtContract.address,
                amount: SALE_PRICE * 11,
                soulBoundTokenIdReferrer:0,
            })
        );
        // await
        //     marketPlaceContract.connect(userTwo).makeOffer(
        //     {
        //         soulBoundTokenIdBuyer: THIRD_PROFILE_ID,
        //         derivativeNFT: derivativeNFT.address, 
        //         tokenId: FIRST_DNFT_TOKEN_ID, 
        //         currency: sbtContract.address,
        //         amount: SALE_PRICE * 11,
        //         soulBoundTokenIdReferrer:0,
        //     }
        // );

       expiry = await getEarnestFundsExpectedExpiration(receipt);
       
    });

    it("Emits OfferMade", async () => {

        matchEvent(
            receipt,
            'OfferMade',
            [
                derivativeNFT.address, 
                FIRST_DNFT_TOKEN_ID,
                11,
                userTwoAddress,
                sbtContract.address,
                SALE_PRICE * 11,
                expiry
            ],
        );
    });

    it("userTwo has total balance", async () => {
        const totalBalance = await bankTreasuryContract['totalBalanceOf(address,uint256)'](sbtContract.address, THIRD_PROFILE_ID)
        expect(totalBalance).to.eq(SALE_PRICE * 11);

      });

    it("useTwo has 0 available free balance", async () => {
        expect(
          await bankTreasuryContract['balanceOf(address,uint256)'](
              sbtContract.address, 
              THIRD_PROFILE_ID)
         ).to.eq(0);

      });
      
    it("useTwo has correct escrow balance", async () => {
        const escrowBalance = await bankTreasuryContract['escrowBalanceOf(address,uint256)'](sbtContract.address, THIRD_PROFILE_ID)
        expect(escrowBalance).to.eq(SALE_PRICE * 11);
      });


      it("Has a token lockup", async () => {
        const lockups = await bankTreasuryContract.getLockups(sbtContract.address, THIRD_PROFILE_ID);
        expect(lockups.amounts[0]).to.eq(SALE_PRICE * 11);
        expect(lockups.expiries[0]).to.eq(expiry);
      });

  });
  

});
