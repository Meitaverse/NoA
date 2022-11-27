const { BigNumber } = require('ethers');
const { ethers, upgrades } = require("hardhat");

const TransparentUpgradeableProxy = require('@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json');
const ProxyAdmin = require('@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol/ProxyAdmin.json');
const {getInitializerData} = require("@openzeppelin/hardhat-upgrades/dist/utils");
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
let deployer, admin, organizer, user1, user2, user3, user4;

async function fetchOrDeployAdminProxy(proxyAdminAddress) {
    const address = proxyAdminAddress ? ethers.utils.getAddressFromAccount(ethers.utils.parseAccount(proxyAdminAddress)) : null;
    
    const proxyAdminFactory = await ethers.getContractFactory(ProxyAdmin.abi, ProxyAdmin.bytecode);
    const proxyAdmin = proxyAdminAddress ? (await proxyAdminFactory.attach(address)) : (await proxyAdminFactory.deploy());
    await proxyAdmin.deployed();

    console.log("ProxyAdmin deployed to:", proxyAdmin.address);

    return proxyAdmin
}


async function deployProxy(proxyAdmin, ImplFactory, args, opts) {
  if (!Array.isArray(args)) {
      opts = args;
      args = [];
  }
  const impl = await ImplFactory.deploy()
  await impl.deployed();

  const ProxyFactory = await ethers.getContractFactory(TransparentUpgradeableProxy.abi, TransparentUpgradeableProxy.bytecode);
  const data = getInitializerData(impl.interface, args, opts.initializer);
  const proxy = await ProxyFactory.deploy(impl.address, proxyAdmin.address, data)
  await proxy.deployed();
  return await ImplFactory.attach(proxy.address)
}

async function main() {
   [deployer, admin, organizer, user1, user2, user3, user4] = await ethers.getSigners();
  
  const name = ' Proof Of Attendance Show';
  const symbol = 'POAS';
  const decimals = 0;

  // Deploy the dao metadata descriptor contract
  const NoAMetadataDescriptor = await ethers.getContractFactory('NoAMetadataDescriptor');
  const descriptor = await NoAMetadataDescriptor.deploy();
  await descriptor.deployed();
  console.log('NoAMetadataDescriptor deployed to:', descriptor.address);
  console.log("");

  const NoA = await ethers.getContractFactory("NoAV1");

  const proxyAdmin = await fetchOrDeployAdminProxy();
  const contractProxy = await deployProxy(proxyAdmin, NoA, [name, symbol, decimals, descriptor.address], { initializer: 'initialize' });

  await contractProxy.deployed();

  console.log("Proxy contract deployed to:", contractProxy.address);


  const event_ = {
    organizer: ZERO_ADDRESS,
    eventName: "Test Slot", //event名称
    eventDescription: "Test Slot Description",
    eventImage: "https://example.com/slot/test_slot.png",
    mintMax: 200
  };

  let tx = await contractProxy.connect(organizer).createEvent(event_);

  let receipt = await tx.wait();
  let transferEvent = receipt.events.filter(e => e.event === 'EventAdded')[0];
  const eventId = transferEvent.args['eventId'];
  console.log("eventId:", eventId.toNumber());
  console.log("");

  const slotDetail_ = {
    name: 'BigShow',
    description: 'for testing desc',
    image: '',
    eventId:  eventId.toNumber(),
    eventMetadataURI: "https://example.com/event/" + eventId.toString(),
  }

  tx = await contractProxy.mint(
    slotDetail_,
     user1.address
  );
   receipt = await tx.wait();
   transferEvent = receipt.events.filter(e => e.event === 'EventToken')[0];
   let tokenId = transferEvent.args['tokenId'];
   console.log("tokenId:", tokenId.toNumber());
   console.log("");

  const owerOfToken = await contractProxy.ownerOf(tokenId.toNumber());
  console.log("owerOfToken address:", owerOfToken);
  console.log("");
  
  const count = await contractProxy['balanceOf(uint256)'](tokenId.toNumber());
  console.log("count:", count.toNumber());
  console.log("");


  const slotOf =  await contractProxy.slotOf(tokenId.toNumber());
  console.log("slotOf:", slotOf.toString());
  console.log("");

  const slotCount = await contractProxy.slotCount();
  console.log("slotCount:", slotCount.toNumber());
  console.log("");

  const contractURI =  await contractProxy.contractURI();
  console.log("contractURI:", contractURI);
  console.log("");
  
  const tokenURI =  await contractProxy.tokenURI(tokenId);
  console.log("tokenURI:", tokenURI);
  console.log("");

  const slotURI =  await contractProxy.slotURI(slotOf);
  console.log("slotURI:", slotURI);
  

}

main();