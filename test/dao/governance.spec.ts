import { BigNumber } from '@ethersproject/bignumber';
import { parseEther } from '@ethersproject/units';
import {  ethers } from "hardhat";

import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';

import {
    FUNC,
    PROPOSAL_DESCRIPTION,
    NEW_STORE_VALUE,
    VOTING_DELAY,
    VOTING_PERIOD,
    MIN_DELAY,
    ADDRESS_ZERO,
} from "../../helper-hardhat-config"

import { moveBlocks } from "../../utils/move-blocks"
import { moveTime } from "../../utils/move-time"

import { 
  ERC20__factory,
  DerivativeNFT,
  DerivativeNFT__factory,
  TimeLock,
  TimeLock__factory,
  GovernorContract,
  GovernorContract__factory,
 } from '../../typechain';
import { MAX_UINT256, ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';

import { 
  DerivativeNFTState,
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
  governorContract,
  box,
  timeLock,
  
} from '../__setup.spec';

import { 
    createProfileReturningTokenId,
  } from '../helpers/utils';
import { constants } from 'ethers';

  const voteWay = 1 // for
  const reason = "I like bit soul"

makeSuiteCleanRoom('Bank Treasury', function () {
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

    context('Vote', function () {

        it("can only be changed through governance", async () => {
            await expect(box.connect(user).store(55)).to.be.revertedWith("Ownable: caller is not the owner")
        });

/*
        it("One user proposes, votes, waits, queues, and then Box executes", async () => {
            //Buy SBT Value to user for vote , value 必须大于90万
            await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: 900000});
            let balanceOfUser =(await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber();
            // console.log('balance of user: ', balanceOfUser);

            const transactionResponse = sbtContract.connect(user).delegate(userAddress, SECOND_PROFILE_ID);
            // await transactionResponse.wait(1);
            const receipt = await waitForTx(transactionResponse);
            matchEvent(
                receipt,
                'DelegateChanged',
                [
                  userAddress, 
                  ZERO_ADDRESS, 
                  userAddress,
                  SECOND_PROFILE_ID,
                ],
              );

  
            // console.log(`Checkpoints: ${await sbtContract.numCheckpoints(userAddress)}`);
            let checkpoints = await sbtContract.checkpoints(userAddress, 0);
            // console.log(`checkpoints.fromBlock: ${checkpoints.fromBlock}`);
            // console.log(`checkpoints.votes: ${checkpoints.votes}`);
         
             //返回 user 选择的委托。    
            // console.log("delegates: ",await sbtContract.delegates(userAddress));

            //This is done so as to transfer the ownership to timelock contract so that it can execute the operation
            const transferTx = await box.transferOwnership(timeLock.address);
            await transferTx.wait(1);

            const proposerRole = await timeLock.PROPOSER_ROLE();
            const executorRole = await timeLock.EXECUTOR_ROLE();
            const adminRole = await timeLock.TIMELOCK_ADMIN_ROLE();
    
            const proposerTx = await timeLock.grantRole(proposerRole, governorContract.address);
            await proposerTx.wait(1);
            const executorTx = await timeLock.grantRole(executorRole, ADDRESS_ZERO);
            await executorTx.wait(1);
            const revokeTx = await timeLock.revokeRole(adminRole, await deployer.getAddress());
            await revokeTx.wait(1);
    
            // propose
            const encodedFunctionCall = box.interface.encodeFunctionData(FUNC, [NEW_STORE_VALUE]);
            
            //创建一个propose的交易
            const proposeTx = await governorContract.propose( //connect(deployer).
                [box.address],
                [0],
                [encodedFunctionCall],
                PROPOSAL_DESCRIPTION,
            );  

            const proposeReceipt = await proposeTx.wait(1);
            const proposalId = proposeReceipt.events![0].args!.proposalId;
            // console.log('proposalId:', proposalId);

            let proposalState = await governorContract.state(proposalId);
            const proposalSnapShot = await governorContract.proposalSnapshot(proposalId);
            const proposalDeadline = await governorContract.proposalDeadline(proposalId);
    
            // 0 - Pending
            // console.log(`Pending! Current Proposal State: ${proposalState}`);
            // What block # the proposal was snapshot
            // console.log(`Current Proposal Snapshot: ${proposalSnapShot}`);
            // The block number the proposal voting expires
            // console.log(`Current Proposal Deadline: ${proposalDeadline}`);

            await moveBlocks(VOTING_DELAY + 1);
            // console.log();

            // user vote
            const voteTx = await governorContract.connect(user).castVoteWithReason(
                proposalId, 
                voteWay, 
                reason,
            );

            await voteTx.wait(1);

            proposalState = await governorContract.state(proposalId);

            // assert.equal(proposalState.toString(), "1")
            expect(proposalState.toString()).to.eq('1');

            
            // 1 - Active
            
            // console.log(`Active! Current Proposal State: ${proposalState}`);

            await moveBlocks(VOTING_PERIOD + 1);
            // console.log();
            
         
            // queue & execute
            // const descriptionHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(PROPOSAL_DESCRIPTION))
            const descriptionHash = ethers.utils.id(PROPOSAL_DESCRIPTION);
            const queueTx = await governorContract.connect(user).queue(
                [box.address], 
                [0], 
                [encodedFunctionCall], 
                descriptionHash
            );
            await queueTx.wait(1);

            await moveTime(MIN_DELAY + 1);
            await moveBlocks(1);
            // console.log();

            proposalState = await governorContract.state(proposalId);
            // assert.equal(proposalState.toString(), "5")
            expect(proposalState.toString()).to.eq('5');

            //5 - Queued
            // console.log(`Queued! Current Proposal State: ${proposalState}`);

            //获取票数
            const votes = await governorContract.getVotes(userAddress, 60);
            // console.log("votes", votes); 
            // console.log(`Checkpoints: ${await sbtContract.numCheckpoints(userAddress)}`);
            
            //(token.getPastTotalSupply(blockNumber) * quorumNumerator(blockNumber)) / quorumDenominator();
            //900000 * 10 / 100
            const quorum = await governorContract.quorum(63);
            // console.log("quorum: ", quorum);
            
            // console.log("\n Executing...");
            console.log
            const exTx = await governorContract.execute([box.address], [0], [encodedFunctionCall], descriptionHash);
            await exTx.wait(1);

            console.log((await box.retrieve()).toString());

            proposalState = await governorContract.state(proposalId);
            // assert.equal(proposalState.toString(), "7")
            expect(proposalState.toString()).to.eq('7');
            // console.log();
            //7 - Executed
            // console.log(`Executed! Current Proposal State: ${proposalState}`);
        
        });
        */

/*
        it("onlyGov proposes, votes, waits, queues, and then Manager onlyGov functions executes", async () => {
            //mint Value to user for vote , value 必须大于90万
            await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: 10000});
            let balanceOfUser =(await sbtContract['balanceOf(uint256)'](SECOND_PROFILE_ID)).toNumber();
            // console.log('balance of user: ', balanceOfUser);

            let balanceOfUserTwo =(await sbtContract['balanceOf(uint256)'](THIRD_PROFILE_ID)).toNumber();
            console.log('balance of userTwo: ', balanceOfUserTwo);

            const transactionResponse = sbtContract.connect(user).delegate(userAddress, SECOND_PROFILE_ID);
            // await transactionResponse.wait(1);
            const receipt = await waitForTx(transactionResponse);
            matchEvent(
                receipt,
                'DelegateChanged',
                [
                  userAddress, 
                  ZERO_ADDRESS, 
                  userAddress,
                  SECOND_PROFILE_ID,
                ],
              );

  
            // console.log(`Checkpoints: ${await sbtContract.numCheckpoints(userAddress)}`);
            let checkpoints = await sbtContract.checkpoints(userAddress, 0);
            // console.log(`checkpoints.fromBlock: ${checkpoints.fromBlock}`);
            // console.log(`checkpoints.votes: ${checkpoints.votes}`);
         
             //返回 user 选择的委托。    
            // console.log("delegates: ",await sbtContract.delegates(userAddress));

            //manager set governanor to timeLock contract
            await expect(
                manager.connect(governance).setTimeLock(timeLock.address)
            ).to.not.be.reverted;

            const proposerRole = await timeLock.PROPOSER_ROLE();
            const executorRole = await timeLock.EXECUTOR_ROLE();
            const adminRole = await timeLock.TIMELOCK_ADMIN_ROLE();
            // console.log('proposerRole: ', proposerRole);
            // console.log('executorRole: ', executorRole);
            // console.log('adminRole: ', adminRole);
    
            const proposerTx = await timeLock.grantRole(proposerRole, governorContract.address);
            await proposerTx.wait(1);

            // const executorTx = await timeLock.grantRole(executorRole, governorContract.address);
            // await executorTx.wait(1);
            // const executorTx2 = await timeLock.grantRole(executorRole, manager.address);
            // await executorTx2.wait(1);
            const executorTx = await timeLock.grantRole(executorRole, ADDRESS_ZERO);
            await executorTx.wait(1);
   
            const revokeTx = await timeLock.revokeRole(adminRole, await deployer.getAddress());
            await revokeTx.wait(1);
    
            // propose
            const FUNC_setDerivativeNFTState = 'setDerivativeNFTState';
            
            const encodedFunctionCall = manager.interface.encodeFunctionData(FUNC_setDerivativeNFTState, [FIRST_PROJECT_ID, DerivativeNFTState.Paused]);
            
            //创建一个propose的交易
            const proposeTx = await governorContract.propose( //connect(deployer).
                [manager.address],
                [0],
                [encodedFunctionCall],
                PROPOSAL_DESCRIPTION,
            );  

            const proposeReceipt = await proposeTx.wait(1);
            const proposalId = proposeReceipt.events![0].args!.proposalId;
            console.log('proposalId:', proposalId);

            let proposalState = await governorContract.state(proposalId);
            const proposalSnapShot = await governorContract.proposalSnapshot(proposalId);
            const proposalDeadline = await governorContract.proposalDeadline(proposalId);
    
            // 0 - Pending
            // console.log(`Pending! Current Proposal State: ${proposalState}`);
            // What block # the proposal was snapshot
            // console.log(`Current Proposal Snapshot: ${proposalSnapShot}`);
            // The block number the proposal voting expires
            // console.log(`Current Proposal Deadline: ${proposalDeadline}`);

            await moveBlocks(VOTING_DELAY + 1);
            console.log();

            // user vote
            const voteTx = await governorContract.connect(user).castVoteWithReason(
                proposalId, 
                voteWay, 
                reason,
            );

            await voteTx.wait(1);

            proposalState = await governorContract.state(proposalId);

            // assert.equal(proposalState.toString(), "1")
            expect(proposalState.toString()).to.eq('1');

            
            // 1 - Active
            
            // console.log(`Active! Current Proposal State: ${proposalState}`);

            await moveBlocks(VOTING_PERIOD + 1);
            // console.log();
            
         
            // queue & execute
            // const descriptionHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(PROPOSAL_DESCRIPTION))
            const descriptionHash = ethers.utils.id(PROPOSAL_DESCRIPTION);
            const queueTx = await governorContract.connect(user).queue(
                [manager.address], 
                [0], 
                [encodedFunctionCall], 
                descriptionHash
            );
            await queueTx.wait(1);

            await moveTime(MIN_DELAY + 1);
            await moveBlocks(1);
            console.log();

            proposalState = await governorContract.state(proposalId);
            // assert.equal(proposalState.toString(), "5")
            expect(proposalState.toString()).to.eq('5');

            //5 - Queued
            // console.log(`Queued! Current Proposal State: ${proposalState}`);

            //获取票数
            const votes = await governorContract.getVotes(userAddress, 60);
            console.log("votes", votes); 
            // console.log(`Checkpoints: ${await sbtContract.numCheckpoints(userAddress)}`);
            
            //(token.getPastTotalSupply(blockNumber) * quorumNumerator(blockNumber)) / quorumDenominator();
            //900000 * 10 / 100
            const quorum = await governorContract.quorum(63);
            console.log("quorum: ", quorum);
            
            // console.log("\n Executing...");
            console.log

            const exTx = await governorContract.execute([manager.address], [0], [encodedFunctionCall], descriptionHash);
            const exReceipt = await exTx.wait(1);
            
            // console.log((await manager.retrieve()).toString());

            balanceOfUserTwo =(await sbtContract['balanceOf(uint256)'](THIRD_PROFILE_ID)).toNumber();
            console.log('Executing finished! balance of userTwo: ', balanceOfUserTwo);

            proposalState = await governorContract.state(proposalId);

            // assert.equal(proposalState.toString(), "7")
            expect(proposalState.toString()).to.eq('7');
            // console.log();
            //7 - Executed
            console.log(`Executed! Current Proposal State: ${proposalState}`);
        
        });
*/        
    });

});