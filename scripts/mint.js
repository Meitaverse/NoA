/*

$ npx hardhat run scripts/mint.js
*/

const { ethers } = require('hardhat');
const contract = require('../artifacts/contracts/NoAV1.sol/NoAV1.json');

async function main() {
  const [deployer, admin, organizer, user1, user2,user3,user4] = await ethers.getSigners();

  const contractAddress = '0x0165878A594ca255338adfa4d48449f69242Eb8F';
  const contractProxy = await ethers.getContractAt(contract.abi, contractAddress);


  const to_ = await deployer.getAddress();
  console.log(
    "to_ Address:",
    to_
  );

  const eventId = 1;
  
  let slotDetail_ = {
    name: 'BigShow#1',
    description: 'Testing desc',
    image: 'https://bitsoul.me/img/1.jpg',
    eventId:  eventId,
    eventMetadataURI: "https://bitsoul.me/event/" + eventId.toString(),
  };
  

  const proof =  [];

  let tx = await contractProxy.connect(deployer).mint(slotDetail_, to_, proof);

  let receipt = await tx.wait();
  let transferEvent = receipt.events.filter(e => e.event === 'EventToken')[0];
  let tokenId = transferEvent.args['tokenId'];

  console.log(
    "mint NoA ok, tokenId: ", tokenId.toNumber()
  );
}

main();
