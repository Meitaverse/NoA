const { BigNumber, constants, utils } = require('ethers');
const { ethers, upgrades } = require("hardhat");
const {expect} = require('chai');

const TransparentUpgradeableProxy = require('@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json');
const ProxyAdmin = require('@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol/ProxyAdmin.json');
const {getInitializerData} = require("@openzeppelin/hardhat-upgrades/dist/utils");

const ZERO_ADDRESS = constants.AddressZero;
let deployer, admin, organizer, user1, user2, user3, user4, user5;
let eventId;

let slotDetail_; 
const event_ = {
  organizer: ZERO_ADDRESS,
  eventName: "Test Slot", //event名称
  eventDescription: "Test Slot Description",
  eventImage: "https://example.com/slot/test_slot.png",
  mintMax: 200
};


const name = 'Network Of Attendance';
const symbol = 'NoA';
const decimals = 0;

async function fetchOrDeployAdminProxy(proxyAdminAddress) {
    const address = proxyAdminAddress ? ethers.utils.getAddressFromAccount(ethers.utils.parseAccount(proxyAdminAddress)) : null;
    
    const proxyAdminFactory = await ethers.getContractFactory(ProxyAdmin.abi, ProxyAdmin.bytecode);
    const proxyAdmin = proxyAdminAddress ? (await proxyAdminFactory.attach(address)) : (await proxyAdminFactory.deploy());
    await proxyAdmin.deployed();

    // console.log("ProxyAdmin deployed to:", proxyAdmin.address);

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

describe("NoA Main Test", () => {

  beforeEach(async function () {
    [deployer, admin, organizer, user1, user2, user3, user4] = await ethers.getSigners();
  

    // Deploy the dao metadata descriptor contract
    const MetadataDescriptor = await ethers.getContractFactory('MetadataDescriptor');
    const descriptor = await MetadataDescriptor.deploy();
    await descriptor.deployed();
    // console.log('MetadataDescriptor deployed to:', descriptor.address);
    // console.log("");

    const NoA = await ethers.getContractFactory("NoAV1");

    const proxyAdmin = await fetchOrDeployAdminProxy();
    this.token = await deployProxy(proxyAdmin, NoA, [name, symbol, decimals, descriptor.address], { initializer: 'initialize' });

    await  this.token.deployed();

    // console.log("Proxy contract deployed to:",  this.token.address);

    let tx = await this.token.connect(organizer).createEvent(event_);
    
    let receipt = await tx.wait();
    let transferEvent = receipt.events.filter(e => e.event === 'EventAdded')[0];
    eventId = transferEvent.args['eventId'];
    // console.log("eventId:", eventId.toNumber());
    // console.log("");
    // expect(eventId.toNumber()).to.be.equal(1);



  });

      it("should return correct name", async function() {
        expect(await this.token.name()).to.equal('Network Of Attendance');
        expect(await this.token.symbol()).to.equal("NoA");
      });
    
     
  
    it('mint and mintEventToManyUsers testing...', async function () {
      [deployer, admin, organizer, user1, user2, user3, user4, user5] = await ethers.getSigners();


      const [organizer_, eventName_, eventDescription_, eventImage_, mintMax_] = await this.token.getEventInfo(eventId);
      // console.log("organizer_:", organizer_);
      // console.log("eventName_:", eventName_);
      // console.log("eventDescription_:", eventDescription_);
      // console.log("eventImage_:", eventImage_);
      // console.log("mintMax_:", mintMax_.toNumber());


     slotDetail_ = {
        name: 'BigShow',
        description: 'for testing desc',
        image: '',
        eventId:  eventId,
        eventMetadataURI: "https://example.com/event/" + eventId.toString(),
      }
      let balanceOfUser1 = await this.token['balanceOf(address)'](user1.address);    
      expect(balanceOfUser1.toNumber()).to.be.equal(0);
  
      tx = await this.token.mint(
        slotDetail_,
        user1.address
      );
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'EventToken')[0];
      let tokenId = transferEvent.args['tokenId'];
      // console.log("tokenId:", tokenId.toNumber());
      // console.log("");
      balanceOfUser1 = await this.token['balanceOf(address)'](user1.address);    
      expect(balanceOfUser1.toNumber()).to.be.equal(1);
  
      expect(tokenId.toNumber()).to.be.equal(1);

      let owerOfToken = await this.token.ownerOf(tokenId.toNumber());
      // console.log("owerOfToken address:", owerOfToken);
      // console.log("");
      expect(owerOfToken).to.be.equal(user1.address);

      expect(await this.token.eventHasUser(eventId, user1.address)).to.equal(true);
      expect(await this.token.tokenEvent(await this.token.tokenOfOwnerByIndex(user1.address, 0))).to.equal(tokenId);

  
      tx =  await this.token.mintEventToManyUsers(slotDetail_, [user2.address, user3.address]);
      receipt = await tx.wait();
      
 

      let slotDetails_ = [{
        name: 'BigShow',
        description: 'for testing desc',
        image: '',
        eventId:  eventId,
        eventMetadataURI: "https://example.com/event/" + eventId.toString(),
      }];
      
      tx =  await this.token.mintUserToManyEvents(slotDetails_, user5.address);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'EventToken')[0];
      let tokenId5 = transferEvent.args['tokenId'];

      owerOfToken = await this.token.ownerOf(tokenId5);
      // console.log("owerOfToken address:", owerOfToken);
      // console.log("");
      expect(owerOfToken).to.be.equal(user5.address);

      expect(await this.token.slotCount()).to.be.equal(1); //equal events

      let count = await this.token.getNoACount(eventId);
      // console.log("getNoACount, count:", count.toNumber());
      // console.log("");
      expect(count).to.be.equal(4); //equal events


      
    });

    it("claim testing...", async function () {
   
      const root = "0x185622dc03039bc70cbb9ac9a4a086aec201f986b154ec4c55dad48c0a474e23";
      tx = await this.token.connect(organizer).setMerkleRoot(eventId, root);
      receipt = await tx.wait();

      const proof = [
        "0xe5c951f74bc89efa166514ac99d872f6b7a3c11aff63f51246c3742dfa925c9b",
        "0x0eaf89a9c884bb4179c071971269df40cd13505356686ff2db6e290749e043e5",
        "0xd4453790033a2bd762f526409b7f358023773723d9e9bc42487e4996869162b6"
       ]
      
      const slotDetail_ = {
        name: 'BigShow',
        description: 'for testing desc',
        image: '',
        eventId:  eventId,
        eventMetadataURI: "https://example.com/event/" + eventId.toString(),
      }
      expect (await this.token.connect(user2).isWhiteListed(eventId, user2.address, proof)).to.equal(true);
      tx = await this.token.connect(user2).claimNoA(slotDetail_, proof);
      receipt = await tx.wait();
      expect(await this.token.eventHasUser(eventId, user2.address)).to.equal(true);

    });
    
    it("burn testing...", async function () {
      tx = await this.token.mint(
        slotDetail_,
        user4.address
      );
      let receipt = await tx.wait();

      let transferEvent = receipt.events.filter(e => e.event === 'EventToken')[0];
      let tokenId = transferEvent.args['tokenId'];
      // console.log("tokenId:", tokenId.toNumber());
      // console.log("");

      tx = await this.token.connect(user4).burn(tokenId);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'BurnToken')[0];
      eventId_ = transferEvent.args['eventId'];
      tokenId_ = transferEvent.args['tokenId'];
      // console.log("eventId_:", eventId_.toNumber());
      // console.log("tokenId_:", tokenId_.toNumber());
      // console.log("");
      expect(eventId_).to.be.equal(eventId);
      expect(tokenId_).to.be.equal(tokenId);
  });
})