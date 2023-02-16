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
import { ONE_HOUR, ONE_DAY, ONE_THOUSAND_DAY } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';

import { 
  createProfileReturningTokenId,
  createHubReturningHubId,
  createProjectReturningProjectId,
  matchEvent,
  getTimestamp, 
  waitForTx, 
  findEvent
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
  eventsLib
} from '../../__setup.spec';
import { increaseTimeTo } from '../../helpers/time';

let derivativeNFT: DerivativeNFT;

const Default_royaltyBasisPoints = 50; //
const SALE_ID = 1;
const THIRD_DNFT_TOKEN_ID =3;
const SALE_PRICE = 100;
const OFFER_PRICE = 120;
const reservePrice = 100;
const INITIAL_EARNESTFUNDS = 10000;

let receipt: TransactionReceipt;
let auctionId = 0;

let totalFees:BigNumber;
let creatorRev:BigNumber;
let previousCreatorRev:BigNumber;
let sellerRev:BigNumber;


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

      //let freeBalance = (await bankTreasuryContract['balanceOf(address,uint256)'](sbtContract.address, SECOND_PROFILE_ID)).toNumber();
      //console.log('\n\t-----EarnestFunds balanceOf user, freeBalance:', freeBalance)
      
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
        INITIAL_EARNESTFUNDS
      );
      expect(await bankTreasuryContract['balanceOf(address,uint256)'](sbtContract.address, THIRD_PROFILE_ID)).to.eq(INITIAL_EARNESTFUNDS);
      
      expect(await manager.getWalletBySoulBoundTokenId(SECOND_PROFILE_ID)).to.eq(userAddress);
      expect(await manager.getWalletBySoulBoundTokenId(THIRD_PROFILE_ID)).to.eq(userTwoAddress);
      
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

      await derivativeNFT.connect(user).setApprovalForAll(marketPlaceContract.address, true);
     
  });

  describe("after the auction has ended", () => {
    beforeEach(async () => {
        let freeBalance = (await bankTreasuryContract['balanceOf(address,uint256)'](sbtContract.address, SECOND_PROFILE_ID)).toNumber();
        //console.log('\n\t-----EarnestFunds balanceOf user, freeBalance:', freeBalance)
        
        const freeBalance_userTwo = await bankTreasuryContract['balanceOf(address,uint256)'](sbtContract.address, THIRD_PROFILE_ID);
        //console.log("\n\t-----userTwo freeBalance: ", freeBalance_userTwo);
        const escrowBalance_userTwo = await bankTreasuryContract['escrowBalanceOf(address,uint256)'](sbtContract.address, THIRD_PROFILE_ID)
        //console.log("\t-----userTwo escrowBalance: ", escrowBalance_userTwo);
  
        // Create an auction
        receipt = await waitForTx(
            marketPlaceContract.connect(user).createReserveAuction(
                SECOND_PROFILE_ID,
                derivativeNFT.address, 
                FIRST_DNFT_TOKEN_ID, 
                sbtContract.address,
                reservePrice
            )
        );

        auctionId = (await marketPlaceContract.connect(user).getReserveAuctionIdFor(
            derivativeNFT.address, 
            FIRST_DNFT_TOKEN_ID, 
        )).toNumber();

        await marketPlaceContract.connect(userTwo).placeBid(
            THIRD_PROFILE_ID, //soulBoundTokenIdBidder
            auctionId, 
            reservePrice * 11, 
            0
        );

        //console.log('\n\t getReserveAuctionIdFor, auctionId:', auctionId)

        let auctionInfo = await marketPlaceContract.getReserveAuction(1);

        await increaseTimeTo(auctionInfo.endTime.add(1));
        receipt = await waitForTx(
            marketPlaceContract.connect(user).finalizeReserveAuction(
                auctionId
            )
        );
       });
    
       it("Emits ReserveAuctionFinalized", async () => {
         [totalFees, 
                creatorRev, 
                previousCreatorRev, 
                sellerRev] = await feeCollectModule.getFees(
                    FIRST_PUBLISH_ID, 
                    reservePrice * 11
            );

            // console.log("\n\t --- getFees");
            // console.log("\t\t --- treasuryFee:", totalFees);
            // console.log("\t\t --- creatorAmount:", creatorRev);
            // console.log("\t\t --- previousCreatorAmount:", previousCreatorRev);
            // console.log("\t\t --- adjustedAmount:", sellerRev);


            const event = findEvent(receipt, 'ReserveAuctionFinalized', eventsLib);
            
            // console.log("\t\t--- auctionId: ", event.args.auctionId);
            // console.log("\t\t--- seller: ", event.args.seller);
            // console.log("\t\t--- bidder: ", event.args.bidder);

            expect(event.args.royaltyAmounts.treasuryAmount).to.eq(totalFees);
            expect(event.args.royaltyAmounts.genesisAmount).to.eq(creatorRev);
            expect(event.args.royaltyAmounts.previousAmount).to.eq(previousCreatorRev);
            expect(event.args.royaltyAmounts.referrerAmount).to.eq(0);
            expect(event.args.royaltyAmounts.adjustedAmount).to.eq(sellerRev);
        
        });

        it("dNFT was transferred to the auction winner", async () => {
            expect(
                await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
              ).to.eq(userTwoAddress);
        });

        it("cannot read auction id for this token", async () => {
            expect(await marketPlaceContract.getReserveAuctionIdFor(
                derivativeNFT.address, 
                FIRST_DNFT_TOKEN_ID, 
            )).to.eq(0);
        });

        it("Earnest balance of user and userTwo", async () => {
            let freeBalance = (await bankTreasuryContract['balanceOf(address,uint256)'](sbtContract.address, SECOND_PROFILE_ID)).toNumber();
            //console.log("\n\t-----user freeBalance: ", freeBalance);

            const freeBalance_userTwo = await bankTreasuryContract['balanceOf(address,uint256)'](sbtContract.address, THIRD_PROFILE_ID);
            //console.log("\n\t-----userTwo freeBalance: ", freeBalance_userTwo);
            const escrowBalance_userTwo = await bankTreasuryContract['escrowBalanceOf(address,uint256)'](sbtContract.address, THIRD_PROFILE_ID)
            //console.log("\t-----userTwo escrowBalance: ", escrowBalance_userTwo);

            expect(
                freeBalance
            ).to.eq(creatorRev.toNumber() + sellerRev.toNumber() );
              
        });


  });      

  

});
