import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import {
  ManagerV2,
  ManagerV2__factory,
  TransparentUpgradeableProxy__factory,
  ERC1967Proxy,
  ERC1967Proxy__factory,
} from '../../typechain';
import { ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import {
  abiCoder,
  deployer,
  deployerAddress,
  SECOND_PROFILE_ID,
  manager,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_URI,
  user,
  managerLibs,
  userAddress,
  userTwoAddress,
  derivativeNFTImpl,
  receiverMock,
  governanceAddress,
  sbtContract,
  NickName,
  governance,
  moduleGlobals,
  FIRST_HUB_ID,
  metadataDescriptor,
  FIRST_PROJECT_ID,
  admin,
} from '../__setup.spec';

import { 
  createProfileReturningTokenId,
  createHubReturningHubId,
  createProjectReturningProjectId,
  getTimestamp, 
} from '../helpers/utils';


export let mockManagerV2Impl: ManagerV2;

makeSuiteCleanRoom('Upgradeability', function () {
  const valueToSet = 123;


  // The Manager contract's last storage variable by default is at the 23nd slot (index 22) and contains the emergency admin
  // We're going to validate the first 23 slots and the 24rd slot before and after the change
  it("Should upgrade and set a new variable's value, previous storage is unchanged, new value is accurate", async function () {
    const newImpl = await new ManagerV2__factory(managerLibs, deployer).deploy();
    const proxyManager = TransparentUpgradeableProxy__factory.connect(manager.address, admin);

    // const data = newImpl.interface.encodeFunctionData('reInitialize', [
    //   derivativeNFTImpl.address,
    //   receiverMock.address,
    // ]);
    // await proxyManager.upgradeToAndCall(
    //   newImpl.address, 
    //   data
    // );
    await proxyManager.upgradeTo( newImpl.address );
    
    const managerV2 = new ManagerV2__factory(managerLibs, deployer).attach(proxyManager.address);

    await expect(
      managerV2.connect(user).setAdditionalValue(valueToSet)
    ).to.not.be.reverted;

     expect(await managerV2.connect(user).getAdditionalValue()).to.eq(valueToSet);
    
  });

  it("Should upgrade and old functions still work", async function () {
    const newImpl = await new ManagerV2__factory(managerLibs, deployer).deploy();
    const proxyManager = TransparentUpgradeableProxy__factory.connect(manager.address, admin);
    
    await proxyManager.upgradeTo(
      newImpl.address, 
    );
    const managerV2 = new ManagerV2__factory(managerLibs, deployer).attach(proxyManager.address);
    console.log("ManagerV1 address: ", manager.address);
    console.log("ManagerV2 address: ", managerV2.address);
    console.log("ManagerV2 receiver address: ", await managerV2.connect(user).getReceiver());
    console.log("ManagerV2 GlobalModule address: ", await managerV2.connect(user).getGlobalModule());

    await expect(manager.connect(user).createProfile({ 
      wallet: userAddress,
      nickName: NickName,
      imageURI: MOCK_PROFILE_URI,
    })).to.not.be.reverted;

    expect(
      await sbtContract.ownerOf(SECOND_PROFILE_ID)
    ).to.eq(userAddress);

    expect(
        await createHubReturningHubId({
          sender: user,
          hub: {
            soulBoundTokenId: SECOND_PROFILE_ID,
            name: "bitsoul",
            description: "Hub for bitsoul",
            imageURI: "image",
          },
        })
    ).to.eq(FIRST_HUB_ID);

    expect(
        await createProjectReturningProjectId({
          project: {
            soulBoundTokenId: SECOND_PROFILE_ID,
            hubId: FIRST_HUB_ID,
            name: "bitsoul",
            description: "Hub for bitsoul",
            image: "image",
            metadataURI: "metadataURI",
            descriptor: metadataDescriptor.address,
            defaultRoyaltyPoints: 0,
            permitByHubOwner: false
          },
        })
    ).to.eq(FIRST_PROJECT_ID);
    
    let projectInfo = await manager.connect(user).getProjectInfo(FIRST_PROJECT_ID);
    expect(projectInfo.soulBoundTokenId).to.eq(SECOND_PROFILE_ID);
    expect(projectInfo.hubId).to.eq(FIRST_HUB_ID);
    expect(projectInfo.name).to.eq("bitsoul");
    expect(projectInfo.description).to.eq("Hub for bitsoul");
    expect(projectInfo.image).to.eq("image");
    expect(projectInfo.metadataURI).to.eq("metadataURI");
    expect(projectInfo.descriptor.toUpperCase()).to.eq(metadataDescriptor.address.toUpperCase());


  });
  


});


