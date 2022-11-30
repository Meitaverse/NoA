/*

$ npx hardhat run scripts/burn.js
*/

const { ethers } = require('hardhat');
const contract = artifacts.require('NoAV1');
const { NOAV1_ADDRESS } = require('./addresses.js');


async function main() {
  const [deployer, admin, organizer, user1, user2,user3,user4] = await ethers.getSigners();

  const contractAddress = NOAV1_ADDRESS;
  const contractProxy = await ethers.getContractAt(contract.abi, contractAddress);


  const tokenId = 1;
  await contractProxy.connect(user1).burn(tokenId);

  console.log(
    "burn token(1) ok for user: ", user1.address
  );
}

main();
