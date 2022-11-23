const { BigNumber, constants, utils } = require('ethers');
const { ethers, upgrades } = require("hardhat");
const { expect } = require('chai');

const { expectEvent } = require('./utils/expectEvent')
const { shouldSupportInterfaces } = require('./utils/SupportsInterface.behavior');

const Error = [ 'None', 'RevertWithMessage', 'RevertWithoutMessage', 'Panic' ]
  .reduce((acc, entry, idx) => Object.assign({ [entry]: idx }, acc), {});

  
const ZERO_ADDRESS = constants.AddressZero;
const MAX_UINT256 = BigNumber.from('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');



let slotDetail_; 
const firstTokenId =1;
const secondTokenId =2;
const thirdTokenId =3;
const fourthokenId =4;

const firstSlot = 1;
const secondSlot = 2;

const nonExistentSlot = 99;
const nonExistentTokenId = 9901;

const noaTokenValue = 1;


const RECEIVER_MAGIC_VALUE = '0x009ce20b';

let deployer, admin, organizer, user1, user2, user3, user4;

function shouldBehaveLikeERC3525 (errorPrefix) {
  // shouldSupportInterfaces([
  //   'ERC165',
  //   'ERC721',
  //   'ERC3525',
  // ]);


  describe("NoA Main Test", () => {

    beforeEach(async function () {
      [deployer, admin, organizer, user1, user2, user3, user4] = await ethers.getSigners();
    
  
      this.token = await deployNoA(name, symbol, decimals);
  
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
  
        let count = await this.token.getTokenAmountOfEventId(eventId);
        // console.log("getTokenAmountOfEventId, count:", count.toNumber());
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
  
        await expect(
          this.token.connect(user2).claimNoA(slotDetail_, proof)
        ).to.be.revertedWith('NoA: Token already claimed!');
  
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
  });

}

function shouldBehaveIsPoAP (errorPrefix) {
}

function shouldBehaveCanCombo (errorPrefix) {

}
/*

*/
module.exports = {
  shouldBehaveLikeERC3525,
  shouldBehaveIsPoAP,
  shouldBehaveCanCombo,
  // shouldBehaveLikeERC3525Metadata,
  // shouldBehaveLikeERC3525SlotEnumerable,
  // shouldBehaveLikeERC3525SlotApprovable
}