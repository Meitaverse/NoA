import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
  // CollectNFT__factory,
  // FeeFollowModule__factory,
  // FollowNFT__factory,
  DerivativeNFT__factory,
  NFTDerivativeProtocolTokenV1__factory,
  Manager__factory,
  ModuleGlobals__factory,
  // TimedFeeCollectModule__factory,
  TransparentUpgradeableProxy__factory,
} from '../../typechain';
import { ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import {
  BPS_MAX,
  deployer,
  deployerAddress,
  governanceAddress,
  managerLibs,
  manager,
  managerImpl,
  SBT_NAME,
  SBT_SYMBOL,
  makeSuiteCleanRoom,
  moduleGlobals,
  TREASURY_FEE_BPS,
  user,
  userAddress,
  receiverMock,
  derivativeNFTImpl,
  sbtContract,
  bankTreasuryContract,
  PublishRoyaltySBT,
  voucherContract,
  marketPlaceContract,
  admin,
  adminAddress
  
} from '../__setup.spec';

makeSuiteCleanRoom('deployment validation', () => {




  it('Deployer should not be able to initialize implementation due to address(this) check', async function () {
    await expect(
      managerImpl.initialize(
        derivativeNFTImpl.address, 
        ZERO_ADDRESS,
        governanceAddress
        )
    ).to.be.revertedWith(ERRORS.CANNOT_INIT_IMPL);
  });

  it("User should fail to initialize manager proxy after it's already been initialized via the proxy constructor", async function () {
    // Initialization happens in __setup.spec.ts
    await expect(
      manager.connect(user).initialize(
        derivativeNFTImpl.address, 
        ZERO_ADDRESS,
        userAddress, 
        )
      ).to.be.revertedWith(ERRORS.INITIALIZED);
    });
    

  it('Deployer should deploy a Manager implementation, a proxy, initialize it, and fail to initialize it again', async function () {
    const newImpl = await new Manager__factory(managerLibs, deployer).deploy(
      
    );

    let data = newImpl.interface.encodeFunctionData('initialize', [
      derivativeNFTImpl.address,
      receiverMock.address,
      governanceAddress,
    ]);

    const proxy = await new TransparentUpgradeableProxy__factory(deployer).deploy(
      newImpl.address,
      adminAddress,
      data
    );

    await expect(
      Manager__factory.connect(proxy.address, user).initialize(
        derivativeNFTImpl.address,
        receiverMock.address,
        userAddress, 
        )
    ).to.be.revertedWith(ERRORS.INITIALIZED);
  });

  it('User should not be able to call admin-only functions on proxy (should fallback) since deployer is admin', async function () {
    const proxy = TransparentUpgradeableProxy__factory.connect(manager.address, user);
    await expect(proxy.upgradeTo(userAddress)).to.be.revertedWith(ERRORS.NO_SELECTOR);
    await expect(proxy.upgradeToAndCall(userAddress, [])).to.be.revertedWith(ERRORS.NO_SELECTOR);
  });
  
  it('Deployer should be able to call admin-only functions on proxy', async function () {
    const proxy = TransparentUpgradeableProxy__factory.connect(manager.address, admin);
    const newImpl = await new Manager__factory(managerLibs, admin).deploy();
    await expect(proxy.upgradeTo(newImpl.address)).to.not.be.reverted;
  });
  
  it('Deployer should transfer admin to user, deployer should fail to call admin-only functions, user should call admin-only functions', async function () {
    const proxy = TransparentUpgradeableProxy__factory.connect(manager.address, admin);
    
    await expect(proxy.changeAdmin(userAddress)).to.not.be.reverted;
    
    await expect(proxy.upgradeTo(userAddress)).to.be.revertedWith(ERRORS.NO_SELECTOR);
    await expect(proxy.upgradeToAndCall(userAddress, [])).to.be.revertedWith(ERRORS.NO_SELECTOR);
    
    const newImpl = await new Manager__factory(managerLibs, admin).deploy();
    
    await expect(proxy.connect(user).upgradeTo(newImpl.address)).to.not.be.reverted;
  });
  
  it('Should fail to deploy module globals with zero address manager', async function () {
    await expect(
      new ModuleGlobals__factory(deployer).deploy(
        ZERO_ADDRESS, 
        sbtContract.address,
        governanceAddress,
        bankTreasuryContract.address, 
        marketPlaceContract.address,
        voucherContract.address,
        TREASURY_FEE_BPS,
        PublishRoyaltySBT
      )
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  it('Should fail to deploy module globals with zero address SBT', async function () {
    await expect(
      new ModuleGlobals__factory(deployer).deploy(
        manager.address, 
        ZERO_ADDRESS,
        governanceAddress,
        bankTreasuryContract.address, 
        marketPlaceContract.address,
        voucherContract.address,
        TREASURY_FEE_BPS,
        PublishRoyaltySBT
      )
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  it('Should fail to deploy module globals with zero address governance', async function () {
    await expect(
      new ModuleGlobals__factory(deployer).deploy(
        manager.address,
        sbtContract.address,
        ZERO_ADDRESS, 
        bankTreasuryContract.address, 
        marketPlaceContract.address,
        voucherContract.address,
        TREASURY_FEE_BPS,
        PublishRoyaltySBT
      )
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  it('Should fail to deploy module globals with zero address treasury', async function () {
    await expect(
      new ModuleGlobals__factory(deployer).deploy(
        manager.address,
        sbtContract.address,
        governanceAddress, 
        ZERO_ADDRESS, 
        marketPlaceContract.address,
        voucherContract.address,
        TREASURY_FEE_BPS,
        PublishRoyaltySBT
        )
      ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  it('Should fail to deploy module globals with zero address voucher', async function () {
    await expect(
      new ModuleGlobals__factory(deployer).deploy(
        manager.address,
        sbtContract.address,
        governanceAddress, 
        bankTreasuryContract.address, 
        marketPlaceContract.address,
        ZERO_ADDRESS, 
        TREASURY_FEE_BPS,
        PublishRoyaltySBT
        )
      ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });
    
  it('Should fail to deploy module globals with treausury fee > BPS_MAX / 2', async function () {
      await expect(
        new ModuleGlobals__factory(deployer).deploy(
          manager.address,
          sbtContract.address,
          governanceAddress, 
          bankTreasuryContract.address, 
          marketPlaceContract.address,
          voucherContract.address,
          5001,
          PublishRoyaltySBT
          )
        ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });
      

  it('Should fail to deploy a fee module with treasury fee equal to or higher than maximum BPS', async function () {
    await expect(
      new ModuleGlobals__factory(deployer).deploy(
        manager.address,
        sbtContract.address,
        governanceAddress, 
        bankTreasuryContract.address,  
        marketPlaceContract.address,
        voucherContract.address,
        BPS_MAX,
        PublishRoyaltySBT
        )
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);

    await expect(
      new ModuleGlobals__factory(deployer).deploy(
        manager.address,
        sbtContract.address,
        governanceAddress, 
        bankTreasuryContract.address, 
        marketPlaceContract.address,
        voucherContract.address,
        BPS_MAX + 1,
        PublishRoyaltySBT
        )
    ).to.be.revertedWith(ERRORS.INIT_PARAMS_INVALID);
  });

  
  it('Validates SBT name & symbol &Owner', async function () {
    const name = await sbtContract.name();
    const symbol = await sbtContract.symbol();
    const decimals = await sbtContract.valueDecimals();

    expect(name).to.eq(SBT_NAME);
    expect(symbol).to.eq(SBT_SYMBOL);
    expect(decimals).to.eq(18);
  });
  
  it('BankTreasury transaction count is zero', async function () {
    const count = await bankTreasuryContract.getTransactionCount();
    expect(count).to.eq(0);
  });

  it('Manager version is 1', async function () {
    expect(await manager.version()).to.eq(1);
  });


});
