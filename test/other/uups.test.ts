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
  derivativeNFTV1Impl,
  governanceAddress,
  sbtImpl,
  sbtContract,
  bankTreasuryContract,
  bankTreasuryImpl,
  sbtLibs,
} from '../__setup.spec';

export let mockManagerV2Impl: ManagerV2;
export let sbtImplV2: NFTDerivativeProtocolTokenV2;
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
          governanceAddress)
        ).to.be.revertedWith(ERRORS.UUPSINITIALIZED);
    });

    describe("#upgrade", () => {
      beforeEach(async () => {

        sbtImplV2 = await new NFTDerivativeProtocolTokenV2__factory(sbtLibs, deployer).deploy();
        bankTreasuryImplV2 = await new BankTreasuryV2__factory(deployer).deploy();
        console.log("\t BankTreasury v1 getGovernance(): ", (await bankTreasuryContract.getGovernance()).toUpperCase());
      });
      // it("Authorize check", async () => {
      //   await expect(
      //     sbtContract.connect(user).upgradeTo(sbtImplV2.address)
      //   ).to.revertedWith(ERRORS.UNAUTHORIZED);
      // });

      it("Successful upgrade BankTreasury, previous storage is unchanged", async () => {
        const managerV1Address = (await bankTreasuryContract.getManager()).toUpperCase();
        
        await bankTreasuryContract
          .connect(deployer)
          .upgradeTo(bankTreasuryImplV2.address);

        const v2 = new BankTreasuryV2__factory(deployer).attach(bankTreasuryContract.address);

        console.log("\n\t BankTreasury v2 getManager(): ", (await v2.getManager()).toUpperCase());
        expect((await v2.getManager()).toUpperCase()).to.eq(managerV1Address.toUpperCase());
        console.log("\t BankTreasury v2 getGovernance(): ", (await v2.getGovernance()).toUpperCase());
        
      });
      

      it("Successful upgrade NFTDerivativeProtocolToken, version should from 1 upgrade to 2, and signer is set to user address", async () => {
          
        const data = sbtImplV2.interface.encodeFunctionData("setSigner", [
          userAddress,
        ]);
        
        await sbtContract
          .connect(deployer)
          .upgradeToAndCall(sbtImplV2.address, data);

        const v2 = new NFTDerivativeProtocolTokenV2__factory(sbtLibs, deployer).attach(sbtContract.address);
         expect(await v2.version()).to.eq(2);
         expect(await v2.getSigner()).to.eq(userAddress);

        //  expect((await sbtContract.getBankTreasury()).toUpperCase()).to.eq(bankTreasuryContract.address.toUpperCase());
      });
      
    });

  });
  
});