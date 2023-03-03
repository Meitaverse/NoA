import '@nomiclabs/hardhat-ethers';
import {expectEvent, expectRevert} from '@openzeppelin/test-helpers';
import { expect } from 'chai';

  // eslint-disable-next-line
import { ethers, upgrades } from 'hardhat';

import {
  ManagerV2,
  ManagerV2__factory,
  TransparentUpgradeableProxy__factory,
  NFTDerivativeProtocolTokenV2__factory,
  ERC1967Proxy,
  ERC1967Proxy__factory,
  NFTDerivativeProtocolTokenV2,
  BankTreasury,
  BankTreasuryV2,
  BankTreasuryV2__factory,
  NFTDerivativeProtocolTokenV1__factory,
  NFTDerivativeProtocolTokenV1,
} from '../../typechain';
import { ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import {
  abiCoder,
  deployer,
  deployerAddress,
  SECOND_PROFILE_ID,
  manager,
  SBT_NAME,
  SBT_SYMBOL,
  SBT_DECIMALS,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  user,
  managerLibs,
  userAddress,
  userTwoAddress,
  governance,
  derivativeNFTImpl,
  governanceAddress,
  sbtMetadataDescriptor,
  bankTreasuryContract,
  LOCKUP_DURATION,
  INITIAL_SUPPLY,
  FIRST_PROFILE_ID,
  NickName,
  sbtContract,
} from '../__setup.spec';
import { parseEther } from 'ethers/lib/utils';
import { createProfileReturningTokenId } from '../helpers/utils';

 let sbtProxyV2: NFTDerivativeProtocolTokenV2;
 let original_balance = 10000;

makeSuiteCleanRoom('SBT upgrade ability', function () {
  /*
  describe("Deployment", () => {
    beforeEach(async () => {

        await manager.connect(user).createProfile({ 
          wallet: userAddress,
          nickName: NickName,
          imageURI: MOCK_PROFILE_URI,
        });

          //user buy some SBT Values 
          await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});
          
          let balance = await sbtContract.connect(user)['balanceOf(uint256)'](SECOND_PROFILE_ID);
          console.log('balance of user: ' , balance);
    
      });

    it("Proxy state", async () => {
      const name = await sbtContract.name();
      const symbol = await sbtContract.symbol();
      const decimals = await sbtContract.valueDecimals();
      expect([
        await sbtContract.name(),
        await sbtContract.symbol(),
        await sbtContract.valueDecimals(),
      ]).to.deep.eq([
        SBT_NAME,
        SBT_SYMBOL,
        18,
      ]);
    });

    it("Attempt to initialize the original SBT contract should revert", async () => {
      await expect(
        sbtContract.connect(user).initialize(
          SBT_NAME, 
          SBT_SYMBOL, 
          8,
          manager.address,
          governanceAddress,
          sbtMetadataDescriptor.address
          )
        ).to.be.reverted;
    });

    it("SBT Proxy balance of user", async () => {
      expect(
        await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID),
      ).to.deep.eq(
        original_balance
      );

    });

  });
  */

  /*
  describe("#upgrade V2", () => {
    beforeEach(async () => {

      await manager.connect(user).createProfile({ 
        wallet: userAddress,
        nickName: NickName,
        imageURI: MOCK_PROFILE_URI,
      });

      
      //user buy some SBT Values 
      await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});

      let balance = await sbtContract.connect(user)['balanceOf(uint256)'](SECOND_PROFILE_ID);
      console.log('sbtContract, balance of user: ' , balance);


    });
    it("Should upgrade and name, symbol decimals is unchanged", async function () {
      const newImpl = await new NFTDerivativeProtocolTokenV2__factory(deployer).deploy();
      const sbtProxyV2 = TransparentUpgradeableProxy__factory.connect(sbtContract.address, deployer);
      
      await sbtProxyV2.upgradeTo(newImpl.address);
      const sbtV2 = new NFTDerivativeProtocolTokenV2__factory(deployer).attach(sbtProxyV2.address);
  
      expect([
        await sbtV2.connect(user).name(),
        await sbtV2.connect(user).symbol(),
        await sbtV2.connect(user).valueDecimals(),
      ]).to.deep.eq([
        SBT_NAME,
        SBT_SYMBOL,
        18,
      ]);

    });
  });
  */
  
  describe("#upgrade V2", () => {
    before('get factories', async function() {
      // this.TokenIsERC20 = await hre.ethers.getContractFactory('TokenIsERC20')
      // this.TokenIsERC20V2 = await hre.ethers.getContractFactory('TokenIsERC20V2')
      this.sbtV2Impl = await new NFTDerivativeProtocolTokenV2__factory(deployer).deploy();
      
    });
    
    it('Should deploy the first smart contract and then upgrade it', async function() {

      // const sbtV2Contract = await upgrades.upgradeProxy(
      //   sbtContract.address,
      //   this.sbtV2Impl
      // );
      // await sbtV2Contract.deployed();
      const sbtV2Contract = (await upgrades.upgradeProxy(
        sbtContract.address,
        this.sbtV2Impl,
      )) as NFTDerivativeProtocolTokenV2;

      expect([
        await sbtV2Contract.connect(user).name(),
        await sbtV2Contract.connect(user).symbol(),
        await sbtV2Contract.connect(user).valueDecimals(),
      ]).to.deep.eq([
        SBT_NAME,
        SBT_SYMBOL,
        18,
      ]);

    });
    
  });
});