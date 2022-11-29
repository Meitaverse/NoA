/*

$ npx hardhat run scripts/mint_SBT.js
*/

const { ethers } = require('hardhat');
const contract = require('../artifacts/contracts/SoulBoundTokenV1.sol/SoulBoundTokenV1.json');

async function main() {
  const [deployer, admin, organizer, user1, user2,user3,user4] = await ethers.getSigners();

  const contractAddress = '0x9A676e781A523b5d0C0e43731313A708CB607508';
  const contractProxy = await ethers.getContractAt(contract.abi, contractAddress);


  const to_ = await admin.getAddress();
  console.log(
    "to_ Address:",
    to_
  );

  const nickName = "Sky Lee";
  const role = "Orgnizer";
  const signature = 0x00;
  

  let tx = await contractProxy.connect(deployer).mint(nickName, role, to_, signature);

  let receipt = await tx.wait();
  let transferEvent = receipt.events.filter(e => e.event === 'Transfer')[0];
  let tokenId = transferEvent.args['_tokenId'];

  console.log(
    "mint SBT ok, tokenId: ", tokenId.toNumber()
  );
}

main();
