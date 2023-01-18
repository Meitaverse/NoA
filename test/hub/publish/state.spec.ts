import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { parseEther } from '@ethersproject/units';
import { DataTypes } from '../../../typechain/contracts/interfaces/IManager';
import { ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import { 
    createProfileReturningTokenId,
    createHubReturningHubId,
    createProjectReturningProjectId,
    DerivativeNFTState,
    ProtocolState,
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
  moduleGlobals,
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
  THIRD_PROFILE_ID,
  
} from '../../__setup.spec';

const Default_royaltyBasisPoints = 50; //


makeSuiteCleanRoom('Multi state', function () {
    context('Negatives create', function () {
        
        it('User should fail to mint SBT value when state is set to pause', async function () {
            
            await expect( 
                manager.connect(user).createProfile({
                wallet: userAddress,
                nickName: 'Alice',
                imageURI: MOCK_PROFILE_URI,
              })
            ).to.not.be.reverted;

            await manager.connect(governance).setState(ProtocolState.Paused);

            await expect( 
                 manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, 100)
            ).to.be.revertedWith(ERRORS.PAUSED);

        });
        it('User should fail to burn SBT value when state is set to pause', async function () {
            
            await expect( 
                manager.connect(user).createProfile({
                wallet: userAddress,
                nickName: 'Alice',
                imageURI: MOCK_PROFILE_URI,
              })
            ).to.not.be.reverted;

            
            await expect( 
                manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, 100)
            ).to.not.be.reverted;
                
                
            await manager.connect(governance).setState(ProtocolState.Paused);

            await expect( 
                manager.connect(governance).burnSBT(SECOND_PROFILE_ID)
            ).to.be.revertedWith(ERRORS.PAUSED);
        });

        it('User should fail to create profile when state is set to pause', async function () {
            await manager.connect(governance).setState(ProtocolState.Paused);
            
            await expect( 
                manager.connect(user).createProfile({
                wallet: userAddress,
                nickName: 'Alice',
                imageURI: MOCK_PROFILE_URI,
              })
            ).to.be.revertedWith(ERRORS.PAUSED);

        });

        it('User should fail to create hub when state is set to pause', async function () {
            await manager.connect(governance).setState(ProtocolState.Paused);
            
            await expect(
                manager.connect(user).createHub({
                  soulBoundTokenId: SECOND_PROFILE_ID,
                  name: "bitsoul",
                  description: "Hub for bitsoul",
                  imageURI: "https://ipfs.io/ipfs/QmVnu7JQVoDRqSgHBzraYp7Hy78HwJtLFi6nUFCowTGdzp/11.png",
                })
              ).to.be.revertedWith(ERRORS.PAUSED);
      
        });

        it('User should fail to update hub when state is set to pause', async function () {
            
            await expect( 
                manager.connect(user).createProfile({
                wallet: userAddress,
                nickName: 'Alice',
                imageURI: MOCK_PROFILE_URI,
              })
            ).to.not.be.reverted;

            await expect(
                manager.connect(user).createHub({
                  soulBoundTokenId: SECOND_PROFILE_ID,
                  name: "bitsoul",
                  description: "Hub for bitsoul",
                  imageURI: "https://ipfs.io/ipfs/QmVnu7JQVoDRqSgHBzraYp7Hy78HwJtLFi6nUFCowTGdzp/11.png",
                })
              ).to.not.be.reverted;

            await manager.connect(governance).setState(ProtocolState.Paused);
            await expect(
                manager.connect(user).updateHub(
                  SECOND_PROFILE_ID,
                   "bitsoul",
                  "Hub for bitsoul",
                   "https://ipfs.io/ipfs/QmVnu7JQVoDRqSgHBzraYp7Hy78HwJtLFi6nUFCowTGdzp/11.png",
                )
              ).to.be.revertedWith(ERRORS.PAUSED);
      
        });

       

    });

    context('Negatives  state is set to publishing pause', function () {
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
            
            let projectInfo = await manager.connect(user).getProjectInfo(FIRST_PROJECT_ID);
            expect(projectInfo.soulBoundTokenId).to.eq(SECOND_PROFILE_ID);
            expect(projectInfo.hubId).to.eq(FIRST_HUB_ID);
            expect(projectInfo.name).to.eq("bitsoul");
            expect(projectInfo.description).to.eq("Hub for bitsoul");
            expect(projectInfo.image).to.eq("image");
            expect(projectInfo.metadataURI).to.eq("metadataURI");
            expect(projectInfo.descriptor.toUpperCase()).to.eq(metadataDescriptor.address.toUpperCase());

        });

        it('User should fail to create project when state is set to PublishingPaused', async function () {
            await manager.connect(governance).setState(ProtocolState.PublishingPaused);
            
            await expect(
                manager.connect(userTwo).createProject(
                  {
                    soulBoundTokenId: SECOND_PROFILE_ID,
                    hubId: FIRST_HUB_ID,
                    name: "bitsoul",
                    description: "Hub for bitsoul",
                    image: "image",
                    metadataURI: "metadataURI",
                    descriptor: metadataDescriptor.address,
                    defaultRoyaltyPoints: 0,
                    feeShareType: 0,  
                  },
                )
              ).to.be.revertedWith(ERRORS.PAUSED);
        });

        it('User should fail to create a prepare publish when state is set to PublishingPaused', async function () {
            // await manager.connect(governance).setDerivativeNFTState(FIRST_PROJECT_ID, DerivativeNFTState.Paused);
            await manager.connect(governance).setState(ProtocolState.PublishingPaused);
            
            const publishModuleinitData = abiCoder.encode(
                ['address', 'uint256'],
                [template.address, DEFAULT_TEMPLATE_NUMBER],
            );

            const collectModuleInitData = abiCoder.encode(
                ['uint256', 'uint16', 'uint256', 'uint256'],
                [SECOND_PROFILE_ID, GENESIS_FEE_BPS, DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints]
            );

            //mint 100Value to user
            await manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, 100);

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
            ).to.be.revertedWith(ERRORS.PAUSED);
        });

        it('User should fail to update publish when state is set to PublishingPaused', async function () {
     
            const publishModuleinitData = abiCoder.encode(
                ['address', 'uint256'],
                [template.address, DEFAULT_TEMPLATE_NUMBER],
            );

            const collectModuleInitData = abiCoder.encode(
                ['uint256', 'uint16', 'uint256', 'uint256'],
                [SECOND_PROFILE_ID, GENESIS_FEE_BPS, DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints]
            );

            //mint 100Value to user
            await manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, 100);
            
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

            await manager.connect(governance).setState(ProtocolState.PublishingPaused);
    
            await expect(
                    manager.connect(user).updatePublish(
                    FIRST_PUBLISH_ID,
                    DEFAULT_COLLECT_PRICE,
                    Default_royaltyBasisPoints,
                    1,
                    "Dollar",
                    "Hand draw",
                    [],
                    [],
                )
            ).to.be.revertedWith(ERRORS.PAUSED);
        });

        it('User should fail to publish when state is set to PublishingPaused', async function () {
     
            const publishModuleinitData = abiCoder.encode(
                ['address', 'uint256'],
                [template.address, DEFAULT_TEMPLATE_NUMBER],
            );

            const collectModuleInitData = abiCoder.encode(
                ['uint256', 'uint16', 'uint256', 'uint256'],
                [SECOND_PROFILE_ID, GENESIS_FEE_BPS, DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints]
            );

            //mint 100Value to user
            await manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, 100);
            
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

            await manager.connect(governance).setState(ProtocolState.PublishingPaused);
    
            await expect(
                    manager.connect(user).publish(
                    FIRST_PUBLISH_ID,
                )
            ).to.be.revertedWith(ERRORS.PAUSED);
        });

        it('User should fail to collect when state is set to PublishingPaused', async function () {
     
            const publishModuleinitData = abiCoder.encode(
                ['address', 'uint256'],
                [template.address, DEFAULT_TEMPLATE_NUMBER],
            );

            const collectModuleInitData = abiCoder.encode(
                ['uint256', 'uint16', 'uint256', 'uint256'],
                [SECOND_PROFILE_ID, GENESIS_FEE_BPS, DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints]
            );

            //mint 100Value to user
            await manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, 100);
            
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
                    manager.connect(user).publish(
                    FIRST_PUBLISH_ID,
                )
            ).to.not.be.reverted;

            await manager.connect(governance).setState(ProtocolState.PublishingPaused);
            
            await expect(manager.connect(user).collect({
                    publishId: FIRST_PUBLISH_ID,
                    collectorSoulBoundTokenId: SECOND_PROFILE_ID,
                    collectUnits: 1,
                    data: [],
                })
            ).to.be.revertedWith(ERRORS.PAUSED);
        });

        it('User should fail to airdrop when state is set to PublishingPaused', async function () {
     
            const publishModuleinitData = abiCoder.encode(
                ['address', 'uint256'],
                [template.address, DEFAULT_TEMPLATE_NUMBER],
            );

            const collectModuleInitData = abiCoder.encode(
                ['uint256', 'uint16', 'uint256', 'uint256'],
                [SECOND_PROFILE_ID, GENESIS_FEE_BPS, DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints]
            );

            //mint 100Value to user
            await manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, 100);
            
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
                    manager.connect(user).publish(
                    FIRST_PUBLISH_ID,
                )
            ).to.not.be.reverted;

            await manager.connect(governance).setState(ProtocolState.PublishingPaused);
            
            await expect(
                manager.connect(user).airdrop({
                publishId: FIRST_PROJECT_ID,
                ownershipSoulBoundTokenId: SECOND_PROFILE_ID,
                toSoulBoundTokenIds: [SECOND_PROFILE_ID],
                tokenId: FIRST_DNFT_TOKEN_ID,
                values: [1],
              })
              ).to.be.revertedWith(ERRORS.PAUSED);

        });


    });
});

