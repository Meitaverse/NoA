/*

$ npx hardhat run scripts/burn.js
*/

const { ethers } = require('hardhat');
const contract = require('../artifacts/contracts/NoAV1.sol/NoAV1.json');


async function main() {
  const [deployer, admin, organizer, user1, user2,user3,user4] = await ethers.getSigners();

  const contractAddress = '0x0165878A594ca255338adfa4d48449f69242Eb8F';
  const contractProxy = await ethers.getContractAt(contract.abi, contractAddress);


  const tokenId = 1;
  await contractProxy.connect(user1).burn(tokenId);

  console.log(
    "burn token(1) ok for user: ", user1.address
  );
}

main();
