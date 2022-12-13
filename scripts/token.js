/*

$ npx hardhat run scripts/token.js
*/

const { ethers } = require('hardhat');
const contract = artifacts.require('NoAV1');
const { NOAV1_ADDRESS } = require('./addresses.js');

async function main() {
  const [deployer, admin, organizer, user1,user2,user3,user4] = await ethers.getSigners();

  const contractAddress = NOAV1_ADDRESS;
  console.log("Proxy contract address: ", contractAddress);


  const contractProxy = await ethers.getContractAt(contract.abi, contractAddress);

  // const tokenId=1;
  // const projectId=1;

  // console.log("projectId:", projectId);
  // console.log("");

  // const user_address = "0xFABB0ac9d68B0B445fB7357272Ff202C5651694a";

  // const count = await contractProxy['balanceOf(address)'](user_address);
  // console.log("user_address: ", user_address, "count:", count.toNumber());
  // console.log("");

  const tokenName = await contractProxy.name();
  console.log("name: ", tokenName);
  const tokenSymbol = await contractProxy.symbol();
  console.log("symbol: ", tokenSymbol);
}

main();
