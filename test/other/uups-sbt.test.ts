import '@nomiclabs/hardhat-ethers';
import {expectEvent, expectRevert} from '@openzeppelin/test-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
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
  sbtContract,
  bankTreasuryContract,
  bankTreasuryImpl,
  LOCKUP_DURATION,
} from '../__setup.spec';

export let mockManagerV2Impl: ManagerV2;
export let sbtProxyV2: NFTDerivativeProtocolTokenV2;
export let bankTreasuryImplV2: BankTreasuryV2;

makeSuiteCleanRoom('UUPS ability', function () {
  describe("Deployment", () => {
    it("Proxy state", async () => {
      // sbtContract.connect(governance).
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
          governanceAddress,
          sbtMetadataDescriptor.address
          )
        ).to.be.revertedWith(ERRORS.UUPSINITIALIZED);
    });

    describe("#upgrade", () => {
      beforeEach(async () => {

        sbtProxyV2 = await new NFTDerivativeProtocolTokenV2__factory(deployer).deploy();

      });

      // it("Authorize check", async () => {
      //   await expect(
      //     sbtContract.connect(user).upgradeTo(sbtProxyV2.address)
      //   ).to.revertedWith(ERRORS.UNAUTHORIZED);
      // });

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
    
      it("Successful upgrade SBT, version should from 1 upgrade to 2, and signer is set to user address", async () => {
          
        const data = sbtProxyV2.interface.encodeFunctionData("setSigner", [
          userAddress,
        ]);

        await sbtContract
          .connect(deployer)
          .upgradeToAndCall(sbtProxyV2.address, data);

        const v2 = new NFTDerivativeProtocolTokenV2__factory(deployer).attach(sbtContract.address);
        // const v2 = new VaultV2__factory(owner).attach(vaultV1Proxy.address);

         expect(await v2.version()).to.eq(2);
         expect(await v2.getSigner()).to.eq(userAddress);

      });
      
    });

  });
  
});