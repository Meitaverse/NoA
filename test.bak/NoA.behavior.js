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
  name: "First Event", //event名称
  description: "Test Slot Description",
  image: "https://example.com/slot/test_slot.png",
  metadataURI: "",
  mintMax: 200
};

const event_2 = {
  organizer: ZERO_ADDRESS,
  name: "Second Event", //event名称
  description: "Test Slot Description",
  image: "https://example.com/slot/test_slot.png",
  metadataURI: "",
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

      let tx = await this.token.connect(organizer).createProject(event_1);
      let receipt = await tx.wait();
      let transferEvent = receipt.events.filter(e => e.event === 'ProjectAdded')[0];
      console.log("transferEvent:", transferEvent);

      let eventId_1 = transferEvent.args['projectId'];
     console.log("eventId_1:", eventId_1.toNumber());
      console.log("");

      let slotDetail_1 = {
        name: 'BigShow#1',
        description: 'for testing desc',
        image: 'https://example.com/img/1.jpg',
        projectId:  eventId_1,
        metadataURI: "https://example.com/event/" + eventId_1.toString(),
      };
      
      tx = await this.token.connect(organizer).createProject(event_2);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'ProjectAdded')[0];
      let  eventId_2 = transferEvent.args['projectId'];
      //console.log("eventId_2:", eventId_2.toNumber());
      // console.log("");
      
      let slotDetail_2 = {
        name: 'BigShow#2',
        description: 'for testing desc',
        image: 'https://example.com/img/1.jpg',
        projectId:  eventId_2,
        metadataURI: "https://example.com/event/" + eventId_2.toString(),
      };
      
      //铸造出4枚token, value分别是1
      tx = await this.token.mint(slotDetail_1, firstOwner.address, []);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
      let tokenId = transferEvent.args['tokenId'];
      //console.log("first tokenId:", tokenId.toNumber());
      // console.log("");

      tx = await this.token.mint(slotDetail_1, secondOwner.address, []);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
      tokenId = transferEvent.args['tokenId'];
      //console.log("second tokenId:", tokenId.toNumber());

      tx = await this.token.mint(slotDetail_2, firstOwner.address, []);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
      tokenId = transferEvent.args['tokenId'];
     // console.log("third tokenId:", tokenId.toNumber());
      
      tx = await this.token.mint(slotDetail_2, secondOwner.address, []);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
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
          projectId:  1,
          metadataURI: "https://example.com/event/1",
        };
        let tx = await this.token.mint(slotDetail_1, this.toOwner.address, []);
        let receipt = await tx.wait();
        let transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
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
            projectId:  1,
            metadataURI: "https://example.com/event/1",
          };
          let tx = await this.token.mint(slotDetail_1, this.toOwner.address, []);
          let receipt = await tx.wait();
          let transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
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
            let receipt = await tx.wait();

            let transferEvent = receipt.events.filter(e => e.event === 'TransferValue')[1];
            //铸造一个新的tokenId=5来接收value
            this.toTokenId = transferEvent.args['_toTokenId'];
            // console.log('this.toTokenId:',  this.toTokenId);

          })
          
          it('keep the ownership of the token', async function () {
            expect(await this.token.ownerOf(this.fromTokenId)).to.be.equal(this.fromOwner.address);
          });

          //交易成功之后，token内的余额为0，也就是slot的value为0
          it('the balance of the from token', async function () {
            expect(await this.token.connect(this.fromOwner)['balanceOf(uint256)'](this.fromTokenId)).to.be.equal(0);
            //接收者的新的tokenId里的balanceOf=1
            expect(await this.token.connect(this.toOwner)['balanceOf(uint256)'](this.toTokenId)).to.be.equal(1);
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

  describe('metadata', function () {
    context('contract URI', function () {
      it('return empty string by default', async function () {
       // expect(await this.token.contractURI()).to.be.equal('');
       const contractURI = await this.token.contractURI();
      //  console.log("contractURI: ", contractURI);
      });
    });

    context('slot URI', function () {
      it('return empty string by default', async function () {
        // expect(await this.token.slotURI(firstSlot)).to.be.equal('');
        const slotURI = await this.token.slotURI(firstSlot);
        // console.log("slotURI: ", slotURI);
      });
    });
  });

}

function shouldBehaveLikeERC3525SlotEnumerable (errorPrefix) {
  shouldSupportInterfaces([
    'ERC3525SlotEnumerable'
  ]);

  // context('with minted tokens', function () {
  //   beforeEach(async function () {
  //     [firstOwner, secondOwner, approved, valueApproved, anotherApproved, operator, slotOperator, other, organizer, user1,user2,user3,user4,user5] = await ethers.getSigners();

  //     let tx = await this.token.connect(organizer).createProject(event_1);
  //     let receipt = await tx.wait();
  //     let transferEvent = receipt.events.filter(e => e.event === 'ProjectAdded')[0];
  //     let eventId_1 = transferEvent.args['projectId'];
  //     this.projectId = eventId_1;
  //     // console.log("eventId_1:", eventId_1.toNumber());
  //     // console.log("");

  //     let slotDetail_1 = {
  //       name: 'BigShow#1',
  //       description: 'for testing desc',
  //       image: 'https://example.com/img/1.jpg',
  //       projectId:  eventId_1,
  //       metadataURI: "https://example.com/event/" + eventId_1.toString(),
  //     };
      
  //     tx = await this.token.connect(organizer).createProject(event_2);
  //     receipt = await tx.wait();
  //     transferEvent = receipt.events.filter(e => e.event === 'ProjectAdded')[0];
  //     let  eventId_2 = transferEvent.args['projectId'];
  //     //console.log("eventId_2:", eventId_2.toNumber());
  //     // console.log("");

      
  //     let slotDetail_2 = {
  //       name: 'BigShow#2',
  //       description: 'for testing desc',
  //       image: 'https://example.com/img/1.jpg',
  //       projectId:  eventId_2,
  //       metadataURI: "https://example.com/event/" + eventId_2.toString(),
  //     };
      
  //     //铸造出4枚token, value分别是1
  //     tx = await this.token.mint(slotDetail_1, firstOwner.address, []);
  //     receipt = await tx.wait();
  //     transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
  //     let tokenId = transferEvent.args['tokenId'];
  //     //console.log("first tokenId:", tokenId.toNumber());
  //     // console.log("");

  //     tx = await this.token.mint(slotDetail_1, secondOwner.address, []);
  //     receipt = await tx.wait();
  //     transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
  //     tokenId = transferEvent.args['tokenId'];
  //     //console.log("second tokenId:", tokenId.toNumber());

  //     tx = await this.token.mint(slotDetail_2, firstOwner.address, []);
  //     receipt = await tx.wait();
  //     transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
  //     tokenId = transferEvent.args['tokenId'];
  //    // console.log("third tokenId:", tokenId.toNumber());
      
  //     tx = await this.token.mint(slotDetail_2, secondOwner.address, []);
  //     receipt = await tx.wait();
  //     transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
  //     tokenId = transferEvent.args['tokenId'];
  //     //console.log("four tokenId:", tokenId.toNumber());
  //   });

  //   const afterTransferFromAddressToAddress = function (validateFunc) {
  //     context('after transferring a token from address to address', function () {
  //       beforeEach(async function () {
  //         await this.token.connect(firstOwner)['transferFrom(address,address,uint256)'](firstOwner.address, secondOwner.address, firstTokenId);
  //       });
  //       validateFunc();
  //     });
  //   }

  //   const afterTransferFromTokenToToken = function (validateFunc) {
  //     context('after transferring value from token to token', function () {
  //       beforeEach(async function () {
  //         await this.token.connect(firstOwner)['transferFrom(uint256,uint256,uint256)'](firstTokenId, secondTokenId, 1);
  //       });
  //       validateFunc();
  //     });
  //   }

  //   const afterTransferFromTokenToAddress = function (validateFunc) {
  //     context('after transferring value from token to address', function () {
  //       beforeEach(async function () {
  //         const tx = await this.token.connect(firstOwner)['transferFrom(uint256,address,uint256)'](firstTokenId, secondOwner.address, 1);
  //         const receipt = await tx.wait();
  //         const transferEvent = receipt.events.filter(e => e.event === 'Transfer')[0];
  //         this.newTokenId = transferEvent.args['_tokenId'];
  //       });
  //       validateFunc();
  //     });
  //   }

  //   const afterBurningToken = function (validateFunc) {
  //     context('after burning token', function () {
  //       beforeEach(async function () {
  //         await this.token.burn(firstTokenId);
  //       });
  //       validateFunc();
  //     });
  //   }

  //   describe('slot count', function () {
  //     it('returns total slot count', async function () {
  //       expect(await this.token.slotCount()).to.be.equal(2);
  //     });
  //   });

    
  //   describe('slot by index', function () {
  //     it('returns all slots', async function () {
  //       const slotsListed = await Promise.all(
  //         [0, 1].map(i => this.token.slotByIndex(i)),
  //       );
  //       expect(slotsListed.map(s => s.toNumber())).to.have.members([firstSlot, secondSlot]);
  //     });

  //     it('reverts if index is greater than slot count', async function () {
  //       await expect(
  //         this.token.slotByIndex(2)
  //       ).to.revertedWith('ERC3525SlotEnumerable: slot index out of bounds')
  //     });
  //   });

  //   describe('tokenSupplyInSlot', function () {
  //     context('when there are tokens in the given slot', function () {
  //       it('returns the number of tokens in the given slot', async function () {
  //         expect(await this.token.tokenSupplyInSlot(firstSlot)).to.be.equal(2);
  //         expect(await this.token.tokenSupplyInSlot(secondSlot)).to.be.equal(2);
  //       });
  //     });
  //   });

  //   context('when there are no tokens in the given slot', function () {
  //     it('returns 0', async function () {
  //       expect(await this.token.tokenSupplyInSlot(nonExistentSlot)).to.be.equal(0);
  //     });
  //   });

  //   afterTransferFromAddressToAddress(function () {
  //     it('tokenSupplyInSlot should remain the same', async function () {
  //       expect(await this.token.tokenSupplyInSlot(firstSlot)).to.be.equal(2);
  //     });
  //   });

  //   afterTransferFromTokenToToken(function () {
  //     it('tokenSupplyInSlot should remain the same', async function () {
  //       expect(await this.token.tokenSupplyInSlot(firstSlot)).to.be.equal(2);
  //       expect(await this.token.tokenSupplyInSlot(secondSlot)).to.be.equal(2);
  //     });
  //   });

    
  //   afterTransferFromTokenToAddress(function () {
  //     it('adjusts tokenSupplyInSlot', async function () {
  //       expect(await this.token.tokenSupplyInSlot(firstSlot)).to.be.equal(3);
  //     });
  //   });

  //   afterBurningToken(function () {
  //     it('adjusts tokenSupplyInSlot', async function () {
  //       expect(await this.token.tokenSupplyInSlot(firstSlot)).to.be.equal(1);
  //     });
  //   });

  //   describe('setApprovalForSlot', function () {
  //     context('when slot operator is not the owner', function () {
  //       context('after being set as slot operator', function () {
  //         let tx = null;
  //         let receipt = null;

  //         beforeEach(async function () {
  //           tx = await this.token.connect(firstOwner).setApprovalForSlot(firstOwner.address, firstSlot, slotOperator.address, true);
  //           receipt = await tx.wait();
  //         });

  //         it('approves the slot operator', async function () {
  //           expect(await this.token.isApprovedForSlot(firstOwner.address, firstSlot, slotOperator.address)).to.be.equal(true);
  //         });

  //       });
  //     });
  //   });

  //   describe('combo', function () {
  //     context('with user', function () {
  //       let tx = null;
  //       let receipt = null;
  //       let transferEvent =  null;

  //       it('User Mint a Derivative NoA', async function () {
  //         tx = await this.token.connect(secondOwner)['transferFrom(uint256,address,uint256)'](
  //           secondTokenId, 
  //           firstOwner.address, 
  //           1
  //         );
  //         receipt = await tx.wait();
  //         transferEvent = receipt.events.filter(e => e.event === 'Transfer')[0];
  //         let newTokenId = transferEvent.args['_tokenId'];
  //         // console.log("newTokenId:", newTokenId.toNumber());

  //         tx = await this.token.connect(firstOwner).combo(
  //           this.projectId, 
  //           [firstTokenId, newTokenId], 
  //           "image", 
  //           "metadataURI", 
  //           firstOwner.address, 
  //           10
  //         );

  //         receipt = await tx.wait();
  //         transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
  //         let derivative_tokenId = transferEvent.args['tokenId'];
  //         // console.log("derivative_tokenId:", derivative_tokenId.toNumber());

  //        // expect(await this.token.isApprovedForSlot(firstOwner.address, firstSlot, slotOperator.address)).to.be.equal(true);
  //       });

  //     });
  //     context('with organizer', function () {
  //       let tx = null;
  //       let receipt = null;
  //       let transferEvent =  null;
  //       const valueAfterCombo = 1000;

  //       it('Organizer Mint many Derivative NoA', async function () {
  //         tx = await this.token.connect(firstOwner)['transferFrom(uint256,address,uint256)'](
  //           firstTokenId, 
  //           organizer.address, 
  //           1
  //         );
  //         receipt = await tx.wait();
  //         transferEvent = receipt.events.filter(e => e.event === 'Transfer')[0];
  //         newTokenId_organizer1 = transferEvent.args['_tokenId'];
  //         // console.log("newTokenId_organizer1:", newTokenId_organizer1.toNumber());

  //         tx = await this.token.connect(secondOwner)['transferFrom(uint256,address,uint256)'](
  //           secondTokenId, 
  //           organizer.address, 
  //           1
  //         );
  //         receipt = await tx.wait();
  //         transferEvent = receipt.events.filter(e => e.event === 'Transfer')[0];
  //         newTokenId_organizer2 = transferEvent.args['_tokenId'];
  //         // console.log("newTokenId_organizer2:", newTokenId_organizer2.toNumber());

  //         tx = await this.token.connect(organizer).combo(
  //           this.projectId, 
  //           [newTokenId_organizer1, newTokenId_organizer2], 
  //           "image", 
  //           "metadataURI", 
  //           organizer.address, 
  //           valueAfterCombo
  //         );

  //         receipt = await tx.wait();
  //         transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
  //         let derivative_tokenId = transferEvent.args['tokenId'];
  //         // console.log("derivative_tokenId:", derivative_tokenId.toNumber());
          
  //         expect(await this.token['balanceOf(uint256)'](derivative_tokenId)).to.be.equal(valueAfterCombo);
  //       });

  //     });
  //   });

  // });

  context('batch minted many tokens', function () {
    beforeEach(async function () {
      [firstOwner, secondOwner, approved, valueApproved, anotherApproved, operator, slotOperator, other, organizer, user1,user2,user3,user4,user5] = await ethers.getSigners();

      let tx = await this.token.connect(organizer).createProject(event_1);
      let receipt = await tx.wait(1);
      let transferEvent = receipt.events.filter(e => e.event === 'ProjectAdded')[0];
      let eventId_1 = transferEvent.args['projectId'];
      this.projectId = eventId_1;
      console.log("eventId_1:", eventId_1.toNumber());
      console.log("");

      let slotDetail_1 = {
        name: 'BigShow#1',
        description: 'for testing desc',
        image: 'https://example.com/img/1.jpg',
        projectId:  eventId_1,
        metadataURI: "https://example.com/event/" + eventId_1.toString(),
      };
      
      //批量铸造
      tx = await this.token.mintEventToManyUsers(slotDetail_1, [ firstOwner.address, secondOwner.address]);
      receipt = await tx.wait();
      transferEvent = receipt.events.filter(e => e.event === 'ProjectToken')[0];
      let tokenId = transferEvent.args['tokenId'];
      console.log("tokenId:", tokenId.toNumber());
      console.log("");

    });
    context('should mint many tokens', function () {
      it('both balance should be 1', async function () {
        expect(await this.token['balanceOf(address)'](firstOwner.address)).to.be.equal(1);
        expect(await this.token['balanceOf(address)'](secondOwner.address)).to.be.equal(1);
      });
    });
  });
}



module.exports = {
  shouldBehaveLikeERC3525,
  // shouldBehaveLikeERC3525Metadata,
  // shouldBehaveLikeERC3525SlotEnumerable,
}