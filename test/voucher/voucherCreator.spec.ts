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
  MockERC1155CreatorMintPermissions__factory,
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

        //user two buy some SBT Values 
        await bankTreasuryContract.connect(userTwo).buySBT(THIRD_PROFILE_ID, {value: original_balance});

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

            //user two buy some SBT Values 
            await bankTreasuryContract.connect(userTwo).buySBT(THIRD_PROFILE_ID, {value: original_balance});
            
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
            await extAnon.connect(user).testMintNew(SECOND_PROFILE_ID, [userAddress], [1000], [''])

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

            await expect( 
                voucherContract.connect(userTwo)['mintBaseNew(uint256,address[],uint256[],string[])'](SECOND_PROFILE_ID, [userAddress], [100], [''])
            ).to.be.revertedWith("NotProfileOwner");
            
            await expect( 
                voucherContract.connect(userThree).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [200], [''])
            ).to.be.revertedWith("NotProfileOwner");

            await expect( 
                voucherContract.connect(user)['mintExtensionNew(uint256,address[],uint256[],string[])'](SECOND_PROFILE_ID, [userAddress], [100], [''])
            ).to.be.revertedWith("Must be registered extension");

            await expect( 
                voucherContract.connect(userTwo)['setRoyalties(uint256,address[],uint256[])'](SECOND_PROFILE_ID, [userTwoAddress], [100])
            ).to.be.revertedWith("AdminControl: Must be owner or admin");
            
            await expect( 
                voucherContract.connect(userTwo)['setRoyaltiesExtension(address,address[],uint256[])'](userTwoAddress, [userTwoAddress], [100])
            ).to.be.revertedWith("AdminControl: Must be owner or admin");

            await expect( 
                voucherContract.connect(userTwo).setApproveTransferExtension(true)
            ).to.be.revertedWith("Must be registered extension");
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
            const mintBase = await voucherContract.connect(user).estimateGas.mintBaseNew(SECOND_PROFILE_ID, [userAddress], [100], [''])
            console.log("No Extension mint gas estimate: %s", mintBase);
            const mintGasEstimate = await extension1.connect(user).estimateGas.testMintNew(SECOND_PROFILE_ID, [userAddress], [100], [''])
            console.log("Extension mint gas estimate: %s", mintGasEstimate);


            // Test minting
            await extension1.connect(user).testMintNew(SECOND_PROFILE_ID, [userAddress], [100], [''])

            let newTokenId1 = 1;
            expect(
                await voucherContract.tokenExtension(newTokenId1)
            ).eq(extension1.address);

        });

        it('voucher batch mint test', async function () {
            await voucherContract.connect(deployer).setBaseTokenURI("http://base/");

            const extension = await new MockERC1155CreatorExtensionBurnable__factory(deployer).deploy(
                voucherContract.address
            );

            await voucherContract.connect(deployer)['registerExtension(address,string)'](extension.address, 'http://extension/');
            
            // Test minting
            await extension.connect(user).testMintNew(SECOND_PROFILE_ID, [userAddress], [100,200,300,400], ["","","t3","t4"]);
            
            await extension.connect(user)['testMintNew(uint256,address[],uint256[],string[])'](SECOND_PROFILE_ID, [userAddress], [500], []);

            await extension.connect(user)['testMintNew(uint256,address[],uint256[],string[])'](SECOND_PROFILE_ID, [userAddress,userTwoAddress], [600,601], ["t6"]);

            await expect(
                    extension.connect(user).testMintNew(SECOND_PROFILE_ID, [userAddress, userTwoAddress], [600,700,800], [])
            ).to.be.revertedWith("Invalid input");   
            
   
            let newTokenId1 = 1;
            let newTokenId2 = 2;
            let newTokenId3 = 3;
            let newTokenId4 = 4;
            let newTokenId5 = 5;
            let newTokenId6 = 6;

            expect(
                await voucherContract.tokenExtension(newTokenId1)
            ).eq(extension.address);
            expect(
                await voucherContract.tokenExtension(newTokenId2)
            ).eq(extension.address);
            expect(
                await voucherContract.tokenExtension(newTokenId3)
            ).eq(extension.address);
            expect(
                await voucherContract.tokenExtension(newTokenId4)
            ).eq(extension.address);
            expect(
                await voucherContract.tokenExtension(newTokenId5)
            ).eq(extension.address);
            expect(
                await voucherContract.tokenExtension(newTokenId6)
            ).eq(extension.address);


            // Check balances
            expect(
                await voucherContract.balanceOf(userAddress, newTokenId1)
            ).eq(100);
            expect(
                await voucherContract.balanceOf(userAddress, newTokenId2)
            ).eq(200);
            expect(
                await voucherContract.balanceOf(userAddress, newTokenId3)
            ).eq(300);
            expect(
                await voucherContract.balanceOf(userAddress, newTokenId4)
            ).eq(400);
            expect(
                await voucherContract.balanceOf(userAddress, newTokenId5)
            ).eq(500);
            expect(
                await voucherContract.balanceOf(userAddress, newTokenId6)
            ).eq(600);
            expect(
                await voucherContract.balanceOf(userTwoAddress, newTokenId6)
            ).eq(601);


        });

        it('voucher permissions functionality test', async function () {
            const extension1 = await new MockERC1155CreatorExtensionBurnable__factory(deployer).deploy(
                voucherContract.address
            );

            await voucherContract.connect(deployer)['registerExtension(address,string)'](extension1.address, 'http://extension1/');
        
            
            const extension2 = await new MockERC1155CreatorExtensionBurnable__factory(deployer).deploy(
                voucherContract.address
            );

            await voucherContract.connect(deployer)['registerExtension(address,string)'](extension2.address, 'http://extension2/');

            await expect(
                new MockERC1155CreatorMintPermissions__factory(deployer).deploy(
                    userTwoAddress
                )
            ).to.be.revertedWith("Must implement IERC1155CreatorCore");

            const permissions = await new MockERC1155CreatorMintPermissions__factory(deployer).deploy(
                voucherContract.address
            );

            await expect(
                permissions.approveMint(userTwoAddress, [userTwoAddress], [1], [100])
            ).to.be.revertedWith("Can only be called by token creator");
            
            await expect(
                voucherContract.connect(deployer).setMintPermissions(extension1.address, userTwoAddress)
            ).to.be.revertedWith("Invalid address");
            

            await voucherContract.connect(deployer).setMintPermissions(extension1.address, permissions.address);

            await extension1.connect(user).testMintNew(SECOND_PROFILE_ID, [userAddress], [100], [''])
            await extension2.connect(userTwo).testMintNew(THIRD_PROFILE_ID, [userTwoAddress], [100], [''])

            await permissions.setApproveEnabled(false);

            await expect(
                extension1.connect(userTwo).testMintNew(THIRD_PROFILE_ID, [userTwoAddress], [100], [''])
            ).to.be.revertedWith("MockERC1155CreatorMintPermissions: Disabled");

            await extension2.connect(userTwo).testMintNew(THIRD_PROFILE_ID, [userTwoAddress], [100], ['']);

            await voucherContract.connect(deployer).setMintPermissions(extension1.address, '0x0000000000000000000000000000000000000000');

            await extension1.connect(userTwo).testMintNew(THIRD_PROFILE_ID, [userTwoAddress], [100], ['']);
            
            await extension2.connect(userTwo).testMintNew(THIRD_PROFILE_ID, [userTwoAddress], [100], ['']);
        });

        it('voucher royalites update test', async function () {
            await voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [100], ['']);
            let tokenId1 = 1;

            // No royalties
            let results = await voucherContract.getRoyalties(tokenId1);
            expect(results[0].length).eq(0);
            expect(results[1].length).eq(0);
            
            await expect( 
                voucherContract.connect(deployer)['setRoyalties(uint256,address[],uint256[])'](tokenId1, [userTwoAddress, userThreeAddress], [9999,1])
            ).to.be.revertedWith("Invalid total royalties");
              
            await expect( 
                voucherContract.connect(deployer)['setRoyalties(uint256,address[],uint256[])'](tokenId1, [userThreeAddress], [1,2])
            ).to.be.revertedWith("Invalid input");
              
            
            await expect( 
                voucherContract.connect(deployer)['setRoyalties(uint256,address[],uint256[])'](tokenId1, [userTwoAddress, userThreeAddress], [1])
            ).to.be.revertedWith("Invalid input");
              
             // Set token royalties
            await voucherContract.connect(deployer)['setRoyalties(uint256,address[],uint256[])'](tokenId1, [userTwoAddress, userThreeAddress], [123, 456]);

            results = await voucherContract.getRoyalties(tokenId1);
            expect(results[0].length).eq(2);
            expect(results[1].length).eq(2);

            results = await voucherContract.getFees(tokenId1);
            expect(results[0].length).eq(2);
            expect(results[1].length).eq(2);

            let results2 = await voucherContract.getFeeRecipients(tokenId1);
            expect(results2.length).eq(2);

            let results3 = await voucherContract.getFeeBps(tokenId1);
            expect(results3.length).eq(2);

            await expect (
                voucherContract.royaltyInfo(tokenId1, 10000)
            ).to.be.revertedWith("More than 1 royalty receiver");


            const extension = await new MockERC1155CreatorExtensionBurnable__factory(deployer).deploy(
                voucherContract.address
            );

            await voucherContract.connect(deployer)['registerExtension(address,string)'](extension.address, 'http://extension/');

            await extension.connect(userTwo).testMintNew(THIRD_PROFILE_ID, [userTwoAddress], [200], [''])

            var tokenId2 = 2;

            // No royalties
            results = await voucherContract.getRoyalties(tokenId2);
            expect(results[0].length).eq(0);
            expect(results[1].length).eq(0);

            await expect( 
                voucherContract.connect(deployer)['setRoyaltiesExtension(address,address[],uint256[])'](extension.address, [userAddress, userTwoAddress], [9999,1])
            ).to.be.revertedWith("Invalid total royalties");

            await expect( 
                voucherContract.connect(deployer)['setRoyaltiesExtension(address,address[],uint256[])'](extension.address, [userAddress], [1,2])
            ).to.be.revertedWith("Invalid input");

            await expect( 
                voucherContract.connect(deployer)['setRoyaltiesExtension(address,address[],uint256[])'](extension.address, [userAddress, userTwoAddress], [1])
            ).to.be.revertedWith("Invalid input");

            // Set royalties
            await voucherContract.connect(deployer)['setRoyaltiesExtension(address,address[],uint256[])'](extension.address, [userAddress], [123]);

            results = await voucherContract.getRoyalties(tokenId2);
            expect(results[0].length).eq(1);
            expect(results[1].length).eq(1);

            let results4 = await voucherContract.royaltyInfo(tokenId2, 10000);
            expect(results4[1]).eq(10000*123/10000);

            await voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [300], ['']);
            
            let tokenId3 = 3;
            await voucherContract.connect(user).mintBaseNew(SECOND_PROFILE_ID, [userAddress], [400], ['']);
           let tokenId4 = 4;

            results = await voucherContract.getRoyalties(tokenId3);
            expect(results[0].length).eq(0);
            expect(results[1].length).eq(0);

            results = await voucherContract.getRoyalties(tokenId4);
            expect(results[0].length).eq(0);
            expect(results[1].length).eq(0);     
            
             // Set default royalties
            await expect( 
                voucherContract.connect(deployer)['setRoyalties(address[],uint256[])']([userTwoAddress, userThreeAddress], [9999,1])
            ).to.be.revertedWith("Invalid total royalties");

            await expect( 
                voucherContract.connect(deployer)['setRoyalties(address[],uint256[])']([userTwoAddress], [1,2])
            ).to.be.revertedWith("Invalid input");

            await expect( 
                voucherContract.connect(deployer)['setRoyalties(address[],uint256[])']([userTwoAddress, userThreeAddress], [1])
            ).to.be.revertedWith("Invalid input");

            await voucherContract.connect(deployer)['setRoyalties(address[],uint256[])']([userTwoAddress], [456]);

            results = await voucherContract.getRoyalties(tokenId1);
            expect(results[0].length).eq(2);
            expect(results[1].length).eq(2);

            results = await voucherContract.getRoyalties(tokenId2);
            expect(results[0].length).eq(1);
            expect(results[1].length).eq(1);
            
            results = await voucherContract.getRoyalties(tokenId3);
            expect(results[0].length).eq(1);
            expect(results[1].length).eq(1);
            expect(results[0][0]).eq(userTwoAddress);

             results = await voucherContract.getRoyalties(tokenId4);
            expect(results[0].length).eq(1);
            expect(results[1].length).eq(1);
            expect(results[0][0]).eq(userTwoAddress);

            // Unset royalties
            await voucherContract.connect(deployer)['setRoyalties(address[],uint256[])']([], []);
            results = await voucherContract.getRoyalties(tokenId3);
            expect(results[0].length).eq(0);
            expect(results[1].length).eq(0);

            results = await voucherContract.getRoyalties(tokenId4);
            expect(results[0].length).eq(0);
            expect(results[1].length).eq(0);

            await voucherContract.connect(deployer)['setRoyaltiesExtension(address,address[],uint256[])'](extension.address, [], []);
            results = await voucherContract.getRoyalties(tokenId4);
            expect(results[0].length).eq(0);
            expect(results[1].length).eq(0);
        });


    });



});
