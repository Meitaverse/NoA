/*

$ npx hardhat run scripts/createEvent.js
*/

const { ethers } = require('hardhat');
const contract = require('../artifacts/contracts/NoAV1.sol/NoAV1.json');


async function main() {
  const [deployer, admin, organizer, user1,user2,user3,user4] = await ethers.getSigners();

  const contractAddress = '0x0165878A594ca255338adfa4d48449f69242Eb8F';
  console.log("Proxy contract address: ", contractAddress);


  const contractProxy = await ethers.getContractAt(contract.abi, contractAddress);

  const organizerAddr = await organizer.getAddress();
  console.log(
    "organizerAddr:",
    organizerAddr
  );

  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
  const event_ = {
    organizer: ZERO_ADDRESS,
    eventName: "NoATest", //event名称
    eventDescription: "Event Of NoA Test",
    eventImage: "https://example.com/slot/test_slot.png",
    eventMetadataURI: "",
    mintMax: 200
  };

  let tx = await contractProxy.connect(organizer).createEvent(event_);

  let receipt = await tx.wait();
  let transferEvent = receipt.events.filter(e => e.event === 'EventAdded')[0];
  const eventId = transferEvent.args['eventId'];
  console.log("eventId:", eventId.toNumber());
  console.log("");
}

main();
