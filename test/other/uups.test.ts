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
  derivativeNFTImpl,
  governanceAddress,
  sbtMetadataDescriptor,
  sbtImpl,
  sbtContract,
  bankTreasuryContract,
  bankTreasuryImpl,
  sbtLibs,
  LOCKUP_DURATION,
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
          governanceAddress,
          sbtMetadataDescriptor.address
          )
        ).to.be.revertedWith(ERRORS.UUPSINITIALIZED);
    });

    describe("#upgrade", () => {
      beforeEach(async () => {

        sbtImplV2 = await new NFTDerivativeProtocolTokenV2__factory(sbtLibs, deployer).deploy();
        bankTreasuryImplV2 = await new BankTreasuryV2__factory(deployer).deploy();
        // console.log("\t BankTreasury v1 getGovernance(): ", (await bankTreasuryContract.getGovernance()).toUpperCase());
      });

      // it("Authorize check", async () => {
      //   await expect(
      //     sbtContract.connect(user).upgradeTo(sbtImplV2.address)
      //   ).to.revertedWith(ERRORS.UNAUTHORIZED);
      // });

      it("Successful upgrade BankTreasury, previous storage is unchanged, etc. governance and manager address", async () => {
        const managerV1Address = (await bankTreasuryContract.getManager()).toUpperCase();
        console.log("\n\t managerV1Address: ", managerV1Address.toUpperCase());
        
        await bankTreasuryContract
        .connect(deployer)
        .upgradeTo(bankTreasuryImplV2.address);
        
        const v2 = new BankTreasuryV2__factory(deployer).attach(bankTreasuryContract.address);
        console.log("\t BankTreasury v2 manager: ", (await v2.getManager()).toUpperCase());
        
        expect((await v2.getManager()).toUpperCase()).to.eq(managerV1Address.toUpperCase());
        
        const governanceV1Address = (await bankTreasuryContract.getGovernance()).toUpperCase();
        console.log("\n\t governanceV1Address: ", governanceV1Address.toUpperCase());
        console.log("\t BankTreasury v2 getGovernance(): ", (await v2.getGovernance()).toUpperCase());
        expect((await v2.getGovernance()).toUpperCase()).to.eq(governanceV1Address.toUpperCase());
        
      });

      it("Successful upgrade BankTreasury, constructor paramters is changed, etc. lockupDuration", async () => {
        const lockupDurationV1 = (await bankTreasuryContract.getLockupDuration()).toNumber();
        console.log("\n\t lockupDurationV1: ", lockupDurationV1);

        await bankTreasuryContract
          .connect(deployer)
          .upgradeTo(bankTreasuryImplV2.address);
/*
        const data = bankTreasuryImplV2.interface.encodeFunctionData("setLockupDuration", [
          LOCKUP_DURATION,
        ]);
        
        await bankTreasuryContract
          .connect(deployer)
          .upgradeToAndCall(bankTreasuryImplV2.address, data);

*/
        const v2 = new BankTreasuryV2__factory(deployer).attach(bankTreasuryContract.address);
        console.log("\t lockupDurationV2: ", (await v2.getLockupDuration()).toNumber());
        
       expect((await v2.getLockupDuration()).toNumber()).to.eq(lockupDurationV1);

        
      });
      

      it("Successful upgrade BankTreasury, immutable storage is unchanged, etc. soulBoundTokenIdBankTreasury", async () => {
        const soulBoundTokenIdBankTreasury = (await bankTreasuryContract.soulBoundTokenIdBankTreasury()).toNumber();
        console.log("\n\t soulBoundTokenIdBankTreasury: ", soulBoundTokenIdBankTreasury);

        await bankTreasuryContract
          .connect(deployer)
          .upgradeTo(bankTreasuryImplV2.address);

        const v2 = new BankTreasuryV2__factory(deployer).attach(bankTreasuryContract.address);
        console.log("\t soulBoundTokenIdBankTreasury V2: ", (await v2.soulBoundTokenIdBankTreasury()).toNumber());
        
       expect((await v2.soulBoundTokenIdBankTreasury()).toNumber()).to.eq(soulBoundTokenIdBankTreasury);

        
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

      });
      
    });

  });
  
});