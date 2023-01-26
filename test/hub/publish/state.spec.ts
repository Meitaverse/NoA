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
import { DerivativeNFT, DerivativeNFT__factory } from '../../../typechain';

const Default_royaltyBasisPoints = 50; //


makeSuiteCleanRoom('Multi state', function () {
    context('Negatives when state is set to pause', function () {
        
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

    context('Negatives when state is set to publishing pause', function () {
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
                    permitByHubOwner: false
                  },
                )
              ).to.be.revertedWith(ERRORS.PAUSED);
        });

        it('User should fail to create a prepare publish when state is set to PublishingPaused', async function () {
            
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
                    canCollect: true,
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
                    canCollect: true,
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
                    canCollect: true,
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

    context('Negatives  DerivativeNFT state is set to pause', function () {
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

        });


        it('User should fail to publish when DerivativeNFT state is set to Paused', async function () {
     
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
                    canCollect: true,
                    materialURIs: [],
                    fromTokenIds: [],
                    collectModule: feeCollectModule.address,
                    collectModuleInitData: collectModuleInitData,
                    publishModule: publishModule.address,
                    publishModuleInitData: publishModuleinitData,
                })
            ).to.not.be.reverted;

            await manager.connect(governance).setDerivativeNFTState(FIRST_PROJECT_ID, DerivativeNFTState.Paused);
            await expect(
                    manager.connect(user).publish(
                    FIRST_PUBLISH_ID,
                )
            ).to.be.revertedWith(ERRORS.PAUSED);
        });

        it('User should fail to collect when DerivativeNFT state is set to paused', async function () {
     
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
                    manager.connect(user).publish(
                    FIRST_PUBLISH_ID,
                )
            ).to.not.be.reverted;

            await manager.connect(governance).setDerivativeNFTState(FIRST_PROJECT_ID, DerivativeNFTState.Paused);

            await expect(manager.connect(user).collect({
                    publishId: FIRST_PUBLISH_ID,
                    collectorSoulBoundTokenId: SECOND_PROFILE_ID,
                    collectUnits: 1,
                    data: [],
                })
            ).to.be.revertedWith(ERRORS.PAUSED);
        });

        it('User should fail to airdrop when DerivativeNFT state is set to pused', async function () {
     
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
                    manager.connect(user).publish(
                    FIRST_PUBLISH_ID,
                )
            ).to.not.be.reverted;

            await manager.connect(governance).setDerivativeNFTState(FIRST_PROJECT_ID, DerivativeNFTState.Paused);
           
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

        it('User should fail to burn when DerivativeNFT state is set to pused', async function () {
     
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
                    manager.connect(user).publish(
                    FIRST_PUBLISH_ID,
                )
            ).to.not.be.reverted;

            await manager.connect(governance).setDerivativeNFTState(FIRST_PROJECT_ID, DerivativeNFTState.Paused);
            
            let derivativeNFT: DerivativeNFT;
            derivativeNFT = DerivativeNFT__factory.connect(
              await manager.connect(user).getDerivativeNFT(FIRST_PROJECT_ID),
              user
            );
      
            await expect(
                derivativeNFT.connect(user).burn(FIRST_DNFT_TOKEN_ID)
              ).to.be.revertedWith(ERRORS.PAUSED);
        });

        it('User should fail to setTokenImageURI when DerivativeNFT state is set to pused', async function () {
     
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
                    manager.connect(user).publish(
                    FIRST_PUBLISH_ID,
                )
            ).to.not.be.reverted;

            await manager.connect(governance).setDerivativeNFTState(FIRST_PROJECT_ID, DerivativeNFTState.Paused);
            
            let derivativeNFT: DerivativeNFT;
            derivativeNFT = DerivativeNFT__factory.connect(
              await manager.connect(user).getDerivativeNFT(FIRST_PROJECT_ID),
              user
            );
      
            await expect(
                derivativeNFT.connect(user).setTokenImageURI(FIRST_DNFT_TOKEN_ID, MOCK_PROFILE_URI)
              ).to.be.revertedWith(ERRORS.PAUSED);
        });
        
    });
    
    context('Negatives setEmergencyAdmin', function () {
        it('User should fail to set the emergency admin', async function () {
            await expect(manager.setEmergencyAdmin(userAddress)).to.be.revertedWith(
            ERRORS.NOT_GOVERNANCE
            );
        });

        it('Governance should set user as emergency admin, user should fail to set protocol state to Unpaused', async function () {
            await expect(manager.connect(governance).setEmergencyAdmin(userAddress)).to.not.be.reverted;
            await expect(manager.setState(ProtocolState.Unpaused)).to.be.revertedWith(
              ERRORS.EMERGENCY_ADMIN_CANNOT_UNPAUSE
            );
        });

        it('Governance should set user as emergency admin, user should fail to set protocol state to PublishingPaused or Paused from Paused', async function () {
            await expect(manager.connect(governance).setEmergencyAdmin(userAddress)).to.not.be.reverted;
            await expect(manager.connect(governance).setState(ProtocolState.Paused)).to.not.be.reverted;
            await expect(manager.setState(ProtocolState.PublishingPaused)).to.be.revertedWith(
              ERRORS.PAUSED
            );
            await expect(manager.setState(ProtocolState.Paused)).to.be.revertedWith(ERRORS.PAUSED);
          });
    });
    
    context('Scenarios setEmergencyAdmin', function () {
        it('Governance should set user as emergency admin, user sets protocol state but fails to set emergency admin, governance sets emergency admin to the zero address, user fails to set protocol state', async function () {
            await expect(manager.connect(governance).setEmergencyAdmin(userAddress)).to.not.be.reverted;
    
            await expect(manager.setState(ProtocolState.PublishingPaused)).to.not.be.reverted;
            await expect(manager.setState(ProtocolState.Paused)).to.not.be.reverted;
            await expect(manager.setEmergencyAdmin(ZERO_ADDRESS)).to.be.revertedWith(
              ERRORS.NOT_GOVERNANCE
            );
    
            await expect(
              manager.connect(governance).setEmergencyAdmin(ZERO_ADDRESS)
            ).to.not.be.reverted;
    
            await expect(manager.setState(ProtocolState.Paused)).to.be.revertedWith(
              ERRORS.NOT_GOVERNANCE_OR_EMERGENCY_ADMIN
            );
            await expect(manager.setState(ProtocolState.PublishingPaused)).to.be.revertedWith(
              ERRORS.NOT_GOVERNANCE_OR_EMERGENCY_ADMIN
            );
            await expect(manager.setState(ProtocolState.Unpaused)).to.be.revertedWith(
              ERRORS.NOT_GOVERNANCE_OR_EMERGENCY_ADMIN
            );
          });


          it('Governance should set the protocol state, fetched protocol state should be accurate', async function () {
            await expect(manager.connect(governance).setState(ProtocolState.Paused)).to.not.be.reverted;
            expect(await manager.getState()).to.eq(ProtocolState.Paused);
    
            await expect(
              manager.connect(governance).setState(ProtocolState.PublishingPaused)
            ).to.not.be.reverted;
            expect(await manager.getState()).to.eq(ProtocolState.PublishingPaused);
    
            await expect(
              manager.connect(governance).setState(ProtocolState.Unpaused)
            ).to.not.be.reverted;
            expect(await manager.getState()).to.eq(ProtocolState.Unpaused);
          });
    
          it('Governance should set user as emergency admin, user should set protocol state to PublishingPaused, then Paused, then fail to set it to PublishingPaused', async function () {
            await expect(manager.connect(governance).setEmergencyAdmin(userAddress)).to.not.be.reverted;
    
            await expect(manager.setState(ProtocolState.PublishingPaused)).to.not.be.reverted;
            await expect(manager.setState(ProtocolState.Paused)).to.not.be.reverted;
            await expect(manager.setState(ProtocolState.PublishingPaused)).to.be.revertedWith(
              ERRORS.PAUSED
            );
          });
    
          it('Governance should set user as emergency admin, user should set protocol state to PublishingPaused, then set it to PublishingPaused again without reverting', async function () {
            await expect(manager.connect(governance).setEmergencyAdmin(userAddress)).to.not.be.reverted;
    
            await expect(manager.setState(ProtocolState.PublishingPaused)).to.not.be.reverted;
            await expect(manager.setState(ProtocolState.PublishingPaused)).to.not.be.reverted;
          });
    });

});

