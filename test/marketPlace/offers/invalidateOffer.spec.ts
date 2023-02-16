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
  marketPlaceContract,
  userThree,
  userThreeAddress,
  NickName2
} from '../../__setup.spec';
import { ContractTransaction, ethers } from 'ethers';
import { getEarnestFundsExpectedExpiration } from '../../helpers/earnestFunds';

let derivativeNFT: DerivativeNFT;

const Default_royaltyBasisPoints = 50; //
const SALE_ID = 1;
const THIRD_DNFT_TOKEN_ID =3;
const SALE_PRICE = 100;
const OFFER_PRICE = 120;
const BID_PRICE = 110;
const INITIAL_EARNESTFUNDS = 10000;

let receipt: TransactionReceipt;
let expiry: number;
let auctionId =1;

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
            nickName: NickName2,
            imageURI: MOCK_PROFILE_URI,
            },
          }) 
        ).to.eq(THIRD_PROFILE_ID);

      await bankTreasuryContract.connect(userTwo).buySBT(THIRD_PROFILE_ID, {value: INITIAL_EARNESTFUNDS * 10});
      
      // @notice MUST deposit SBT value into bank treasury before buy
       await bankTreasuryContract.connect(userTwo).deposit(
        THIRD_PROFILE_ID,
        sbtContract.address,
        INITIAL_EARNESTFUNDS
      );
      expect(
        await bankTreasuryContract['balanceOf(address,uint256)'](
            sbtContract.address, 
            THIRD_PROFILE_ID)
      ).to.eq(INITIAL_EARNESTFUNDS);

      //registed userThree
      expect(
        await createProfileReturningTokenId({
            sender: userThree,
            vars: {
                wallet: userThreeAddress,
                nickName: NickName3,
                imageURI: MOCK_PROFILE_URI,
            },
          }) 
        ).to.eq(FOUR_PROFILE_ID);

      await bankTreasuryContract.connect(userThree).buySBT(FOUR_PROFILE_ID, {value: INITIAL_EARNESTFUNDS * 10});
      
      // @notice MUST deposit SBT value into bank treasury before buy
       await bankTreasuryContract.connect(userThree).deposit(
        FOUR_PROFILE_ID,
        sbtContract.address,
        INITIAL_EARNESTFUNDS
      );
      expect(
        await bankTreasuryContract['balanceOf(address,uint256)'](
            sbtContract.address, 
            FOUR_PROFILE_ID)
      ).to.eq(INITIAL_EARNESTFUNDS);

      
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

    const collectModuleInitData = abiCoder.encode(
        ['uint256', 'uint16', 'uint256', 'uint256'],
       
        [SECOND_PROFILE_ID, GENESIS_FEE_BPS, DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints]
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

      // Make an offer to accept
      receipt = await waitForTx(
         marketPlaceContract.connect(userTwo).makeOffer(
         {
            soulBoundTokenIdBuyer: THIRD_PROFILE_ID,
            derivativeNFT: derivativeNFT.address, 
            tokenId: FIRST_DNFT_TOKEN_ID, 
            currency: sbtContract.address,
            amount: SALE_PRICE * 11,
            soulBoundTokenIdReferrer: 0,
         })
      );

      expiry = await getEarnestFundsExpectedExpiration(receipt);

       // Create an auction to invalidate the offer
       await marketPlaceContract.connect(user).createReserveAuction(
            SECOND_PROFILE_ID,
            derivativeNFT.address, 
            FIRST_DNFT_TOKEN_ID, 
            sbtContract.address,
            SALE_PRICE
        );
        
        // The offer is still valid when there is a reserve price
        const offer = await marketPlaceContract.getOffer(derivativeNFT.address, FIRST_DNFT_TOKEN_ID);
        expect(offer.amount).to.eq(SALE_PRICE * 11);
       
  });

  context('Invalidate on auction start', function () {
    beforeEach(async function () {
        // When a bid is placed by userThree, the dNFT is reserved for the winner of the auction
        receipt = await waitForTx(
            marketPlaceContract.connect(userThree).placeBid(
                FOUR_PROFILE_ID, //soulBoundTokenIdBidder
                auctionId, 
                SALE_PRICE * 11, 
                0
            )
        );

    });

    it("Emits OfferInvalidated", async () => {

        matchEvent(
            receipt,
            'OfferInvalidated',
            [
                derivativeNFT.address, 
                FIRST_DNFT_TOKEN_ID
            ],
        );
    });

    it("The EarnestFunds balance is now available for use", async () => {

      const auctionInfo = await marketPlaceContract.getReserveAuction(auctionId);
      // console.log("\n\t-----getReserveAuction: ");
      // console.log("\t\t-----auctionInfo.soulBoundTokenId: ", auctionInfo.soulBoundTokenId);
      // console.log("\t\t-----auctionInfo.soulBoundTokenIdBidder: ", auctionInfo.soulBoundTokenIdBidder);
      // console.log("\t\t-----auctionInfo.reservePrice: ", auctionInfo.reservePrice);
      // console.log("\t\t-----auctionInfo.units: ", auctionInfo.units);
      // console.log("\t\t-----auctionInfo.amount: ", auctionInfo.amount);

      const freeBalance_userTwo = await bankTreasuryContract['balanceOf(address,uint256)'](sbtContract.address, THIRD_PROFILE_ID);
      // console.log("\n\t\t-----userTwo freeBalance: ", freeBalance_userTwo);
      const escrowBalance_userTwo = await bankTreasuryContract['escrowBalanceOf(address,uint256)'](sbtContract.address, THIRD_PROFILE_ID)
      // console.log("\t\t-----userTwo escrowBalance: ", escrowBalance_userTwo);

      const freeBalance_userThree = await bankTreasuryContract['balanceOf(address,uint256)'](sbtContract.address, FOUR_PROFILE_ID);
      // console.log("\n\t\t-----userThree freeBalance: ", freeBalance_userThree);
      const escrowBalance_userThree = await bankTreasuryContract['escrowBalanceOf(address,uint256)'](sbtContract.address, FOUR_PROFILE_ID)
      // console.log("\t\t-----userThree escrowBalance: ", escrowBalance_userThree);

      expect(freeBalance_userTwo).to.eq(INITIAL_EARNESTFUNDS);
      expect(escrowBalance_userTwo).to.eq(0);
      expect(freeBalance_userThree).to.eq(INITIAL_EARNESTFUNDS - (SALE_PRICE * 11));
      expect(escrowBalance_userThree).to.eq(0);
    });
  
      it("Token lockup does not apply", async () => {
        const lockups = await bankTreasuryContract.getLockups(sbtContract.address, THIRD_PROFILE_ID);
        expect(lockups.amounts.length).to.eq(0);
      });

      it("The offer is no longer found", async () => {
        const offer = await marketPlaceContract.getOffer(derivativeNFT.address, FIRST_DNFT_TOKEN_ID);
        expect(offer.amount).to.eq(0);
        expect(offer.buyer).to.eq(ethers.constants.AddressZero);
      });
  });
  

});
