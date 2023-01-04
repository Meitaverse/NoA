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
  const DEFAULT_COLLECT_PRICE = 10000; // in wei parseEther('10');
  const Default_royaltyBasisPoints = 50; //

  beforeEach(async function () {

    expect(
      await createProfileReturningTokenId({
          vars: {
          to: userAddress,
          nickName: NickName,
          imageURI: MOCK_PROFILE_URI,
          },
         }) 
      ).to.eq(SECOND_PROFILE_ID);

      expect(await manager.getWalletBySoulBoundTokenId(SECOND_PROFILE_ID)).to.eq(userAddress);
       
      //mint some Values to user
      await manager.connect(governance).mintNDPTValue(SECOND_PROFILE_ID, parseEther('10'));

      const tokenId = await manager.connect(userTwo).callStatic.createProfile({ 
            to: userTwoAddress,
            nickName: NickName3,
            imageURI: MOCK_PROFILE_URI,
      });
      
      await expect(manager.connect(userTwo).createProfile({ 
            to: userTwoAddress,
            nickName: NickName3,
            imageURI: MOCK_PROFILE_URI,
      })).to.not.be.reverted;
      expect(tokenId).to.eq(THIRD_PROFILE_ID);

      expect(await manager.getWalletBySoulBoundTokenId(THIRD_PROFILE_ID)).to.eq(userTwoAddress);

      //mint some Values to userTwo
      await manager.connect(governance).mintNDPTValue(THIRD_PROFILE_ID, parseEther('10'));
      // expect((await ndptContract.balanceOfNDPT(THIRD_PROFILE_ID)).toNumber()).to.eq(parseEther('10'));
        

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
      
      it('user should fail to publish with fee collect module using zero publishId', async function () {
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
             amount: 1,
             salePrice: DEFAULT_COLLECT_PRICE,
             royaltyBasisPoints: Default_royaltyBasisPoints,             
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
            ['uint256', 'uint16', 'uint256', 'uint256'],
            //10000 is max
            [SECOND_PROFILE_ID, 10000, DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints]
        );

        await expect(
          manager.connect(user).prePublish({
             soulBoundTokenId: SECOND_PROFILE_ID,
             hubId: FIRST_HUB_ID,
             projectId: FIRST_PROJECT_ID,
             amount: 1,
             salePrice: DEFAULT_COLLECT_PRICE,
             royaltyBasisPoints: Default_royaltyBasisPoints,             
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
            ['uint256', 'uint16', 'uint256', 'uint256'],
           
            [SECOND_PROFILE_ID, GENESIS_FEE_BPS, DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints]
        );

        await expect(
          manager.connect(user).prePublish({
             soulBoundTokenId: SECOND_PROFILE_ID,
             hubId: FIRST_HUB_ID,
             projectId: FIRST_PROJECT_ID,
             amount: 0,
             salePrice: DEFAULT_COLLECT_PRICE,
             royaltyBasisPoints: Default_royaltyBasisPoints,             
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
        
      });      

    });

    context('Collecting', function () {
      beforeEach(async function () {

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
              amount: 1,
              salePrice: DEFAULT_COLLECT_PRICE,
              royaltyBasisPoints: Default_royaltyBasisPoints,              
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

        /*
        //不开放直接调用transferFrom, 必须通过manager来调用
        const tx = derivativeNFT['transferFrom(uint256,address,uint256)'](FIRST_DNFT_TOKEN_ID, userTwoAddress, 1);
        const receipt = await waitForTx(tx);
        */
          
        let [treasuryFee, genesisSoulBoundTokenId, treasuryAmount, genesisAmount, adjustedAmount] = await feeCollectModule.getFees(FIRST_PUBLISH_ID, 1);
        console.log("\t --- treasuryFee:", treasuryFee);
        console.log("\t --- genesisSoulBoundTokenId:", genesisSoulBoundTokenId);
        console.log("\t --- treasuryAmount:", treasuryAmount);
        console.log("\t --- genesisAmount:", genesisAmount);
        console.log("\t --- adjustedAmount:", adjustedAmount);

        const tx = manager.connect(userTwo).collect({
            publishId: FIRST_PUBLISH_ID,
            collectorSoulBoundTokenId: THIRD_PROFILE_ID,
            collectValue: 1,
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

        matchEvent(
          receipt,
          'DerivativeNFTCollected',
          [FIRST_PUBLISH_ID, derivativeNFT.address, SECOND_PROFILE_ID, THIRD_PROFILE_ID, FIRST_DNFT_TOKEN_ID, 1, SECOND_DNFT_TOKEN_ID, await getTimestamp()],
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
          
        let [treasuryFee, genesisSoulBoundTokenId, treasuryAmount, genesisAmount, adjustedAmount] = await feeCollectModule.getFees(FIRST_PUBLISH_ID, 1);
        console.log("\t --- treasuryFee:", treasuryFee);
        console.log("\t --- genesisSoulBoundTokenId:", genesisSoulBoundTokenId);
        console.log("\t --- treasuryAmount:", treasuryAmount);
        console.log("\t --- genesisAmount:", genesisAmount);
        console.log("\t --- adjustedAmount:", adjustedAmount);

        expect(
          await collectReturningTokenId({
              sender: userTwo,
              vars: {
                publishId: FIRST_PUBLISH_ID,
                collectorSoulBoundTokenId: THIRD_PROFILE_ID,
                collectValue: 1,
                data : [],
              },
          }) 
          ).to.eq(SECOND_DNFT_TOKEN_ID);

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
   
    });

    context('Airdrop', function () {
      beforeEach(async function () {
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
              amount: 11,
              salePrice: DEFAULT_COLLECT_PRICE,
              royaltyBasisPoints: Default_royaltyBasisPoints,              
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
          ).to.eq(11);

  
      });

      it('Should success to airdrop ', async function () {
        
        expect(
          await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
        ).to.eq(userAddress);

        await expect(manager.connect(user).airdrop({
          publishId: FIRST_PROJECT_ID,
          ownershipSoulBoundTokenId: SECOND_PROFILE_ID,
          toSoulBoundTokenIds: [THIRD_PROFILE_ID],
          tokenId: FIRST_DNFT_TOKEN_ID,
          values: [1],
        })).to.not.be.reverted;

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
            ['uint256', 'uint16', 'uint256', 'uint256'],
           
            [SECOND_PROFILE_ID, GENESIS_FEE_BPS, DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints]
        );

        await expect(
            manager.connect(user).prePublish({
              soulBoundTokenId: SECOND_PROFILE_ID,
              hubId: FIRST_HUB_ID,
              projectId: FIRST_PROJECT_ID,
              amount: 11,
              salePrice: DEFAULT_COLLECT_PRICE,
              royaltyBasisPoints: Default_royaltyBasisPoints,              
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
          ).to.eq(11);
  
      });

      it('Transfer dNFT to a soulBoundTokenId ', async function () {
        
        expect(
          await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
        ).to.eq(userAddress);

        //approve manager contract
        await derivativeNFT.connect(user)['approve(address,uint256)'](manager.address, FIRST_DNFT_TOKEN_ID);

        await expect(manager.connect(user).transferDerivativeNFT(
          FIRST_PROJECT_ID,
          SECOND_PROFILE_ID,
          THIRD_PROFILE_ID,
          FIRST_DNFT_TOKEN_ID,
        )).to.not.be.reverted;

        expect(
          await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
        ).to.eq(userTwoAddress);

        expect(
          await derivativeNFT['balanceOf(uint256)'](FIRST_DNFT_TOKEN_ID)
        ).to.eq(11);

      });      

      it('Transfer dNFT value to a soulBoundTokenId ', async function () {
        
        expect(
          await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
        ).to.eq(userAddress);

        //approve manager contract
        await derivativeNFT.connect(user)['approve(address,uint256)'](manager.address, FIRST_DNFT_TOKEN_ID);

        await expect(manager.connect(user).transferValueDerivativeNFT(
          FIRST_PROJECT_ID,
          SECOND_PROFILE_ID,
          THIRD_PROFILE_ID,
          FIRST_DNFT_TOKEN_ID,
          1
        )).to.not.be.reverted;

        expect(
          await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
        ).to.eq(userAddress);

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
      
    });

  });
});
