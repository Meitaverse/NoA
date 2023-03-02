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
  sbtImpl,
  // sbtContract,
  bankTreasuryContract,
  bankTreasuryImpl,
  LOCKUP_DURATION,
  INITIAL_SUPPLY,
  FIRST_PROFILE_ID,
  NickName,
} from '../__setup.spec';
import { parseEther } from 'ethers/lib/utils';
import { createProfileReturningTokenId } from '../helpers/utils';

 let sbtV1Proxy: NFTDerivativeProtocolTokenV1;
 let sbtProxyV2: NFTDerivativeProtocolTokenV2;
 let original_balance = 10000;

makeSuiteCleanRoom('UUPS SBT ability', function () {
  describe("Deployment", () => {
    beforeEach(async () => {

      const implV1Factory = new NFTDerivativeProtocolTokenV1__factory(deployer);

       sbtV1Proxy = (await upgrades.deployProxy(
        implV1Factory,
        [
          SBT_NAME, 
          SBT_SYMBOL, 
          SBT_DECIMALS,
          manager.address,
          sbtMetadataDescriptor.address,
        ],
        { kind: "uups", initializer: "initialize" }
      )) as NFTDerivativeProtocolTokenV1;

      // console.log('sbtV1Proxy: ' , sbtV1Proxy.address);

      });

    it("Proxy state", async () => {
      // sbtContract.connect(governance).
      const name = await sbtV1Proxy.name();
      const symbol = await sbtV1Proxy.symbol();
      const decimals = await sbtV1Proxy.valueDecimals();
      expect([
        await sbtV1Proxy.name(),
        await sbtV1Proxy.symbol(),
        await sbtV1Proxy.valueDecimals(),
      ]).to.deep.eq([
        SBT_NAME,
        SBT_SYMBOL,
        18,
      ]);
    });

    it("Attempt to initialize the original SBT contract should revert", async () => {
      await expect(
        sbtV1Proxy.connect(user).initialize(
          SBT_NAME, 
          SBT_SYMBOL, 
          8,
          governanceAddress,
          sbtMetadataDescriptor.address
          )
        ).to.be.revertedWith(ERRORS.UUPSINITIALIZED);
    });
  });

  describe("#upgrade V2", () => {
    beforeEach(async () => {

      const implV1Factory = new NFTDerivativeProtocolTokenV1__factory(deployer);

      const sbtV1Proxy = (await upgrades.deployProxy(
        implV1Factory,
        [
          SBT_NAME, 
          SBT_SYMBOL, 
          SBT_DECIMALS,
          manager.address,
          sbtMetadataDescriptor.address,
        ],
        { kind: "uups", initializer: "initialize" }
      )) as NFTDerivativeProtocolTokenV1;

      // console.log('sbtV1Proxy: ' , sbtV1Proxy.address);

      await expect(sbtV1Proxy.connect(deployer).setBankTreasury(
        bankTreasuryContract.address, 
        INITIAL_SUPPLY
      )).to.not.be.reverted;
      
      // expect(
      //     await createProfileReturningTokenId({
      //         vars: {
      //         wallet: userAddress,
      //         nickName: NickName,
      //         imageURI: MOCK_PROFILE_URI,
      //       },
      //     }) 
      // ).to.eq(SECOND_PROFILE_ID);

      await expect(manager.connect(user).createProfile({ 
            wallet: userTwoAddress,
            nickName: NickName,
            imageURI: MOCK_PROFILE_URI,
      })).to.not.be.reverted;

      let balance = await sbtV1Proxy['balanceOf(uint256)'](SECOND_PROFILE_ID);
      console.log('balance of user: ' , balance);

      //user buy some SBT Values 
      await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});

      const implV2Factory = new NFTDerivativeProtocolTokenV2__factory(deployer);
      sbtProxyV2 = (await upgrades.upgradeProxy(
        sbtV1Proxy.address,
        implV2Factory,
      )) as NFTDerivativeProtocolTokenV2;
      
      // console.log('sbtProxyV2: ' , sbtProxyV2.address);

    });

    it("New SBT Proxy state", async () => {
      const name = await sbtProxyV2.name();
      const symbol = await sbtProxyV2.symbol();
      const decimals = await sbtProxyV2.valueDecimals();
      expect([
        await sbtProxyV2.name(),
        await sbtProxyV2.symbol(),
        await sbtProxyV2.valueDecimals(),
      ]).to.deep.eq([
        SBT_NAME,
        SBT_SYMBOL,
        18,
      ]);
    });

    it("New SBT Proxy balance of treasury", async () => {
      expect([
        await sbtProxyV2['balanceOf(uint256)'](FIRST_PROFILE_ID),
      ]).to.deep.eq([
        parseEther(INITIAL_SUPPLY.toString()),
      ]);
    });

    it("New SBT Proxy balance of user", async () => {
      expect([
        await sbtProxyV2['balanceOf(uint256)'](SECOND_PROFILE_ID),
      ]).to.deep.eq([
        parseEther(original_balance.toString()),
      ]);

      // await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});
    });



  });

  
  
});