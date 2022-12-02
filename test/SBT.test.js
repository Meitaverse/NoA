/**
 
 $ npx hardhat test test/SBT.test.js
 */
const { ethers, upgrades } = require('hardhat');
const { expect } = require('chai');


async function deploySBT(name, symbol, deployer) {
      
    // Deploy the SBT metadata sbtDescriptor contract
    const SBTMetadataDescriptor = await ethers.getContractFactory('SBTMetadataDescriptor');
    const sbtDescriptor = await SBTMetadataDescriptor.deploy();
    await sbtDescriptor.deployed();
    console.log('SBTMetadataDescriptor deployed to:', sbtDescriptor.address);
    console.log("");

    const SoulBoundTokenV1 = await ethers.getContractFactory('SoulBoundTokenV1');

    const organization = "ShowDao";
    const ownerToken = deployer.address;
    const minterOfToken = deployer.address;
    const signer = deployer.address;

    const soulBoundToken = await upgrades.deployProxy(SoulBoundTokenV1, [
        name, 
        symbol, 
        sbtDescriptor.address
        // organization,
        // ownerToken,
        // minterOfToken,
        // signer
    ], {
      initializer: "initialize",
      kind: "uups",
    });

    await soulBoundToken.deployed();

    console.log("soulBoundToken.address: ", soulBoundToken.address);
    return soulBoundToken;
}

describe('SBT', () => {

  const name = 'Soul Bound Token For ShowDao';
  const symbol = 'SBT';

  beforeEach(async function () {
    let [deployer]  = await ethers.getSigners();
    this.token = await deploySBT(name, symbol, deployer);
    console.log('SBT deployed to:',  this.token.address);
  })

  describe("version", () => {
    it('version should returns 1', async function () {
      expect(await this.token.version()).to.be.equal(1);
    });
  });

})