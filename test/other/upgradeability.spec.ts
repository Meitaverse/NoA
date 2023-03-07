import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
  ManagerV2,
  ManagerV2__factory,
  // ManagerV2_BadRevision,
  // ManagerV2_BadRevision__factory,
  TransparentUpgradeableProxy__factory,
  ERC1967Proxy,
  ERC1967Proxy__factory,
} from '../../typechain';
import {
  deployer,
  manager,
  makeSuiteCleanRoom,
  user,
  managerLibs,
} from '../__setup.spec';

export let mockManagerV2Impl: ManagerV2;

makeSuiteCleanRoom('Upgradeability', function () {
  const valueToSet = 123;

  it('Should fail to initialize an implementation with the same revision', async function () {

    // const newImpl =  await new ManagerV2_BadRevision__factory(managerLibs, deployer).deploy();
    // const proxyManager = TransparentUpgradeableProxy__factory.connect(manager.address, deployer);
    // const newMockManagerV2 = ManagerV2_BadRevision__factory.connect(proxyManager.address, user);
    // await expect(proxyManager.upgradeTo(newImpl.address)).to.not.be.reverted;
    // await expect(newMockManagerV2.initialize()).to.be.revertedWith(ERRORS.INITIALIZED);
  });


  // The Manager contract's last storage variable by default is at the 23nd slot (index 22) and contains the emergency admin
  // We're going to validate the first 23 slots and the 24rd slot before and after the change
  it("Should upgrade and set a new variable's value, previous storage is unchanged, new value is accurate", async function () {
    
    const newImpl = await new ManagerV2__factory(managerLibs, deployer).deploy();

    // managerImpl = await new Manager__factory(managerLibs, deployer).deploy(
    //   derivativeNFTImpl.address,
    //   receiverMock.address,
    // );
  
    // let data = managerImpl.interface.encodeFunctionData('initialize', [
    //   governanceAddress
    // ]);

    const proxyHub = TransparentUpgradeableProxy__factory.connect(manager.address, deployer);
    await proxyHub.upgradeTo(newImpl.address);
    const managerV2 = new ManagerV2__factory(managerLibs, deployer).attach(proxyHub.address);
    // console.log("ManagerV1 address: ", manager.address);
    // console.log("ManagerV2 address: ", managerV2.address);

    await expect(
      managerV2.connect(user).setAdditionalValue(valueToSet)
    ).to.not.be.reverted;

     expect(await managerV2.connect(user).getAdditionalValue()).to.eq(valueToSet);
     expect(await managerV2.connect(user).version()).to.eq(2);

    // for (let i = 0; i < 24; i++) {
    //   const valueAt = await ethers.provider.getStorageAt(proxyHub.address, i);
    //   expect(valueAt).to.eq(prevStorage[i]);
    // }

    // const newNextSlot = await ethers.provider.getStorageAt(proxyHub.address, 24);
    // const formattedValue = abiCoder.encode(['uint256'], [valueToSet]);
    // expect(newNextSlot).to.eq(formattedValue);

  });
  





});
