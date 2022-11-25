const { BigNumber, constants, utils } = require('ethers');
const { ethers, upgrades } = require("hardhat");
const { expect } = require('chai');

const { expectEvent } = require('./utils/expectEvent')
const { shouldSupportInterfaces } = require('./utils/SupportsInterface.behavior');

const Error = [ 'None', 'RevertWithMessage', 'RevertWithoutMessage', 'Panic' ]
  .reduce((acc, entry, idx) => Object.assign({ [entry]: idx }, acc), {});

  
const ZERO_ADDRESS = constants.AddressZero;
const MAX_UINT256 = BigNumber.from('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');

const event_1 = {
  organizer: ZERO_ADDRESS,
  eventName: "First Event", //event名称
  eventDescription: "Test Slot Description",
  eventImage: "https://example.com/slot/test_slot.png",
  mintMax: 200
};

const event_2 = {
  organizer: ZERO_ADDRESS,
  eventName: "Second Event", //event名称
  eventDescription: "Test Slot Description",
  eventImage: "https://example.com/slot/test_slot.png",
  mintMax: 100
};

let slotDetail_; 
const firstTokenId =1;
const secondTokenId =2;
const thirdTokenId =3;
const fourthTokenId =4;

const firstSlot = 1;
const secondSlot = 2;

const nonExistentSlot = 99;
const nonExistentTokenId = 9901;

const noaTokenValue = 1;


const RECEIVER_MAGIC_VALUE = '0x009ce20b';

let  firstOwner, secondOwner, newOwner, approved, valueApproved, anotherApproved, operator, slotOperator, other, organizer, user1,user2,user3,user4,user5;

function shouldBehaveLikeERC3525 (errorPrefix) {
  shouldSupportInterfaces([
    'ERC165',
    'ERC721',
    'ERC3525',
  ]);

  context('with minted tokens', function () {
    beforeEach(async function () {
      [firstOwner, secondOwner, approved, valueApproved, anotherApproved, operator, slotOperator, other, organizer, user1,user2,user3,user4,user5] = await ethers.getSigners();

      let tx = await this.token.connect(organizer).createEvent(event_1);
      let receipt = await tx.wait();
      let transferEvent = receipt.events.filter(e => e.event === 'EventAdded')[0];
      let eventId_1 = transferEvent.args['eventId'];
     // console.log("eventId_1:", eventId_1.toNumber());
      // console.log("");

      let slotDetail_1 = {
        name: 'BigShow#1',
        description: 'for testing desc',
        image: 'https://example.com/img/1.jpg',
        eventId:  eventId_1,
        eventMetadataURI: "https://example.com/event/" + eventId_1.toString(),
      };
      
      tx = await this.token.connect(organizer).createEvent(event_2);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'EventAdded')[0];
      let  eventId_2 = transferEvent.args['eventId'];
      //console.log("eventId_2:", eventId_2.toNumber());
      // console.log("");
      
      let slotDetail_2 = {
        name: 'BigShow#2',
        description: 'for testing desc',
        image: 'https://example.com/img/1.jpg',
        eventId:  eventId_2,
        eventMetadataURI: "https://example.com/event/" + eventId_2.toString(),
      };
      

      //铸造出4枚token, value分别是1
      tx = await this.token.mint(slotDetail_1, firstOwner.address, []);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'EventToken')[0];
      let tokenId = transferEvent.args['tokenId'];
      //console.log("first tokenId:", tokenId.toNumber());
      // console.log("");

      tx = await this.token.mint(slotDetail_1, secondOwner.address, []);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'EventToken')[0];
      tokenId = transferEvent.args['tokenId'];
      //console.log("second tokenId:", tokenId.toNumber());

      tx = await this.token.mint(slotDetail_2, firstOwner.address, []);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'EventToken')[0];
      tokenId = transferEvent.args['tokenId'];
     // console.log("third tokenId:", tokenId.toNumber());
      
      tx = await this.token.mint(slotDetail_2, secondOwner.address, []);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'EventToken')[0];
      tokenId = transferEvent.args['tokenId'];
      //console.log("four tokenId:", tokenId.toNumber());

      this.toWhom = other;
      //接收者
      this.ERC3525ReceiverMockFactory = await ethers.getContractFactory('ERC3525ReceiverMock');
    });

    describe("balanceOf(uint256)", () => {
      
      context('when the given token is valid', function () {
        it('returns the value held by the token', async function () {
          expect(await this.token['balanceOf(uint256)'](firstTokenId)).to.be.equal(noaTokenValue);
          expect(await this.token['balanceOf(uint256)'](secondTokenId)).to.be.equal(noaTokenValue);
          expect(await this.token['balanceOf(uint256)'](thirdTokenId)).to.be.equal(noaTokenValue);
          expect(await this.token['balanceOf(uint256)'](fourthTokenId)).to.be.equal(noaTokenValue);
        });
      });

      context('when the given token does not exist', function () {
        it('reverts', async function () {
          await expect(this.token['balanceOf(uint256)'](0)).to.be.revertedWith('ERC3525: invalid token ID');
          await expect(this.token['balanceOf(uint256)'](nonExistentTokenId)).to.be.revertedWith('ERC3525: invalid token ID');
        });
      });
    });

    describe('slotOf', function () {
      context('when the given token is valid', function () {
        it('returns the slot of the token', async function () {
          expect(await this.token.slotOf(firstTokenId)).to.be.equal(firstSlot);
          expect(await this.token.slotOf(secondTokenId)).to.be.equal(firstSlot);
          expect(await this.token.slotOf(thirdTokenId)).to.be.equal(secondSlot);
          expect(await this.token.slotOf(fourthTokenId)).to.be.equal(secondSlot);
        });
      });

      context('when the given token does not exist', function () {
        it('reverts', async function () {
          await expect(this.token.slotOf(0)).to.be.revertedWith('ERC3525: invalid token ID');
          await expect(this.token.slotOf(nonExistentTokenId)).to.be.revertedWith('ERC3525: invalid token ID');
        });
      });
    });

/*
    //同一地址的token之间转移value
    describe('transfer value from token to token', function () {
      const transferValue = 1;

      let tx = null;
      let receipt = null;

      beforeEach(async function() {
        await this.token.connect(firstOwner)['approve(address,uint256)'](approved.address, firstTokenId);
        await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, noaTokenValue);
        await this.token.connect(firstOwner).setApprovalForAll(operator.address, true);

        this.fromOwner = firstOwner;
        this.fromTokenId = firstTokenId;
        this.fromTokenValue = noaTokenValue;
        this.fromOwnerBalance = await this.token['balanceOf(address)'](this.fromOwner.address);

        this.toOwner = secondOwner;
        this.toTokenId = secondTokenId;
        this.toTokenValue = noaTokenValue;
        this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);
      });

      const transferValueFromTokenToTokenWasSuccessful = function () {
        it('transfers value of one token ID to another token ID', async function() {
          expect(await this.token['balanceOf(uint256)'](this.fromTokenId)).to.be.equal(this.fromTokenValue - transferValue);
          expect(await this.token['balanceOf(uint256)'](this.toTokenId)).to.be.equal(this.toTokenValue + transferValue);
        });

        it('emits a TransferValue event', async function() {
          expectEvent(receipt, 'TransferValue', { _fromTokenId: this.fromTokenId, _toTokenId: this.toTokenId, _value: transferValue});
        });

        it('do not adjust owners balances', async function() {
          expect(await this.token['balanceOf(address)'](this.fromOwner.address)).to.be.equal(this.fromOwnerBalance);
          expect(await this.token['balanceOf(address)'](this.toOwner.address)).to.be.equal(this.toOwnerBalance);
        });

        it('do not adjust token owners', async function() {
          expect(await this.token.ownerOf(this.fromTokenId)).to.be.equal(this.fromOwner.address);
          expect(await this.token.ownerOf(this.toTokenId)).to.be.equal(this.toOwner.address);
        });

        it('do not adjust tokens slots', async function() {
          expect(await this.token.slotOf(this.fromTokenId)).to.be.equal(firstSlot);
          expect(await this.token.slotOf(this.toTokenId)).to.be.equal(firstSlot);
        });
      };



      const shouldTransferValueFromTokenToTokenByUsers = function () {
        //以owner身份call
        context('when called by the owner', function () {
          this.beforeEach(async function () {
            tx = await this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue);
            receipt = await tx.wait();
          })
          transferValueFromTokenToTokenWasSuccessful();
        });

        //以approved的身份call
        context('when called by the token approved individual', function () {
          beforeEach(async function () {
            tx = await this.token.connect(approved)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToTokenWasSuccessful();
        });
        
        context('when called by the value approved individual', function () {
          beforeEach(async function () {
            this.allowanceBefore = await this.token.allowance(this.fromTokenId, valueApproved.address);
            tx = await this.token.connect(valueApproved)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToTokenWasSuccessful();

          it('adjust allowance', async function() {
            this.allowanceAfter = await this.token.allowance(this.fromTokenId, valueApproved.address);
            expect(this.allowanceAfter).to.be.equal(this.allowanceBefore - transferValue);
          });
        });
        
        context('when called by the unlimited value approved individual', function () {
          beforeEach(async function () {
            await this.token.connect(this.fromOwner)['approve(uint256,address,uint256)'](this.fromTokenId, valueApproved.address, MAX_UINT256);
            expect(await this.token.allowance(this.fromTokenId, valueApproved.address)).to.be.equal(MAX_UINT256);
            tx = await this.token.connect(valueApproved)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToTokenWasSuccessful();

          it('adjust allowance', async function() {
            expect(await this.token.allowance(this.fromTokenId, valueApproved.address)).to.be.equal(MAX_UINT256);
          });
        });
        
        //以operator身份call
        context('when called by the operator', function () {
          beforeEach(async function () {
            tx = await this.token.connect(operator)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToTokenWasSuccessful();
        });

        //TODO，这里从ERC-3525复制的测试代码有问题，改动之后才通过 
        context('when called by the operator without an approved user', function () {
          beforeEach(async function () {
            await this.token.connect(this.fromOwner)['approve(address,uint256)'](ZERO_ADDRESS, this.fromTokenId);
            tx = await this.token.connect(operator)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToTokenWasSuccessful();
        });
        

        context('when sent to the from token itself', function () {
          beforeEach(async function () {
            tx = await this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.fromTokenId, transferValue);
            receipt = await tx.wait();
          });

          it('keeps the ownership of the token', async function () {
            expect(await this.token.ownerOf(this.fromTokenId)).to.be.equal(this.fromOwner.address);
          });

          it('keeps the balance of the token', async function () {
            expect(await this.token['balanceOf(uint256)'](this.fromTokenId)).to.be.equal(this.fromTokenValue);
          });

          it('keeps the owner balance', async function () {
            expect(await this.token['balanceOf(address)'](this.fromOwner.address)).to.be.equal(this.fromOwnerBalance);
          });

          it('emits a TransferValue event', async function() {
            expectEvent(receipt, 'TransferValue', { _fromTokenId: this.fromTokenId, _toTokenId: this.fromTokenId, _value: transferValue});
          });
        });

        context('when transfer value exceeds balance of token', function () {
          it('reverts', async function () {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, this.fromTokenValue + 1)
            ).to.be.revertedWith('ERC3525: insufficient balance for transfer');
          });
        });

        context('when transfer to a token with different slot', function () {
          it('reverts', async function () {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, thirdTokenId, transferValue)
            ).to.be.revertedWith('ERC3525: transfer to token with different slot');
          });
        });

        context('with invalid token ID', function() {
          it('reverts when from token ID is invalid', async function() {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](nonExistentTokenId, this.toTokenId, transferValue)
            ).to.be.revertedWith('ERC3525: invalid token ID');
          });

          it('reverts when to token ID is invalid', async function() {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, nonExistentTokenId, transferValue)
            ).to.be.revertedWith('ERC3525: transfer to invalid token ID');
          });
        });

        context('when the sender is not authorized for the token id', function () {
          it('reverts', async function () {
            await expect(
              this.token.connect(other)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue)
            ).to.revertedWith('ERC3525: insufficient allowance');
          });
        });

        context('when transfer value exceeds allowance', function () {
          it('reverts', async function () {
            await this.token.connect(this.fromOwner)['approve(uint256,address,uint256)'](this.fromTokenId, valueApproved.address, transferValue - 1);
            await expect(
              this.token.connect(valueApproved)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue)
            ).to.be.revertedWith('ERC3525: insufficient allowance');
          });
        });
      };

      describe('to a token held by a user account', function () {
        shouldTransferValueFromTokenToTokenByUsers();
      });

      const deployReceiverAndMint = async function (magicValue, errorType) {
        //接收者是合约
        this.toOwner = await this.ERC3525ReceiverMockFactory.deploy(magicValue, errorType);
        // this.toTokenId = 1003;
        // this.toTokenValue = 100000;
        this.toTokenValue = 1;
        let slotDetail_1 = {
          name: 'BigShow#1',
          description: 'for testing desc',
          image: 'https://example.com/img/1.jpg',
          eventId:  1,
          eventMetadataURI: "https://example.com/event/1",
        };
        let tx = await this.token.mint(slotDetail_1, this.toOwner.address, []);
        let receipt = await tx.wait();
        let transferEvent = receipt.events.filter(e => e.event === 'EventToken')[0];
        this.toTokenId = transferEvent.args['tokenId'];

        this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);      
      }

      describe('to a non-receiver contract', function () {
        beforeEach(async function () {
          this.toOwner = this.token;
          // this.toTokenId = 1003;
          // this.toTokenValue = 100000;
          this.toTokenValue =1;
          let slotDetail_1 = {
            name: 'BigShow#1',
            description: 'for testing desc',
            image: 'https://example.com/img/1.jpg',
            eventId:  1,
            eventMetadataURI: "https://example.com/event/1",
          };
          let tx = await this.token.mint(slotDetail_1, this.toOwner.address, []);
          let receipt = await tx.wait();
          let transferEvent = receipt.events.filter(e => e.event === 'EventToken')[0];
          this.toTokenId = transferEvent.args['tokenId'];
 
          this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);   
        });
        shouldTransferValueFromTokenToTokenByUsers();
      });

      describe('to a valid receiver contract', function () {
        beforeEach(async function () {
          await deployReceiverAndMint.call(this, RECEIVER_MAGIC_VALUE, Error.None);
        });
        shouldTransferValueFromTokenToTokenByUsers();
      });

      describe('to a receiver contract returning unexpected value', function () {
        it('reverts', async function () {
          await deployReceiverAndMint.call(this, '0x12345678', Error.None);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue)
          ).to.revertedWith('ERC3525: transfer to non ERC3525Receiver');
        });
      });

      describe('to a receiver contract that reverts with message', function () {
        it('reverts', async function () {
          await deployReceiverAndMint.call(this, RECEIVER_MAGIC_VALUE, Error.RevertWithMessage);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue)
          ).to.revertedWith('ERC3525ReceiverMock: reverting');
        });
      });

      describe('to a receiver contract that reverts without message', function () {
        it('reverts', async function () {
          await deployReceiverAndMint.call(this, RECEIVER_MAGIC_VALUE, Error.RevertWithoutMessage);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue)
          ).to.revertedWith('ERC3525: transfer to non ERC3525Receiver');
        });
      });

      describe('to a receiver contract that panics', function () {
        it('reverts', async function () {
          await deployReceiverAndMint.call(this, RECEIVER_MAGIC_VALUE, Error.Panic);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue)
          ).to.revertedWithPanic;
        });
      });
      
    });

    //将value数量从token转移到另外一个新的地址
    describe('transfer value from token to address', function () {
      const transferValue = 1;

      let tx = null;
      let receipt = null;

      beforeEach(async function () {
        await this.token.connect(firstOwner)['approve(address,uint256)'](approved.address, firstTokenId);
        await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, noaTokenValue);
        await this.token.connect(firstOwner).setApprovalForAll(operator.address, true);

        this.fromOwner = firstOwner;
        this.fromTokenId = firstTokenId;
        this.fromTokenValue = noaTokenValue;
        this.fromOwnerBalance = await this.token['balanceOf(address)'](this.fromOwner.address);

        this.toOwner = secondOwner;
        this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);
      });

      const transferValueFromTokenToAddressWasSuccessful = function () {
        it('adjustments on owners balances', async function() {
          if (this.fromOwner != this.toOwner) {
            expect(await this.token['balanceOf(address)'](this.fromOwner.address)).to.be.equal(this.fromOwnerBalance);
          }
          expect(await this.token['balanceOf(address)'](this.toOwner.address)).to.be.equal(this.toOwnerBalance.add(1));
        })

        it('transfers value of one token ID to an address', async function() {
          expect(await this.token['balanceOf(uint256)'](this.fromTokenId)).to.be.equal(this.fromTokenValue - transferValue);
          const toTokenId = await this.token['tokenOfOwnerByIndex(address,uint256)'](this.toOwner.address, this.toOwnerBalance);
          expect(await this.token['balanceOf(uint256)'](toTokenId)).to.be.equal(transferValue);
        });

        it('emits Transfer/SlotChanged/TransferValue event', async function() {
          const toTokenId = await this.token['tokenOfOwnerByIndex(address,uint256)'](this.toOwner.address, this.toOwnerBalance);
          expectEvent(receipt, 'Transfer', { _from: ZERO_ADDRESS, _to: this.toOwner.address, _tokenId: toTokenId });
          expectEvent(receipt, 'SlotChanged', { _tokenId: toTokenId, _oldSlot: 0, _newSlot: firstSlot });
          expectEvent(receipt, 'TransferValue', { _fromTokenId: this.fromTokenId, _toTokenId: toTokenId, _value: transferValue});
        });

        it('do not adjust owner of from token ID', async function() {
          expect(await this.token['ownerOf(uint256)'](this.fromTokenId)).to.be.equal(this.fromOwner.address);
        });

        it('do not adjust tokens slots', async function() {
          expect(await this.token['slotOf(uint256)'](this.fromTokenId)).to.be.equal(firstSlot);
          const toTokenId = await this.token['tokenOfOwnerByIndex(address,uint256)'](this.toOwner.address, this.toOwnerBalance);
          expect(await this.token['slotOf(uint256)'](toTokenId)).to.be.equal(firstSlot);
        });
      };

      const shouldTransferValueFromTokenToAddressByUsers = function () {
        context('when called by the owner', function () {
          this.beforeEach(async function () {
            tx = await this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          })
          transferValueFromTokenToAddressWasSuccessful();
        });

        context('when called by the token approved individual', function () {
          beforeEach(async function () {
            tx = await this.token.connect(approved)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToAddressWasSuccessful();
        });

        context('when called by the value approved individual', function () {
          beforeEach(async function () {
            this.allowanceBefore = await this.token.allowance(this.fromTokenId, valueApproved.address);
            tx = await this.token.connect(valueApproved)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToAddressWasSuccessful();

          it('adjust allowance', async function() {
            this.allowanceAfter = await this.token.allowance(this.fromTokenId, valueApproved.address);
            expect(this.allowanceAfter).to.be.equal(this.allowanceBefore - transferValue);
          });
        });

        context('when called by the unlimited value approved individual', function () {
          beforeEach(async function () {
            await this.token.connect(this.fromOwner)['approve(uint256,address,uint256)'](this.fromTokenId, valueApproved.address, MAX_UINT256);
            expect(await this.token.allowance(this.fromTokenId, valueApproved.address)).to.be.equal(MAX_UINT256);
            tx = await this.token.connect(valueApproved)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToAddressWasSuccessful();

          it('adjust allowance', async function() {
            expect(await this.token.allowance(this.fromTokenId, valueApproved.address)).to.be.equal(MAX_UINT256);
          });
        });
        
        context('when called by the operator', function () {
          beforeEach(async function () {
            tx = await this.token.connect(operator)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToAddressWasSuccessful();
        });

        context('when called by the operator without an approved user', function () {
          beforeEach(async function () {
            await this.token.connect(this.fromOwner)['approve(address,uint256)'](ZERO_ADDRESS, this.fromTokenId);
            tx = await this.token.connect(operator)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToAddressWasSuccessful();
        });

        context('when sent to the owner', function () {
          beforeEach(async function () {
            this.toOwner = this.fromOwner;
            this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);
            tx = await this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToAddressWasSuccessful();
        });

        context('when transfer value exceeds balance of token', function () {
          it('reverts', async function () {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, this.fromTokenValue + 1)
            ).to.be.revertedWith('ERC3525: insufficient balance for transfer');
          });
        });

        context('transfer from invalid token ID', function() {
          it('reverts', async function() {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](nonExistentTokenId, this.toOwner.address, transferValue)
            ).to.be.revertedWith('ERC3525: invalid token ID');
          });
        });

        context('transfer to the zero address', function() {
          it('reverts', async function() {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, ZERO_ADDRESS, transferValue)
            ).to.be.revertedWith('ERC3525: mint to the zero address');
          });
        });

        context('when the sender is not authorized for the token id', function () {
          it('reverts', async function () {
            await expect(
              this.token.connect(other)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)
            ).to.revertedWith('ERC3525: insufficient allowance');
          });
        });

        context('when transfer value exceeds allowance', function () {
          it('reverts', async function () {
            await this.token.connect(this.fromOwner)['approve(uint256,address,uint256)'](this.fromTokenId, valueApproved.address, transferValue - 1);
            await expect(
              this.token.connect(valueApproved)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)
            ).to.be.revertedWith('ERC3525: insufficient allowance');
          });
        });
      };

      describe('to a user account', function () {
        shouldTransferValueFromTokenToAddressByUsers();
      });

      describe('to a non-receiver contract', function () {
        beforeEach(async function () {
          this.toOwner = this.token;
          this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);
        });
        shouldTransferValueFromTokenToAddressByUsers();
      });

      describe('to a valid receiver contract', function () {
        beforeEach(async function () {
          this.toOwner = await this.ERC3525ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.None);
          this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);
        });
        shouldTransferValueFromTokenToAddressByUsers();
      });

      describe('to a receiver contract returning unexpected value', function () {
        it('reverts', async function () {
          this.toOwner = await this.ERC3525ReceiverMockFactory.deploy('0x12345678', Error.None);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)
          ).to.revertedWith('ERC3525: transfer to non ERC3525Receiver');
        });
      });

      describe('to a receiver contract that reverts with message', function () {
        it('reverts', async function () {
          this.toOwner = await this.ERC3525ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.RevertWithMessage);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)
          ).to.revertedWith('ERC3525ReceiverMock: reverting');
        });
      });

      describe('to a receiver contract that reverts without message', function () {
        it('reverts', async function () {
          this.toOwner = await this.ERC3525ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.RevertWithoutMessage);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)
          ).to.revertedWith('ERC3525: transfer to non ERC3525Receiver');
        });
      });

      describe('to a receiver contract that panics', function () {
        it('reverts', async function () {
          this.toOwner = await this.ERC3525ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.Panic);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)
          ).to.revertedWithPanic;
        });
      });
    });
 
*/
    //token to address
    describe('token to address', function () {

      const shouldBurnTokenByUsers = function () {
        //以owner身份call
        context('when called by the owner', function () {
          this.beforeEach(async function () {
            const transferValue = 1;
            this.fromOwner = firstOwner;
            this.toOwner = secondOwner;
            this.fromTokenId = firstTokenId;
            let tx = await this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)

            await tx.wait();


          })
          
          it('keep the ownership of the token', async function () {
            expect(await this.token.ownerOf(this.fromTokenId)).to.be.equal(this.fromOwner.address);
          });

          it('the balance of the from token', async function () {

            expect(await this.token['balanceOf(uint256)'](this.fromTokenId)).to.be.equal(0);

          });

          it('keeps the owner balance', async function () {
            //保持owner的token层的数量不变，但是fromTokenId的对应的value已经为0
           expect(await this.token.connect(this.fromOwner)['balanceOf(address)'](this.fromOwner.address)).to.be.equal(2);
          });

          it('keep the slot Of the token', async function () {
            expect(await this.token.slotOf(this.fromTokenId)).to.be.equal(firstSlot);

          });
        });

      };

      describe('burn...', function () {
        shouldBurnTokenByUsers();
      });
    });


  });

}

function shouldBehaveLikeERC3525Metadata (errorPrefix) {
  shouldSupportInterfaces([
    'ERC721Metadata',
    'ERC3525Metadata'
  ]);

}

function shouldBehaveLikeERC3525SlotEnumerable (errorPrefix) {
  shouldSupportInterfaces([
    'ERC3525SlotEnumerable'
  ]);
}

function shouldBehaveCanCombo (errorPrefix) {

}

/*

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
})
*/
module.exports = {
  shouldBehaveLikeERC3525,
  shouldBehaveCanCombo,
  shouldBehaveLikeERC3525Metadata,
  shouldBehaveLikeERC3525SlotEnumerable,
  // shouldBehaveLikeERC3525SlotApprovable
}