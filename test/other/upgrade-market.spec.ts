import '@nomiclabs/hardhat-ethers';
import {expectEvent, expectRevert} from '@openzeppelin/test-helpers';
import { expect } from 'chai';
import hre from 'hardhat' 

  // eslint-disable-next-line
import { ethers, upgrades } from 'hardhat';

import {
  MarketPlace,
  MarketPlaceV2,
  VoucherV2,
} from '../../typechain';
import {
  MOCK_PROFILE_URI,
  NickName,
  SBT_NAME,
  SBT_SYMBOL,
  SECOND_PROFILE_ID,
  bankTreasuryContract,
  makeSuiteCleanRoom,
  manager,
  marketPlaceContract,
  sbtContract,
  user,
  userAddress,
  userTwoAddress,
  voucherContract,
} from '../__setup.spec';

 let original_balance = 10000;
 const valueToSet = 123;

makeSuiteCleanRoom('Market upgrade ability', function () {
  
  describe("#upgrade V2", () => {
    beforeEach('get factories', async function() {

      await manager.connect(user).createProfile({ 
        wallet: userAddress,
        nickName: NickName,
        imageURI: MOCK_PROFILE_URI,
      });

      //user buy some SBT Values 
      await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});
    
    
      this.marketV2Impl = await hre.ethers.getContractFactory('MarketPlaceV2');
      
    });

    it('Should upgrade market contract and can call V2 function.', async function() {
      
      const marketV2 = (await upgrades.upgradeProxy(
        marketPlaceContract.address,
        this.marketV2Impl,
      )) as MarketPlaceV2;
      

        await expect(
          marketV2.connect(user).setAdditionalValue(valueToSet)
        ).to.not.be.reverted;
    
         expect(await marketV2.connect(user).getAdditionalValue()).to.eq(valueToSet);
         
         expect(await marketV2.version()).to.eq(2);
        
    });
  });
});