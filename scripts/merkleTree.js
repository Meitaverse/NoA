// 

/*
$ npx hardhat run scripts/merkleTree.js
*/

const { ethers } = require('hardhat');
const contract = artifacts.require('NoAV1');
const { NOAV1_ADDRESS } = require('./addresses.js');


async function main() {
  const [deployer, admin, organizer, user1, user2,user3,user4] = await ethers.getSigners();

  const contractAddress = NOAV1_ADDRESS;
  const contractProxy = await ethers.getContractAt(contract.abi, contractAddress);

  //admin
  const adminAddr = await admin.getAddress();
  const organizerAddr = await organizer.getAddress();
  const user1Addr = await user1.getAddress();
  console.log(
    "organizerAddr:",
    organizerAddr
  );
  console.log(
    "user1Addr:",
    user1Addr
  );


  //设置event的root
  const eventId = 1;
  const root = "0x185622dc03039bc70cbb9ac9a4a086aec201f986b154ec4c55dad48c0a474e23";
  await contractProxy.connect(organizer).setMerkleRoot(eventId, root);


}

main();
