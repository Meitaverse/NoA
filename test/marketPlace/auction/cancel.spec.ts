import { BigNumber } from '@ethersproject/bignumber';
import { parseEther } from '@ethersproject/units';
import '@nomiclabs/hardhat-ethers';
import { constants } from "ethers";
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
  waitForTx 
} from '../../helpers/utils';

import {
  abiCoder,
  SECOND_PROFILE_ID,
  THIRD_PROFILE_ID,
  FIRST_HUB_ID,
  FIRST_PROJECT_ID,
  FIRST_DNFT_TOKEN_ID,
  FIRST_PUBLISH_ID,
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

let derivativeNFT: DerivativeNFT;

const Default_royaltyBasisPoints = 50; //
const SALE_PRICE = 100;
const INITIAL_EARNESTFUNDS = 10000;

let receipt: TransactionReceipt;
let auctionId = 0;

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
        INITIAL_EARNESTFUNDS
      );
      
      expect(await bankTreasuryContract['balanceOf(address,uint256)'](sbtContract.address, THIRD_PROFILE_ID)).to.eq(INITIAL_EARNESTFUNDS);
      
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
      ['uint256', 'uint16', 'uint16'],
      [DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints, 0]
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
     
      // Create an auction
      await waitForTx(
            marketPlaceContract.connect(user).createReserveAuction(
                SECOND_PROFILE_ID,
                derivativeNFT.address, 
                FIRST_DNFT_TOKEN_ID, 
                sbtContract.address,
                SALE_PRICE
            )
      );

      auctionId = (await marketPlaceContract.connect(user).getReserveAuctionIdFor(
        derivativeNFT.address, 
        FIRST_DNFT_TOKEN_ID, 
      )).toNumber();

      console.log('\n\t getReserveAuctionIdFor, auctionId:', auctionId)
           
      let info = await marketPlaceContract.getReserveAuction(1);
      console.log('\n\t getReserveAuction')
      console.log('\t\t  --- soulBoundTokenId:', info.soulBoundTokenId)
      console.log('\t\t  --- derivativeNFT:', info.derivativeNFT)
      console.log('\t\t  --- projectId:', info.projectId)
      console.log('\t\t  --- publishId:', info.publishId)
      console.log('\t\t  --- tokenId:', info.tokenId)
      console.log('\t\t  --- seller:', info.seller)
      console.log('\t\t  --- units:', info.units)
   
      receipt = await waitForTx(
        marketPlaceContract.connect(user).cancelReserveAuction(
          auctionId
        )
      );

      // await marketPlaceContract.connect(user).cancelReserveAuction(
      //   auctionId
      // );
 
 
  });


  context('Should cancel auction', function () {
    
    it("Emits ReserveAuctionCanceled", async () => {

      matchEvent(
        receipt,
        'ReserveAuctionCanceled',
        [
            auctionId,
        ],
      );
    });

    it("The DNFT has been returned to the creator", async () => {
        expect(
            await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
          ).to.eq(userAddress);
    });

    it("Can not read auction info", async () => {
      let auctionInfo = await marketPlaceContract.getReserveAuction(auctionId);
     
      expect(auctionInfo.derivativeNFT).to.eq(constants.AddressZero);
      expect(auctionInfo.tokenId).to.eq(0);
      expect(auctionInfo.seller).to.eq(constants.AddressZero);
      expect(auctionInfo.endTime).to.eq(0);
      expect(auctionInfo.bidder).to.eq(constants.AddressZero);
      expect(auctionInfo.amount).to.eq(0);

    });

  });
  

});
