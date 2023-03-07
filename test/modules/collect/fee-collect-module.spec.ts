import { BigNumber } from '@ethersproject/bignumber';
import { parseEther } from '@ethersproject/units';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { 
  ERC20__factory,
  DerivativeNFT,
  DerivativeNFT__factory,
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
  bankTreasuryContract
  
} from '../../__setup.spec';


import { 
  createProfileReturningTokenId,
  createHubReturningHubId,
  createProjectReturningProjectId,
} from '../../helpers/utils';

let derivativeNFT: DerivativeNFT;

makeSuiteCleanRoom('Fee Collect Module', function () {
  const DEFAULT_COLLECT_PRICE = 10000; // in wei 10000;
  const Default_royaltyBasisPoints = 50; //

  beforeEach(async function () {

    expect(
      await createProfileReturningTokenId({
          vars: {
          wallet: userAddress,
          nickName: NickName,
          imageURI: MOCK_PROFILE_URI,
          },
         }) 
      ).to.eq(SECOND_PROFILE_ID);

      expect(await manager.getWalletBySoulBoundTokenId(SECOND_PROFILE_ID)).to.eq(userAddress);
       
      //user buy some SBT Values 
      await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: 10000});

      const tokenId = await manager.connect(userTwo).callStatic.createProfile({ 
            wallet: userTwoAddress,
            nickName: NickName3,
            imageURI: MOCK_PROFILE_URI,
      });
      
      await expect(manager.connect(userTwo).createProfile({ 
            wallet: userTwoAddress,
            nickName: NickName3,
            imageURI: MOCK_PROFILE_URI,
      })).to.not.be.reverted;
      expect(tokenId).to.eq(THIRD_PROFILE_ID);

      expect(await manager.getWalletBySoulBoundTokenId(THIRD_PROFILE_ID)).to.eq(userTwoAddress);

      //mint some Values to userTwo
      await bankTreasuryContract.connect(userTwo).buySBT(THIRD_PROFILE_ID, {value: 10000});
        

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

    derivativeNFT = DerivativeNFT__factory.connect(
      await manager.getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );

  });

  context('Negatives', function () {
    context('Publication publish', function () {
      
      it('user should fail to publish with fee collect module using zero publishId', async function () {
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
             amount: 1,
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
        
        await expect(
          manager.connect(user).publish(0)  //0 is publishId
        ).to.be.revertedWith(ERRORS.PROJECT_ID_INVALID);
      });      

      

      it('user should fail to publish with fee collect module with zero amount', async function () {
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
             amount: 0,
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
        ).to.be.revertedWith(ERRORS.INVALID_PARAMETER);
        
      });      

    });

    context('Collecting', function () {
      beforeEach(async function () {

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
              amount: 1,
              salePrice: DEFAULT_COLLECT_PRICE,
              royaltyBasisPoints: GENESIS_FEE_BPS,              
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
          
          let fetchedData = await feeCollectModule.getPublicationData(FIRST_PUBLISH_ID);
          expect(fetchedData.genesisFee).to.eq(GENESIS_FEE_BPS);
          expect(fetchedData.salePrice).to.eq(DEFAULT_COLLECT_PRICE);
          expect(fetchedData.royaltyBasisPoints).to.eq(Default_royaltyBasisPoints);

          expect(
            await derivativeNFT['balanceOf(uint256)'](FIRST_DNFT_TOKEN_ID)
          ).to.eq(1);
      });

      it('UserTwo should fail to process collect without being the manager', async function () {
        await expect(
          feeCollectModule
            .connect(userTwo)
            .processCollect(SECOND_PROFILE_ID, 4, FIRST_PUBLISH_ID, 1, [])
        ).to.be.revertedWith(ERRORS.NOT_MANAGER);
      });

      it('Governance should set the treasury fee BPS to zero, userTwo call permit userTwo collecting should not emit a transfer event to the treasury', async function () {
        await expect(moduleGlobals.connect(governance).setTreasuryFee(0)).to.not.be.reverted;

          
        let [totalFees, 
            creatorRev, 
            previousCreatorRev, 
            sellerRev] = await feeCollectModule.getFees(
                FIRST_PUBLISH_ID, 
                DEFAULT_COLLECT_PRICE
        );

        console.log("\n\t --- getFees");
        console.log("\t\t --- treasuryFee:", totalFees);
        console.log("\t\t --- creatorAmount:", creatorRev);
        console.log("\t\t --- previousCreatorAmount:", previousCreatorRev);
        console.log("\t\t --- adjustedAmount:", sellerRev);

        const tx = manager.connect(userTwo).collect({
            publishId: FIRST_PUBLISH_ID,
            collectorSoulBoundTokenId: THIRD_PROFILE_ID,
            collectUnits: 1,
            data: [],
        });
        const receipt = await waitForTx(tx);

        matchEvent(
          receipt,
          'TransferValue',
          [FIRST_DNFT_TOKEN_ID, SECOND_DNFT_TOKEN_ID, 1],
          derivativeNFT,
          derivativeNFT.address
        );

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


      });         

      it('User collecting a dNFT and pay to the treasury', async function () {
        
        let [totalFees, 
          creatorRev, 
          previousCreatorRev, 
          sellerRev] = await feeCollectModule.getFees(
              FIRST_PUBLISH_ID, 
              DEFAULT_COLLECT_PRICE
        );

        console.log("\n\t --- getFees");
        console.log("\t\t --- treasuryFee:", totalFees);
        console.log("\t\t --- creatorAmount:", creatorRev);
        console.log("\t\t --- previousCreatorAmount:", previousCreatorRev);
        console.log("\t\t --- adjustedAmount:", sellerRev);

        // expect(
        //   await collectReturningTokenId({
        //       sender: userTwo,
        //       vars: {
        //         publishId: FIRST_PUBLISH_ID,
        //         collectorSoulBoundTokenId: THIRD_PROFILE_ID,
        //         collectUnits: 1,
        //         data : [],
        //       },
        //   }) 
        //   ).to.eq(SECOND_DNFT_TOKEN_ID);

        await  manager.connect(userTwo).collect({
            publishId: FIRST_PUBLISH_ID,
            collectorSoulBoundTokenId: THIRD_PROFILE_ID,
            collectUnits: 1,
            data: [],
        });

        expect(
          await derivativeNFT.ownerOf(SECOND_DNFT_TOKEN_ID)
        ).to.eq(userTwoAddress);

        expect(
          await derivativeNFT.connect(userTwo)['balanceOf(uint256)'](SECOND_DNFT_TOKEN_ID)
        ).to.eq(1);

        //After transferFrom, user have zero dNFT unit
        expect(
          await derivativeNFT['balanceOf(uint256)'](FIRST_DNFT_TOKEN_ID)
        ).to.eq(0); 


      });         
   
    });

    context('Airdrop', function () {
      beforeEach(async function () {
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

          expect(
            await derivativeNFT['balanceOf(uint256)'](FIRST_DNFT_TOKEN_ID)
          ).to.eq(11);

  
      });

      it('Should success to airdrop ', async function () {
        
        expect(
          await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
        ).to.eq(userAddress);

        await expect(
          manager.connect(user).airdrop({
          publishId: FIRST_PROJECT_ID,
          ownershipSoulBoundTokenId: SECOND_PROFILE_ID,
          toSoulBoundTokenIds: [THIRD_PROFILE_ID],
          tokenId: FIRST_DNFT_TOKEN_ID,
          values: [1],
        })
        ).to.not.be.reverted;

        expect(
          await derivativeNFT.ownerOf(SECOND_DNFT_TOKEN_ID)
        ).to.eq(userTwoAddress);

        expect(
          await derivativeNFT['balanceOf(uint256)'](FIRST_DNFT_TOKEN_ID)
        ).to.eq(10);

        expect(
          await derivativeNFT['balanceOf(uint256)'](SECOND_DNFT_TOKEN_ID)
        ).to.eq(1);
      });      

      
      it('Should fail to airdrop when amount is exceed', async function () {
        
        expect(
          await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
        ).to.eq(userAddress);

        await expect(manager.connect(user).airdrop({
          publishId: FIRST_PROJECT_ID,
          ownershipSoulBoundTokenId: SECOND_PROFILE_ID,
          toSoulBoundTokenIds: [THIRD_PROFILE_ID],
          tokenId: FIRST_DNFT_TOKEN_ID,
          values: [100],
        })).to.be.revertedWith(ERRORS.ERC3525INSUFFICIENTBALANCE);

        expect(
          await derivativeNFT['balanceOf(uint256)'](FIRST_DNFT_TOKEN_ID)
        ).to.eq(11);
      });      
         
    });
    
    context('DerivativeNFT transfer', function () {
      beforeEach(async function () {

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

          expect(
            await derivativeNFT['balanceOf(uint256)'](FIRST_DNFT_TOKEN_ID)
          ).to.eq(11);
  
      });

      
    });

  });
});
