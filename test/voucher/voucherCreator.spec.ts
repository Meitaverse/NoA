import { BigNumber } from '@ethersproject/bignumber';
import { parseEther } from '@ethersproject/units';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';

import { 
  ERC20__factory,
  DerivativeNFT,
  DerivativeNFT__factory,
  MockERC1155CreatorExtensionOverride,
  MockERC1155CreatorExtensionOverride__factory,
  MockERC1155CreatorExtensionBurnable,
  MockERC1155CreatorExtensionBurnable__factory,
 } from '../../typechain';
import { MAX_UINT256, ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import { TransactionReceipt, TransactionResponse } from '@ethersproject/providers';

import { 
  collectReturningTokenId, 
  getTimestamp, 
  matchEvent, 
  waitForTx 
} from '../helpers/utils';


import {
  abiCoder,
  INITIAL_SUPPLY,
  VOUCHER_AMOUNT_LIMIT,
  FIRST_PROFILE_ID,
  SECOND_PROFILE_ID,
  THIRD_PROFILE_ID,
  FOUR_PROFILE_ID,
  FIRST_HUB_ID,
  FIRST_PROJECT_ID,
  FIRST_DNFT_TOKEN_ID,
  SECOND_DNFT_TOKEN_ID,
  FIRST_PUBLISH_ID,
  GENESIS_FEE_BPS,
  DEFAULT_COLLECT_PRICE,
  DEFAULT_TEMPLATE_NUMBER,
  NickName,
  NickName3,
  governance,
  manager,
  makeSuiteCleanRoom,
  MAX_PROFILE_IMAGE_URI_LENGTH,
  mockModuleData,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  userAddress,
  user,
  userTwo,
  userTwoAddress,
  sbtContract,
  metadataDescriptor,
  publishModule,
  feeCollectModule,
  template,
  receiverMock,
  moduleGlobals,
  bankTreasuryContract,
  deployer,
  voucherContract,
  currency,
  deployerAddress,
  userThreeAddress,
  userThree,
} from '../__setup.spec';

import { 
  createProfileReturningTokenId,
} from '../helpers/utils';
import { ContractTransaction, ethers } from 'ethers';

let derivativeNFT: DerivativeNFT;
const FIRST_VOUCHER_TOKEN_ID = 1;
const SECOND_VOUCHER_TOKEN_ID = 2;
let receipt: TransactionReceipt;
let original_balance = 10000;
let baseApprover: MockERC1155CreatorExtensionOverride
let extApprover: MockERC1155CreatorExtensionOverride
let extAnon: MockERC1155CreatorExtensionOverride

makeSuiteCleanRoom('Voucher Creator', function () {

    beforeEach(async function () {

        expect(
        await createProfileReturningTokenId({
            sender: user,
            vars: {
            wallet: userAddress,
            nickName: NickName,
            imageURI: MOCK_PROFILE_URI,
            },
            }) 
        ).to.eq(SECOND_PROFILE_ID);

        expect(
        await createProfileReturningTokenId({
            sender: userTwo,
            vars: {
            wallet: userTwoAddress,
            nickName: NickName3,
            imageURI: MOCK_PROFILE_URI,
            },
            }) 
        ).to.eq(THIRD_PROFILE_ID);

        expect(await manager.getWalletBySoulBoundTokenId(SECOND_PROFILE_ID)).to.eq(userAddress);
        expect(await manager.getWalletBySoulBoundTokenId(THIRD_PROFILE_ID)).to.eq(userTwoAddress);

    });


    context('Voucher generate', function () {
      beforeEach(async () => {
        //user buy some SBT Values 
        await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});
      });

      it('User should success mint a voucher and transfer SBT Value to bank treasury', async function () {
        await voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [original_balance], [''])
        expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(0);
      });
    });
    
    context('Negatives', function () {

        it('Should faild to mint a voucher when have insufficient balance', async function () {
        
            await expect(
              voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [original_balance ], [''])
            ).to.be.reverted;
    
            expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(0);
           
    
          });
    
          it('Should faild to mint a voucher when amount is zero', async function () {
    
            await expect(
              voucherContract.connect(user).mintBaseNew(
                SECOND_PROFILE_ID, [userAddress], [0], ['']
              )
            ).to.be.revertedWith(ERRORS.AmountSBT_Is_Zero);
    
            expect((await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber()).to.eq(0);
           
          });

    });

    context('Voucher Creator', function () {
        beforeEach(async () => {
            //user buy some SBT Values 
            await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: original_balance});

            //mock voucher extension override
            baseApprover = await new MockERC1155CreatorExtensionOverride__factory(deployer).deploy(
                voucherContract.address
            );
  
            extApprover = await new MockERC1155CreatorExtensionOverride__factory(deployer).deploy(
                voucherContract.address
            );

            extAnon = await new MockERC1155CreatorExtensionOverride__factory(deployer).deploy(
                voucherContract.address
            );
            
          });
    
        it('supportsInterface test', async function () {
                
            // ICreatorCoreV1
            expect(await voucherContract.supportsInterface('0x28f10a21')).eq(true);
            
            // Creator Core Royalites
            expect(await voucherContract.supportsInterface('0xbb3bafd6')).eq(true);
            
            // EIP-2981 Royalites
            expect(await voucherContract.supportsInterface('0x2a55205a')).eq(true);
            
            // RaribleV1 Royalites
            expect(await voucherContract.supportsInterface('0xb7799584')).eq(true);

            // Foundation Royalites
            expect(await voucherContract.supportsInterface('0xd5a06d4c')).eq(true);
        
        });

        it('voucher should support transfer approvals', async () => {
            await voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [original_balance], [''])
            let sbtValue = await voucherContract.balanceOf(userAddress, FIRST_VOUCHER_TOKEN_ID);

            expect(sbtValue).to.eq(original_balance);
        
            await voucherContract.connect(user).safeTransferFrom(
                userAddress, 
                userTwoAddress, 
                FIRST_VOUCHER_TOKEN_ID,
                original_balance,
                []
            );

        });

        it('voucher should support batchTransfer ', async () => {
            await voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [original_balance], [''])
            let sbtValue = await voucherContract.balanceOf(userAddress, FIRST_VOUCHER_TOKEN_ID);

            expect(sbtValue).to.eq(original_balance);
        
            await voucherContract.connect(user).safeBatchTransferFrom(
                userAddress, 
                userTwoAddress, 
                [FIRST_VOUCHER_TOKEN_ID],
                [original_balance],
                []
            );
        });
    
        it('extension creator should support transfer approvals', async () => {
            await baseApprover.connect(deployer).setApproveEnabled(true);
            await extApprover.connect(deployer).setApproveEnabled(true);
            await extAnon.connect(deployer).setApproveEnabled(true);
            await voucherContract.connect(deployer)['registerExtension(address,string)'](extApprover.address, "");
            await voucherContract.connect(deployer)['registerExtension(address,string)'](extAnon.address, "");


            // mint 3 tokens, one base, one on approval extension, one on anon extension
            await voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [1000], [''])     
            await extApprover.connect(user).testMintNew(SECOND_PROFILE_ID, [userAddress], [1000], [''])
            //TODO ??
            await extAnon.connect(userTwo).testMintNew(SECOND_PROFILE_ID, [userAddress], [1000], [''])

            await voucherContract.connect(user).safeTransferFrom(
                userAddress, 
                userTwoAddress, 
                1,
                1000,
                []
            );

            await voucherContract.connect(user).safeTransferFrom(
                userAddress, 
                userTwoAddress, 
                2,
                1000,
                []
            );

            await voucherContract.connect(user).safeTransferFrom(
                userAddress, 
                userTwoAddress, 
                3,
                1000,
                []
            );

            // set base approver but don't block transfers
            await expect(
                voucherContract.connect(user).setApproveTransfer(
                    baseApprover.address
                )
            ).to.be.reverted;

            await voucherContract.connect(deployer).setApproveTransfer(baseApprover.address);

            expect(await voucherContract.getApproveTransfer()).eq(baseApprover.address);

            await voucherContract.connect(userTwo).safeBatchTransferFrom(userTwoAddress, userAddress, [1], [1000], []);
            await voucherContract.connect(userTwo).safeBatchTransferFrom(userTwoAddress, userAddress, [2], [1000], []);
            await voucherContract.connect(userTwo).safeBatchTransferFrom(userTwoAddress, userAddress, [3], [1000], []);

            // block extension only
            await extApprover.connect(deployer).setApproveEnabled(false);
            await voucherContract.connect(user).safeTransferFrom(
                userAddress, 
                userTwoAddress, 
                1,
                1000,
                []
            );

            await expect(voucherContract.connect(user).safeTransferFrom(
                userAddress, 
                userTwoAddress, 
                2,
                1000,
                []
            )).to.be.reverted;

            await voucherContract.connect(user).safeTransferFrom(
                userAddress, 
                userTwoAddress, 
                3,
                1000,
                []
            );

            // block on base; approval extension override
            await baseApprover.connect(deployer).setApproveEnabled(false);
            await extApprover.connect(deployer).setApproveEnabled(true);

            await expect(voucherContract.connect(userTwo).safeTransferFrom(
                userTwoAddress, 
                userAddress, 
                1,
                1000,
                []
            )).to.be.reverted;


            await expect(voucherContract.connect(user).safeTransferFrom(
                userAddress, 
                userTwoAddress, 
                2,
                1000,
                []
            )).to.not.be.reverted;


            await expect(voucherContract.connect(userTwo).safeTransferFrom(
                userTwoAddress, 
                userAddress, 
                3,
                1000,
                []
            )).to.not.be.reverted;

        });

        it('voucher should respect royalty override order', async function () {
            let extension = await new MockERC1155CreatorExtensionOverride__factory(deployer).deploy(
                voucherContract.address
            );

            await voucherContract.connect(deployer)['registerExtension(address,string)'](extension.address, "http://extension/");

            await extension.connect(deployer).setApproveTransfer(voucherContract.address, false);

            // royalty priority (highest to lowest)
            // 1. token
            // 2. extension override 
            // 3. extension default 
            // 4. creator default

            await extension.connect(user).testMintNew(SECOND_PROFILE_ID, [userAddress], [1000], [''])
            
            await voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [1000], [''])

            let [receipts, royalties] = await voucherContract.getRoyalties(1);
            expect( receipts.length ).eq(0);
            expect( royalties.length ).eq(0);

            let [receipts2, royalties2] = await voucherContract.getRoyalties(2);
            expect( receipts2.length ).eq(0);
            expect( royalties2.length ).eq(0);

            await voucherContract.connect(deployer)['setRoyalties(address[],uint256[])']([userTwoAddress], [1]);
            
            [receipts, royalties] = await voucherContract.getRoyalties(1);
            expect( receipts[0] ).eq(userTwoAddress);
            expect( royalties[0] ).eq(1);
            
            [receipts2, royalties2] = await voucherContract.getRoyalties(2);
            expect( receipts2[0] ).eq(userTwoAddress);
            expect( royalties2[0] ).eq(1);

            await voucherContract.connect(deployer).setRoyaltiesExtension(extension.address, [userTwoAddress], [10]);
            
            [receipts, royalties] = await voucherContract.getRoyalties(1);
            expect( receipts[0] ).eq(userTwoAddress);
            expect( royalties[0] ).eq(10);
            
            [receipts2, royalties2] = await voucherContract.getRoyalties(2);
            expect( receipts2[0] ).eq(userTwoAddress);
            expect( royalties2[0] ).eq(1);

            await extension.connect(user).setRoyaltyOverrides(1, [deployerAddress], [100]);
            
            [receipts, royalties] = await voucherContract.getRoyalties(1);
            expect( receipts[0] ).eq(deployerAddress);
            expect( royalties[0] ).eq(100);

            [receipts2, royalties2] = await voucherContract.getRoyalties(2);
            expect( receipts2[0] ).eq(userTwoAddress);
            expect( royalties2[0] ).eq(1);

            await voucherContract.connect(deployer)['setRoyalties(uint256,address[],uint256[])'](1, [userThreeAddress], [200]);

            [receipts, royalties] = await voucherContract.getRoyalties(1);
            expect( receipts[0] ).eq(userThreeAddress);
            expect( royalties[0] ).eq(200);

            [receipts2, royalties2] = await voucherContract.getRoyalties(2);
            expect( receipts2[0] ).eq(userTwoAddress);
            expect( royalties2[0] ).eq(1);

        });

        it('voucher permission test', async function () {


            await expect( 
                voucherContract.connect(userTwo)['registerExtension(address,string)'](userTwoAddress, 'http://extension')
            ).to.be.revertedWith("AdminControl: Must be owner or admin");
            
            await expect( 
                voucherContract.connect(userTwo).unregisterExtension(userTwoAddress)
            ).to.be.revertedWith("AdminControl: Must be owner or admin");

            await expect( 
                voucherContract.connect(userTwo).blacklistExtension(userTwoAddress)
            ).to.be.revertedWith("AdminControl: Must be owner or admin");
            
            await expect( 
                voucherContract.connect(userTwo)['setBaseTokenURIExtension(string)']('http://extension')
            ).to.be.revertedWith("Must be registered extension");
            
            await expect( 
                voucherContract['setBaseTokenURIExtension(string)']('http://extension')
            ).to.be.revertedWith("Must be registered extension");

            await expect( 
                voucherContract.connect(userTwo)['setTokenURIPrefixExtension(string)']('http://extension')
            ).to.be.revertedWith("Must be registered extension");

            await expect( 
                voucherContract.connect(userTwo)['setTokenURIExtension(uint256,string)'](1, 'http://extension')
            ).to.be.revertedWith("Must be registered extension");
            
            await expect( 
                voucherContract.connect(userTwo)['setTokenURIExtension(uint256[],string[])']([1], ['http://extension'])
            ).to.be.revertedWith("Must be registered extension");

            await expect( 
                voucherContract.connect(userTwo)['setBaseTokenURI(string)']('http://extension')
            ).to.be.revertedWith("AdminControl: Must be owner or admin");
            
            await expect( 
                voucherContract.connect(userTwo)['setTokenURIPrefix(string)']('http://base')
            ).to.be.revertedWith("AdminControl: Must be owner or admin");
            
            await expect( 
                voucherContract.connect(userTwo)['setTokenURI(uint256,string)'](1, 'http://base')
            ).to.be.revertedWith("AdminControl: Must be owner or admin");
            
            await expect( 
                voucherContract.connect(userTwo)['setTokenURI(uint256[],string[])']([1], ['http://base'])
            ).to.be.revertedWith("AdminControl: Must be owner or admin");

            await expect( 
                voucherContract.connect(userTwo).setMintPermissions(userTwoAddress, userTwoAddress)
            ).to.be.revertedWith("AdminControl: Must be owner or admin");

            // await truffleAssert.reverts(creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [1], [""], {from:anyone}), "AdminControl: Must be owner or admin");
            await expect( 
                voucherContract.connect(userTwo)['mintBaseNew(uint256,address[],uint256[],string[])'](SECOND_PROFILE_ID, [userAddress], [100], [''])
            ).to.not.be.reverted;

            
            // await truffleAssert.reverts(creator.methods['mintExtensionNew(address[],uint256[],string[])']([anyone], [1], [""], {from:anyone}), "Must be registered extension");
            // await truffleAssert.reverts(creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone], [1], [100], {from:anyone}), "AdminControl: Must be owner or admin");
            // await truffleAssert.reverts(creator.methods['mintExtensionExisting(address[],uint256[],uint256[])']([anyone], [1], [100], {from:anyone}), "Must be registered extension");
            // await truffleAssert.reverts(creator.methods['setRoyalties(address[],uint256[])']([anyone], [100], {from:anyone}), "AdminControl: Must be owner or admin");
            // await truffleAssert.reverts(creator.methods['setRoyalties(uint256,address[],uint256[])'](1, [anyone], [100], {from:anyone}), "AdminControl: Must be owner or admin");
            // await truffleAssert.reverts(creator.methods['setRoyaltiesExtension(address,address[],uint256[])'](anyone, [anyone], [100], {from:anyone}), "AdminControl: Must be owner or admin");
            // await truffleAssert.reverts(creator.setApproveTransferExtension(true, {from:anyone}), "Must be registered extension");

        });

        it('voucher blacklist extension test', async function() {
            await expect(
                voucherContract.connect(deployer).blacklistExtension(voucherContract.address )
            ).to.be.revertedWith('Cannot blacklist yourself');

            voucherContract.connect(deployer).blacklistExtension(userTwoAddress);
        });

        it('voucher functionality test', async function () {

            expect((await voucherContract.getExtensions()).length).eq(0);

            await voucherContract.connect(deployer).setBaseTokenURI("http://base/");

            const extension1 = await new MockERC1155CreatorExtensionBurnable__factory(deployer).deploy(
                voucherContract.address
            );

            expect((await voucherContract.getExtensions()).length).eq(0);

            await expect(
                extension1.onBurn(userTwoAddress, [1], [100])
            ).to.be.revertedWith('Can only be called by token creator');

            await voucherContract.connect(deployer)['registerExtension(address,string)'](extension1.address, "http://extension1/");

            expect((await voucherContract.getExtensions()).length).eq(1);
            
            const extension2 = await new MockERC1155CreatorExtensionBurnable__factory(deployer).deploy(
                voucherContract.address
            );

            expect((await voucherContract.getExtensions()).length).eq(1);

            // Admins can register extensions
            await voucherContract.connect(deployer).approveAdmin(userTwoAddress);

            await voucherContract.connect(userTwo)['registerExtension(address,string)'](extension2.address, "http://extension/");
            expect((await voucherContract.getExtensions()).length).eq(2);

            // Minting cost
            const mintBase = await voucherContract.connect(deployer).estimateGas.mintBaseNew(SECOND_PROFILE_ID, [userAddress], [100], [''])
            console.log("No Extension mint gas estimate: %s", mintBase);
            const mintGasEstimate = await extension1.connect(deployer).estimateGas.testMintNew(SECOND_PROFILE_ID, [userAddress], [100], [''])
            console.log("Extension mint gas estimate: %s", mintGasEstimate);


            // Test minting
            await extension1.connect(userTwo).testMintNew(SECOND_PROFILE_ID, [userAddress], [100], [''])

            let newTokenId1 = 1;
            expect(
                await voucherContract.tokenExtension(newTokenId1)
            ).eq(extension1.address);


            // await extension1.testMintNew([another], [200], [""]);
            // let newTokenId2 = 2;

            // await extension2.testMintNew([anyone], [300], [""]);
            // let newTokenId3 = 3;

            // await extension1.testMintNew([anyone], [400], [""]);
            // let newTokenId4 = 4;

            // await extension1.testMintNew([anyone], [500], ["extension5"]);
            // let newTokenId5 = 5;

            // await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [600], [""], {from:owner});
            // let newTokenId6 = 6;
            // await truffleAssert.reverts(creator.tokenExtension(newTokenId6), "No extension for token");

            // await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [700], ["base7"], {from:owner});
            // let newTokenId7 = 7;
            // await truffleAssert.reverts(creator.tokenExtension(newTokenId7), "No extension for token");

            // await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [800], [""], {from:owner});
            // let newTokenId8 = 8;
            // await truffleAssert.reverts(creator.tokenExtension(newTokenId8), "No extension for token");

            // await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [900], [""], {from:owner});
            // let newTokenId9 = 9;
            // await truffleAssert.reverts(creator.tokenExtension(newTokenId9), "No extension for token");

            // // Check URI's
            // assert.equal(await creator.uri(newTokenId1), 'http://extension1/'+newTokenId1);
            expect(await voucherContract.uri(newTokenId1)).eq('http://extension1/'+newTokenId1);
            
            // assert.equal(await creator.uri(newTokenId2), 'http://extension1/'+newTokenId2);
            // assert.equal(await creator.uri(newTokenId3), 'http://extension2/'+newTokenId3);
            // assert.equal(await creator.uri(newTokenId4), 'http://extension1/'+newTokenId4);
            // assert.equal(await creator.uri(newTokenId5), 'extension5');
            // assert.equal(await creator.uri(newTokenId6), 'http://base/'+newTokenId6);
            // assert.equal(await creator.uri(newTokenId7), 'base7');
            // assert.equal(await creator.uri(newTokenId8), 'http://base/'+newTokenId8);
            // assert.equal(await creator.uri(newTokenId9), 'http://base/'+newTokenId9);


        });

        it('voucher batch mint test', async function () {

        });

        it('voucher permissions functionality test', async function () {

        });

        it('voucher royalites update test', async function () {


        });


    });



});
