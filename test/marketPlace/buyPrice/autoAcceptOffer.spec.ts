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

let derivativeNFT: DerivativeNFT;

const Default_royaltyBasisPoints = 50; //
const SALE_ID = 1;
const THIRD_DNFT_TOKEN_ID =3;
const SALE_PRICE = 100;
const OFFER_PRICE = 120;
const INITIAL_EARNESTFUNDS = 10000;

let receipt: TransactionReceipt;

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
            feeShareType: 0, //Level two
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
      
      // Or approve market contract for token #1
      // await derivativeNFT.connect(user)['approve(address,uint256)'](marketPlaceContract.address, FIRST_DNFT_TOKEN_ID);
       
      // Make an offer for greater than the buy price we will set
       await marketPlaceContract.connect(userTwo).makeOffer(
        {
          soulBoundTokenIdBuyer: THIRD_PROFILE_ID,
          derivativeNFT: derivativeNFT.address, 
          tokenId: FIRST_DNFT_TOKEN_ID, 
          currency: sbtContract.address,
          amount: OFFER_PRICE * 11,
          soulBoundTokenIdReferrer:0,
        }
       );
  });

  context('On `setBuyPrice`', function () {
    beforeEach(async function () {
 
      receipt = await waitForTx(
         marketPlaceContract.connect(user).setBuyPrice({
            soulBoundTokenId: SECOND_PROFILE_ID,
            derivativeNFT: derivativeNFT.address,
            tokenId: FIRST_DNFT_TOKEN_ID,
            currency: sbtContract.address,
            salePrice: SALE_PRICE,
        })
      );

      // await waitForTx(
      //     marketPlaceContract.connect(user).setBuyPrice({
      //     soulBoundTokenId: SECOND_PROFILE_ID,
      //     derivativeNFT: derivativeNFT.address,
      //     tokenId: FIRST_DNFT_TOKEN_ID,
      //     currency: sbtContract.address,
      //     salePrice: SALE_PRICE,
      //   })
      // );
    });
    
    it('User should success to setBuyPrice', async function () {
      
        expect(
          await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
        ).to.eq(userTwoAddress);
    });
    
    it("Emits OfferAccepted", async () => {
    
      const event = findEvent(receipt, 'OfferAccepted', eventsLib);
      console.log(
        "\n\t--- setBuyPrice success! Event OfferAccepted emited ..."
      );
      console.log(
        "\t\t--- derivativeNFT: ", event.args.derivativeNFT
      );
      console.log(
        "\t\t--- tokenId: ", event.args.tokenId
      );
      console.log(
        "\t\t--- buyer: ", event.args.buyer
      );
      console.log(
        "\t\t--- seller: ", event.args.seller
      );
      console.log(
        "\t\t--- currency: ", event.args.currency
      );
      console.log(
        "\t\t--- treasuryAmount: ", event.args.royaltyAmounts.treasuryAmount
      );
      console.log(
        "\t\t--- genesisAmount: ", event.args.royaltyAmounts.genesisAmount
      );
      console.log(
        "\t\t--- previousAmount: ", event.args.royaltyAmounts.previousAmount
      );
      console.log(
        "\t\t--- referrerAmount: ", event.args.royaltyAmounts.referrerAmount
      );
      console.log(
        "\t\t--- adjustedAmount: ", event.args.royaltyAmounts.adjustedAmount
      );

      expect( FIRST_DNFT_TOKEN_ID ).to.eq(event.args.tokenId.toNumber());

    });
    

    it("Owner of new token id", async () => {
        expect(
            await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
        ).to.eq(userTwoAddress); //userTwo

    });
    

  });
  

});
