import '@nomiclabs/hardhat-ethers';
import {expectEvent, expectRevert} from '@openzeppelin/test-helpers';
import { expect } from 'chai';
import hre from 'hardhat' 

  // eslint-disable-next-line
import { ethers, upgrades } from 'hardhat';

import {
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
  sbtContract,
  user,
  userAddress,
  userTwoAddress,
  voucherContract,
} from '../__setup.spec';

 let original_balance = 10000;
 const valueToSet = 123;

makeSuiteCleanRoom('Voucher upgrade ability', function () {
  
  describe("#upgrade V2", () => {
    beforeEach('get factories', async function() {

      await manager.connect(user).createProfile({ 
        wallet: userAddress,
        nickName: NickName,
        imageURI: MOCK_PROFILE_URI,
      });

      //user buy some SBT Values 
      await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});
    
      await voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [original_balance], [''])
      let value = await voucherContract.balanceOf(userAddress, 1);
      console.log("balance of user, voucher token (id=1): ", value);

      this.voucherV2Impl = await hre.ethers.getContractFactory('VoucherV2');
      
    });

    it("Proxy state", async () => {
      expect([
        await voucherContract.name(),
        await voucherContract.symbol()
      ]).to.deep.eq([
        "Voucher Bitsoul",
        "Voucher",
      ]);

    });

    it('Should upgrade sbt contract, name , symbol, decimals is not chanaged.', async function() {
      
      const voucherV2 = (await upgrades.upgradeProxy(
        voucherContract.address,
        this.voucherV2Impl,
      )) as VoucherV2;

      expect([
        await voucherV2.connect(user).name(),
        await voucherV2.connect(user).symbol(),
      ]).to.deep.eq([
        "Voucher Bitsoul",
        "Voucher",
      ]);
      
    });


    it('Should upgrade voucher contract and can mint voucher.', async function() {
      
      const voucherV2 = (await upgrades.upgradeProxy(
        voucherContract.address,
        this.voucherV2Impl,
      )) as VoucherV2;
      

      //user buy some SBT Values 
      await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});


      let tokenId2 = 2;
      
      await voucherV2.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [original_balance], [''])
      let value = await voucherV2.balanceOf(userAddress, tokenId2);
      console.log("voucherV2 upgraded, balance of user, voucher token (id=", tokenId2, "): ", value);

      expect(
        value,
      ).to.deep.eq(
        original_balance
      );
    });

    it('Should upgrade voucher contract and can call V2 function.', async function() {
      
      const voucherV2 = (await upgrades.upgradeProxy(
        voucherContract.address,
        this.voucherV2Impl,
      )) as VoucherV2;
      

        await expect(
          voucherV2.connect(user).setAdditionalValue(valueToSet)
        ).to.not.be.reverted;
    
         expect(await voucherV2.connect(user).getAdditionalValue()).to.eq(valueToSet);
         
         expect(await voucherV2.version()).to.eq(2);
        
    });
  });
});