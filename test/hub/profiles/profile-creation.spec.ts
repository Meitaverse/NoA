import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
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
  SECOND_PROFILE_ID,
  FIRST_HUB_ID,
  FIRST_PROJECT_ID,
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
  metadataDescriptor
} from '../../__setup.spec';


const nickName = 'BitsoulUser';

makeSuiteCleanRoom('Profile Creation', function () {
    context('Generic', function () {
        context('Negatives', function () {
            it('User should fail to create a profile with a handle longer than 31 bytes', async function () {
                const val = '11111111111111111111111111111111';
                
                expect(val.length).to.eq(32);
                await expect(
                  manager.createProfile({
                    to: userAddress,
                    handle: val,
                    nickName: nickName,
                    imageURI: MOCK_PROFILE_URI,
                    followModule: ZERO_ADDRESS,
                    followModuleInitData: [],
                    followNFTURI: MOCK_FOLLOW_NFT_URI,
                  })
                ).to.be.revertedWith(ERRORS.INVALID_HANDLE_LENGTH);
            });

            it('User should fail to create a profile with an empty handle (0 length bytes)', async function () {
                await expect(
                   manager.createProfile({
                    to: userAddress,
                    handle: '',
                    nickName: nickName,
                    imageURI: MOCK_PROFILE_URI,
                    followModule: ZERO_ADDRESS,
                    followModuleInitData: [],
                    followNFTURI: MOCK_FOLLOW_NFT_URI,
                  })
                ).to.be.revertedWith(ERRORS.INVALID_HANDLE_LENGTH);
            });
            it('User should fail to create a profile with a handle with a capital letter', async function () {
                await expect(
                  manager.createProfile({
                    to: userAddress,
                    handle: 'Egg',
                    nickName: nickName,
                    imageURI: MOCK_PROFILE_URI,
                    followModule: ZERO_ADDRESS,
                    followModuleInitData: [],
                    followNFTURI: MOCK_FOLLOW_NFT_URI,
                  })
                ).to.be.revertedWith(ERRORS.HANDLE_CONTAINS_INVALID_CHARACTERS);
            });

            it('User should fail to create a profile with a handle with an invalid character', async function () {
                await expect(
                   manager.createProfile({
                    to: userAddress,
                    handle: 'egg?',
                    nickName: nickName,
                    imageURI: MOCK_PROFILE_URI,
                    followModule: ZERO_ADDRESS,
                    followModuleInitData: [],
                    followNFTURI: MOCK_FOLLOW_NFT_URI,
                  })
                ).to.be.revertedWith(ERRORS.HANDLE_CONTAINS_INVALID_CHARACTERS);
              });

              it('User should fail to create a profile when they are not a whitelisted profile creator', async function () {
                await expect(
                  manager.connect(governance).whitelistProfileCreator(userAddress, false)
                ).to.not.be.reverted;
        
                await expect(
                  manager.createProfile({
                    to: userAddress,
                    handle: MOCK_PROFILE_HANDLE,
                    nickName: nickName,
                    imageURI: MOCK_PROFILE_URI,
                    followModule: ZERO_ADDRESS,
                    followModuleInitData: [],
                    followNFTURI: MOCK_FOLLOW_NFT_URI,
                  })
                ).to.be.revertedWith(ERRORS.PROFILE_CREATOR_NOT_WHITELISTED);
              });

              
        }); //Negatives

        context('Successful', function () {

            it('User should success to create a profile', async function () {
                await expect(
                    manager.connect(governance).whitelistProfileCreator(userAddress, true)
                  ).to.not.be.reverted;
                  
                await expect(
                    manager.connect(user).createProfile({
                      to: userAddress,
                      handle: MOCK_PROFILE_HANDLE,
                      nickName: nickName,
                      imageURI: MOCK_PROFILE_URI,
                      followModule: ZERO_ADDRESS,
                      followModuleInitData: [],
                      followNFTURI: MOCK_FOLLOW_NFT_URI,
                    })
                  ).to.not.be.reverted;
              });

        });
    });

    context('Scenarios', function () {
        it('User should be able to create a profile with a handle, receive an NFT and the handle should resolve to the NFT ID, userTwo should do the same', async function () {
            let timestamp: any;
            let owner: string;
            let totalSupply: BigNumber;
            let profileId: BigNumber;
            let mintTimestamp: BigNumber;
    
            expect(
              await createProfileReturningTokenId({
                vars: {
                  to: userAddress,
                  handle: MOCK_PROFILE_HANDLE,
                  nickName: nickName,
                  imageURI: MOCK_PROFILE_URI,
                  followModule: ZERO_ADDRESS,
                  followModuleInitData: [],
                  followNFTURI: MOCK_FOLLOW_NFT_URI,
                },
              })
            ).to.eq(SECOND_PROFILE_ID);

    
            timestamp = await getTimestamp();
            owner = await ndptContract.ownerOf(SECOND_PROFILE_ID);
            totalSupply = await ndptContract.totalSupply();
            expect(owner).to.eq(userAddress);
            expect(totalSupply).to.eq(SECOND_PROFILE_ID); //1-is bankTreasury

    
            // const secondProfileId = SECOND_PROFILE_ID + 1;
            // const secondProfileHandle = '2nd_profile';
            // expect(
            //   await createProfileReturningTokenId({
            //     sender: userTwo,
            //     vars: {
            //       to: userTwoAddress,
            //       handle: secondProfileHandle,
            //       nickName: nickName,
            //       imageURI: MOCK_PROFILE_URI,
            //       followModule: ZERO_ADDRESS,
            //       followModuleInitData: [],
            //       followNFTURI: MOCK_FOLLOW_NFT_URI,
            //     },
            //   })
            // ).to.eq(secondProfileId + 1);
    
            // timestamp = await getTimestamp();
            // owner = await ndptContract.ownerOf(secondProfileId + 1);
            // totalSupply = await ndptContract.totalSupply();
            // expect(owner).to.eq(userTwoAddress);
            // expect(totalSupply).to.eq(secondProfileId + 2);
        });

    });

    context('Hub and Project', function () {
        it('User should be able to create a hub', async function () {
            
            expect(
                await createProfileReturningTokenId({
                  vars: {
                    to: userAddress,
                    handle: MOCK_PROFILE_HANDLE,
                    nickName: nickName,
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

            let hubData = await manager.getHubInfo(FIRST_HUB_ID);
            expect(hubData.creator).to.eq(userAddress);
            expect(hubData.soulBoundTokenId).to.eq(SECOND_PROFILE_ID);
            expect(hubData.name).to.eq("bitsoul");
            expect(hubData.description).to.eq("Hub for bitsoul");
            expect(hubData.image).to.eq("image");

        });
        
        it('User should be able to create a project', async function () {
            expect(
                await createProfileReturningTokenId({
                  vars: {
                    to: userAddress,
                    handle: MOCK_PROFILE_HANDLE,
                    nickName: nickName,
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
        });
    });
});