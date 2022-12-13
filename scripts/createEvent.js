/*

$ npx hardhat run scripts/createProject.js
*/

const { ethers } = require('hardhat');
const contract = artifacts.require('NoAV1');
const { NOAV1_ADDRESS } = require('./addresses.js');

async function main() {
  const [deployer, admin, organizer, user1,user2,user3,user4] = await ethers.getSigners();

  const contractAddress = NOAV1_ADDRESS;
  console.log("Proxy contract address: ", contractAddress);


  const contractProxy = await ethers.getContractAt(contract.abi, contractAddress);

  const organizerAddr = await organizer.getAddress();
  console.log(
    "organizerAddr:",
    organizerAddr
  );

  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
  const project_ = {
    organizer: ZERO_ADDRESS,
    name: "NoATest", //event名称
    description: "Event Of NoA Test",
    image: "https://example.com/slot/test_slot.png",
    metadataURI: "",
    mintMax: 200
  };

  let tx = await contractProxy.connect(organizer).createProject(project_);

  let receipt = await tx.wait();
  let transferEvent = receipt.events.filter(e => e.event === 'ProjectAdded')[0];
  const projectId = transferEvent.args['projectId'];
  console.log("projectId:", projectId.toNumber());
  console.log("");
}

main();
