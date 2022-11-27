/**
 
 $ npx hardhat test test/SBT.test.js
 */
const { ethers, upgrades } = require('hardhat');


async function deploySBT(name, symbol, deployer) {
      
    // Deploy the SBT metadata sbtDescriptor contract
    const SBTMetadataDescriptor = await ethers.getContractFactory('SBTMetadataDescriptor');
    const sbtDescriptor = await SBTMetadataDescriptor.deploy();
    await sbtDescriptor.deployed();
    console.log('SBTMetadataDescriptor deployed to:', sbtDescriptor.address);
    console.log("");

    const SoulBoundTokenV1 = await ethers.getContractFactory('SoulBoundTokenV1');

    // const name = "Soul Bound Token";
    // const symbol = "SBT";
    const organization = "ShowDao";
    const transferable = false;
    const mintable = true;
    const ownerofToken = deployer.address;
    const minterOfToken = deployer.address;
    const signer = deployer.address;

    const soulBoundToken = await upgrades.deployProxy(SoulBoundTokenV1, [
        name, 
        symbol, 
        sbtDescriptor.address,
        organization,
        transferable,
        mintable,
        ownerofToken,
        minterOfToken,
        signer
    ], {
      initializer: "initialize",
      kind: "uups",
    });

    await soulBoundToken.deployed();

    console.log("soulBoundToken.address: ", soulBoundToken.address);
    return soulBoundToken;
}

describe('NoA', () => {

  const name = 'Soul Bound Token For ShowDao';
  const symbol = 'SBT';

  beforeEach(async function () {
    let deployer  = await ethers.getSigners();
    this.token = await deploySBT(name, symbol, deployer);
    console.log('SBT deployed to:',  this.token.address);
  })


})