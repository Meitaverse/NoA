/*

$ npx hardhat run scripts/mintmanyToUsers.js
*/

const { ethers } = require('hardhat');
const contract = artifacts.require('NoAV1');
const { NOAV1_ADDRESS } = require('./addresses.js');


async function main() {
  const [deployer, admin, organizer, user] = await ethers.getSigners();

  const contractAddress = NOAV1_ADDRESS;
  const contractProxy = await ethers.getContractAt(contract.abi, contractAddress);

  const projectId = 1;

  let slotDetail_ = {
    name: 'BigShow#1',
    description: 'Testing desc',
    image: 'https://bitsoul.me/img/1.jpg',
    projectId:  projectId,
    metadataURI: "https://bitsoul.me/event/" + projectId.toString(),
  };
  
  let to = [
    "0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097", 
    "0x71bE63f3384f5fb98995898A86B02Fb2426c5788",
    "0xFABB0ac9d68B0B445fB7357272Ff202C5651694a",
  ];
  await contractProxy.connect(deployer).mintEventToManyUsers(slotDetail_, to);
  console.log(
    "mintEventToManyUsers ok, to: ", to
  );
}

main();
