import '@nomiclabs/hardhat-ethers';
import {expectEvent, expectRevert} from '@openzeppelin/test-helpers';
import { expect } from 'chai';
import hre from 'hardhat' 

  // eslint-disable-next-line
import { ethers, upgrades } from 'hardhat';

import {
  NFTDerivativeProtocolTokenV2,
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
} from '../__setup.spec';

 let original_balance = 10000;

makeSuiteCleanRoom('SBT upgrade ability', function () {
  
  describe("#upgrade V2", () => {
    beforeEach('get factories', async function() {

      await manager.connect(user).createProfile({ 
        wallet: userAddress,
        nickName: NickName,
        imageURI: MOCK_PROFILE_URI,
      });
      this.sbtV2Impl = await hre.ethers.getContractFactory('NFTDerivativeProtocolTokenV2');
      
    });

    it("Proxy state", async () => {
      expect([
        await sbtContract.name(),
        await sbtContract.symbol(),
        await sbtContract.valueDecimals(),
      ]).to.deep.eq([
        SBT_NAME,
        SBT_SYMBOL,
        18,
      ]);

      expect(
        await sbtContract.version()
      ).to.deep.eq(
        1,
      );


    });

    it('Should upgrade sbt contract, name , symbol, decimals is not chanaged.', async function() {
      
      const sbtV2 = (await upgrades.upgradeProxy(
        sbtContract.address,
        this.sbtV2Impl,
      )) as NFTDerivativeProtocolTokenV2;

      expect([
        await sbtV2.connect(user).name(),
        await sbtV2.connect(user).symbol(),
        await sbtV2.connect(user).valueDecimals(),
      ]).to.deep.eq([
        SBT_NAME,
        SBT_SYMBOL,
        18,
      ]);

      expect(
        await sbtV2.version()
      ).to.deep.eq(
        2,
      );


      expect(
        await sbtV2['balanceOf(uint256)'](SECOND_PROFILE_ID),
      ).to.deep.eq(
        0
      );
      
    });


    it('Should upgrade sbt contract and can buy sbt value.', async function() {
      
      const sbtV2 = (await upgrades.upgradeProxy(
        sbtContract.address,
        this.sbtV2Impl,
      )) as NFTDerivativeProtocolTokenV2;

        //user buy some SBT Values 
        await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});
        
      expect(
        await sbtV2['balanceOf(uint256)'](SECOND_PROFILE_ID),
      ).to.deep.eq(
        original_balance
      );

    });

    it('Should upgrade sbt contract and can call V2 function.', async function() {
      
      const sbtV2 = (await upgrades.upgradeProxy(
        sbtContract.address,
        this.sbtV2Impl,
      )) as NFTDerivativeProtocolTokenV2;

        await sbtV2.connect(user).setSigner(userTwoAddress);

        expect (
          await sbtV2.connect(user).getSigner()
        ).to.eq(userTwoAddress);
        

    });
  });
});