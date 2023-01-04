import '@nomiclabs/hardhat-ethers';
import {expectEvent, expectRevert} from '@openzeppelin/test-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import {
  ManagerV2,
  ManagerV2__factory,
  // ManagerV2_BadRevision,
  // ManagerV2_BadRevision__factory,
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
  NDPT_NAME,
  NDPT_SYMBOL,
  NDPT_DECIMALS,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  user,
  managerLibs,
  userAddress,
  userTwoAddress,
  governance,
  derivativeNFTV1Impl,
  governanceAddress,
  ndptImpl,
  ndptContract,
  ndptAddress,
  bankTreasuryContract,
  bankTreasuryImpl,
  
} from '../__setup.spec';

export let mockManagerV2Impl: ManagerV2;
export let ndptImplV2: NFTDerivativeProtocolTokenV2;
export let bankTreasuryImplV2: BankTreasuryV2;

makeSuiteCleanRoom('UUPS ability', function () {
  describe("Deployment", () => {
    it("Proxy state", async () => {
      // ndptContract.connect(governance).
      const name = await ndptContract.name();
      const symbol = await ndptContract.symbol();
      const decimals = await ndptContract.valueDecimals();
      expect([
        await ndptContract.name(),
        await ndptContract.symbol(),
        await ndptContract.valueDecimals(),
      ]).to.deep.eq([
        NDPT_NAME,
        NDPT_SYMBOL,
        18,
      ]);
    });

    it("Attempt to initialize the original NDPT contract should revert", async () => {
      await expect(
        ndptContract.connect(user).initialize(
          NDPT_NAME, 
          NDPT_SYMBOL, 
          8,
          governanceAddress)
        ).to.be.revertedWith(ERRORS.UUPSINITIALIZED);
    });

    describe("#upgrade", () => {
      beforeEach(async () => {
        ndptImplV2 = await new NFTDerivativeProtocolTokenV2__factory(deployer).deploy();
        bankTreasuryImplV2 = await new BankTreasuryV2__factory(deployer).deploy();
      });
      it("Authorize check", async () => {
        await expect(
          ndptContract.connect(user).upgradeTo(ndptImplV2.address)
        ).to.revertedWith(ERRORS.UNAUTHORIZED);
      });

      it("Successful upgrade BankTreasury, previous storage is unchanged", async () => {
        const managerV1Address = (await bankTreasuryContract.getManager()).toUpperCase();
        
        await bankTreasuryContract
          .connect(deployer)
          .upgradeTo(bankTreasuryImplV2.address);

        const v2 = new BankTreasuryV2__factory(deployer).attach(bankTreasuryContract.address);

        console.log("v2.MANAGER: ", (await v2.getManager()).toUpperCase());
         expect((await v2.getManager()).toUpperCase()).to.eq(managerV1Address.toUpperCase());
      });
      

      it("Successful upgrade NFTDerivativeProtocolToken, version should from 1 upgrade to 2, and signer is set to user address", async () => {
        expect(await ndptContract.version()).to.eq(1);
        const managerV1Address = (await ndptContract.getManager()).toUpperCase();
        
        const data = ndptImplV2.interface.encodeFunctionData("setSigner", [
          userAddress,
        ]);
        
        await ndptContract
          .connect(deployer)
          .upgradeToAndCall(ndptImplV2.address, data);

        const v2 = new NFTDerivativeProtocolTokenV2__factory(deployer).attach(ndptContract.address);
         expect(await v2.version()).to.eq(2);
         expect(await v2.getSigner()).to.eq(userAddress);
        //  console.log("v2.MANAGER: ", (await v2.getManager()).toUpperCase());
         expect((await v2.getManager()).toUpperCase()).to.eq(managerV1Address.toUpperCase());
         expect((await ndptContract.getBankTreasury()).toUpperCase()).to.eq(bankTreasuryContract.address.toUpperCase());
      });
      
    });

  });
  
});