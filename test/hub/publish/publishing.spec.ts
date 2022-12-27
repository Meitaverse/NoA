import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { parseEther } from '@ethersproject/units';
import { HubDataStruct } from '../../../typechain/IManager';
import { ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import { 
    createProfileReturningTokenId,
    createHubReturningHubId,
    createProjectReturningProjectId,
    getTimestamp, 
    waitForTx 
} from '../../helpers/utils';

import {
  abiCoder,
  SECOND_PROFILE_ID,
  FIRST_HUB_ID,
  FIRST_PROJECT_ID,
  FIRST_DNFT_TOKEN_ID,
  FIRST_PUBLISH_ID,
  GENESIS_FEE_BPS,
  DEFAULT_COLLECT_PRICE,
  DEFAULT_TEMPLATE_NUMBER,
  NickName,
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
  
} from '../../__setup.spec';



makeSuiteCleanRoom('Publishing', function () {
    context('Scenarios', function () {
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
            
            let projectInfo = await manager.connect(user).getProjectInfo(FIRST_PROJECT_ID);
            expect(projectInfo.soulBoundTokenId).to.eq(SECOND_PROFILE_ID);
            expect(projectInfo.hubId).to.eq(FIRST_HUB_ID);
            expect(projectInfo.name).to.eq("bitsoul");
            expect(projectInfo.description).to.eq("Hub for bitsoul");
            expect(projectInfo.image).to.eq("image");
            expect(projectInfo.metadataURI).to.eq("metadataURI");
            expect(projectInfo.descriptor.toUpperCase()).to.eq(metadataDescriptor.address.toUpperCase());

            // await manager.connect(governance).deployDerivativeNFT(metadataDescriptor.address);
            // expect(await  manager.connect(governance).getProjectInfo_name(FIRST_PROJECT_ID)).to.eq("Bitsoul");
            
        });
   
        it('User should free to create a prepare publish when amount is 1', async function () {
            const publishModuleinitData = abiCoder.encode(
                ['address', 'uint256'],
                [template.address, DEFAULT_TEMPLATE_NUMBER],
            );

            const collectModuleInitData = abiCoder.encode(
                ['uint256', 'uint16', 'address', 'uint256', 'bool'],
                [SECOND_PROFILE_ID, GENESIS_FEE_BPS, ndptAddress, DEFAULT_COLLECT_PRICE, false]
            );

            //mint 100Value to user
            await manager.connect(governance).mintNDPTValue(SECOND_PROFILE_ID, 100);

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

            let publishInfo = await manager.connect(user).getPublishInfo(FIRST_PUBLISH_ID);
            expect(publishInfo.publication.soulBoundTokenId).to.eq(SECOND_PROFILE_ID);
            expect(publishInfo.publication.hubId).to.eq(FIRST_HUB_ID);
            expect(publishInfo.publication.projectId).to.eq(FIRST_PROJECT_ID);
            expect(publishInfo.publication.amount).to.eq(1);
            expect(publishInfo.publication.name).to.eq("Dollar");
            expect(publishInfo.publication.description).to.eq("Hand draw");

            //balanceOf is still 100 value
            expect((await ndptContract.balanceOfNDPT(SECOND_PROFILE_ID)).toNumber()).to.eq(100);

        });

        it('User should be able to create a prepare publish and amount is 2', async function () {
            const publishModuleinitData = abiCoder.encode(
                ['address', 'uint256'],
                [template.address, DEFAULT_TEMPLATE_NUMBER],
            );

            const collectModuleInitData = abiCoder.encode(
                ['uint256', 'uint16', 'address', 'uint256', 'bool'],
                [SECOND_PROFILE_ID, GENESIS_FEE_BPS, ndptAddress, DEFAULT_COLLECT_PRICE, false]
            );

            //mint 100Value to user
            await manager.connect(governance).mintNDPTValue(SECOND_PROFILE_ID, 100);
            
            expect((await ndptContract.balanceOfNDPT(SECOND_PROFILE_ID)).toNumber()).to.eq(100);

            await expect(
                 manager.connect(user).prePublish({
                    soulBoundTokenId: SECOND_PROFILE_ID,
                    hubId: FIRST_HUB_ID,
                    projectId: FIRST_PROJECT_ID,
                    amount: 2,
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

            expect((await ndptContract.balanceOfNDPT(SECOND_PROFILE_ID)).toNumber()).to.eq(0);

        });

        it('User should be able to publish a dNFT to himself', async function () {
            const publishModuleinitData = abiCoder.encode(
                ['address', 'uint256'],
                [template.address, DEFAULT_TEMPLATE_NUMBER],
            );

            const collectModuleInitData = abiCoder.encode(
                ['uint256', 'uint16', 'address', 'uint256', 'bool'],
                [SECOND_PROFILE_ID, GENESIS_FEE_BPS, ndptAddress, DEFAULT_COLLECT_PRICE, false]
            );
            
            //mint 100Value to user
            await manager.connect(governance).mintNDPTValue(SECOND_PROFILE_ID, 100);

            expect((await ndptContract.balanceOfNDPT(SECOND_PROFILE_ID)).toNumber()).to.eq(100);

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
                 manager.connect(user).publish(
                    FIRST_PUBLISH_ID
               )
            ).to.not.be.reverted;

            // const dNFTTokenId = await manager.connect(user).callStatic.publish(FIRST_PUBLISH_ID);
            // await expect(manager.connect(user).publish(FIRST_PUBLISH_ID)).to.not.be.reverted;
            // expect(dNFTTokenId).to.eq(FIRST_DNFT_TOKEN_ID);  

            //ownerOf
            
            expect((await ndptContract.balanceOfNDPT(SECOND_PROFILE_ID)).toNumber()).to.eq(100);

        });

        it('User should be able to publish 11 dNFTs to himself', async function () {
            const publishModuleinitData = abiCoder.encode(
                ['address', 'uint256'],
                [template.address, DEFAULT_TEMPLATE_NUMBER],
            );

            const collectModuleInitData = abiCoder.encode(
                ['uint256', 'uint16', 'address', 'uint256', 'bool'],
                [SECOND_PROFILE_ID, GENESIS_FEE_BPS, ndptAddress, DEFAULT_COLLECT_PRICE, false]
            );
            
            //mint 1000Value to user
            await manager.connect(governance).mintNDPTValue(SECOND_PROFILE_ID, 1000);
            
            expect((await ndptContract.balanceOfNDPT(SECOND_PROFILE_ID)).toNumber()).to.eq(1000);
            
            await expect(
                manager.connect(user).prePublish({
                   soulBoundTokenId: SECOND_PROFILE_ID,
                   hubId: FIRST_HUB_ID,
                   projectId: FIRST_PROJECT_ID,
                   amount: 11,
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
            await expect(manager.connect(user).publish(FIRST_PUBLISH_ID)).to.not.be.reverted;
            expect(dNFTTokenId).to.eq(FIRST_DNFT_TOKEN_ID);  

            //ownerOf
            
            expect((await ndptContract.balanceOfNDPT(SECOND_PROFILE_ID)).toNumber()).to.eq(0);

        });
        
    });
});

