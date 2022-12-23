import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { HubDataStruct } from '../../../typechain/IManager';
// import { TokenDataStructOutput } from '../../../typechain/Manager';
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
//   mockFollowModule,
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

makeSuiteCleanRoom('Publishing', function () {
    context('Scenarios', function () {
        it('User should be able to create a prepare publish', async function () {
            
        });

    });
});