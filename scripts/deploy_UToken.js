const { ethers, upgrades } = require('hardhat');

async function main() {
  const UTokenV1 = await ethers.getContractFactory('UTokenV1');

  console.log('Deploying UToken Token...');

  const uToken = await upgrades.deployProxy(UTokenV1, [], {
    initializer: 'initialize',
  });
  await uToken.deployed();

  console.log('UToken Token deployed to:', uToken.address);
}

main();

//npx hardhat run scripts/deployToken.js