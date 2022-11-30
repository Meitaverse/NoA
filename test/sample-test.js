const { expect } = require("chai");
const { ethers } = require("hardhat");
const {MIN_DELAY,QUORUM_PERCENTAGE,VOTING_PERIOD,VOTING_DELAY,ADDRESS_ZERO }=require("../helper.config")
const {moveBlocks}=require("../move")
const {moveTime}=require("../move_time")
describe("Test governance contracts, proposals,voting and execution", function () {

    it("Testing proposal creation,voting ,execution by single user", async () => {
        [owner, addr1, addr2, admin] = await ethers.getSigners();
      
        //MyToken合约是一种特殊类型的ERC20合约，它实现了ERC20Votes扩展。这允许将投票权映射到过去余额
        // 的快照而不是当前余额
        MyToken = await ethers.getContractFactory("MyToken");
        deployedToken=await MyToken.deploy();
        await deployedToken.deployed();

        transactionResponse = await deployedToken.delegate(owner.address)
        await transactionResponse.wait(1);

        timeLock = await ethers.getContractFactory("TimeLock")
      
        deployedTimeLock=await timeLock.deploy(MIN_DELAY,[],[], owner.address);

        await deployedTimeLock.deployed();
       
        governor = await ethers.getContractFactory("GovernorContract")

        deployedGovernor=await governor.deploy(deployedToken.address,deployedTimeLock.address,QUORUM_PERCENTAGE,VOTING_PERIOD,VOTING_DELAY);
        await deployedGovernor.deployed()

        box = await ethers.getContractFactory("Box")
        deployedBox=await box.deploy()
        await deployedBox.deployed()
        /** This is done so as to transfer the ownership to timelock contract so that it can execute the operation */
        const transferTx = await deployedBox.transferOwnership(deployedTimeLock.address)
        await transferTx.wait(1)
        /**
        * Granting roles to the relevant parties
        */
        const proposerRole = await deployedTimeLock.PROPOSER_ROLE()
        const executorRole = await deployedTimeLock.EXECUTOR_ROLE()
        const adminRole = await deployedTimeLock.TIMELOCK_ADMIN_ROLE()

        const proposerTx = await deployedTimeLock.grantRole(proposerRole, deployedGovernor.address)
        await proposerTx.wait(1)
      
        const executorTx = await deployedTimeLock.grantRole(executorRole, ADDRESS_ZERO)
        await executorTx.wait(1)
        const revokeTx = await deployedTimeLock.revokeRole(adminRole, owner.address)
        await revokeTx.wait(1)
      
        const proposalDescription="propose this data"

        //投票之后要执行的函数及传参,执行store(77)
        let encodedFunctionCall = box.interface.encodeFunctionData("store", [77])

        transactionResponse = await deployedToken.delegate(owner.address)
        await transactionResponse.wait(1)


        const proposeTx = await deployedGovernor.propose([deployedBox.address],[0],[encodedFunctionCall],proposalDescription);

        await moveBlocks(VOTING_DELAY + 1)
        const proposeReceipt = await proposeTx.wait(1)

        //propose函数的输出是一个包含Proposal Id的交易。这是用来跟踪提案的。
        proposalId = proposeReceipt.events[0].args.proposalId
        console.log(`Proposed with proposal ID:\n  ${proposalId}`)

        let proposalState = await deployedGovernor.state(proposalId)
        const proposalSnapShot = await deployedGovernor.proposalSnapshot(proposalId)
        const proposalDeadline = await deployedGovernor.proposalDeadline(proposalId)

        // The state of the proposal. 1 is not passed. 0 is passed.
        console.log(`Current Proposal State: ${proposalState}`)
        // What block # the proposal was snapshot
        console.log(`Current Proposal Snapshot: ${proposalSnapShot}`)
        // The block number the proposal voting expires
        console.log(`Current Proposal Deadline: ${proposalDeadline}`)
        const voteWay = 1
        const reason = "I vote yes"

        //返回“account”选择的委托。    
        console.log("delegates",await deployedToken.delegates(owner.address))
        //console.log("deployedGovernor",deployedGovernor)

        let voteTx = await deployedGovernor.castVoteWithReason(proposalId, voteWay, reason)
        let voteTxReceipt = await voteTx.wait(1)
        console.log(voteTxReceipt.events[0].args.reason)
        proposalState = await deployedGovernor.state(proposalId)
        console.log(`Current Proposal State: ${proposalState}`)
        /**
         * Moving blocks to simulate completion of voting period
         */
        await moveBlocks(VOTING_PERIOD + 1)


        const descriptionHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(proposalDescription))

        console.log("Queueing...")

        //获取赞同的票数
        const votes = await deployedGovernor.getVotes(owner.address,12)
        console.log("votes",votes)
        console.log(`Checkpoints: ${await deployedToken.numCheckpoints(owner.address)}`)
     
        const quorum=await deployedGovernor.quorum(12)
        console.log("quorum",quorum)
        proposalState = await deployedGovernor.state(proposalId)
        console.log(`Current Proposal State: ${proposalState}`)
        const queueTx = await deployedGovernor.queue([deployedBox.address],[0],[encodedFunctionCall],descriptionHash)
        await queueTx.wait(1)

        await moveTime(MIN_DELAY + 1)
        await moveBlocks(1)


        console.log("Executing...");
    
        const executeTx = await deployedGovernor.execute(
                [deployedBox.address],
                [0],
                [encodedFunctionCall],
                descriptionHash
        );
        await executeTx.wait(1)
        const value=await deployedBox.retrieve();
        console.log(value);

    });

  
    it("Create another user, issue token, both users voting to match 90% quorum and execution", async () => {
        [owner, addr1, addr2] = await ethers.getSigners();
    
        MyToken = await ethers.getContractFactory("MyToken");
        deployedToken=await MyToken.deploy();
        await deployedToken.deployed();

        transactionResponse = await deployedToken.delegate(owner.address);
        await transactionResponse.wait(1);

        timeLock = await ethers.getContractFactory("TimeLock");

        deployedTimeLock=await timeLock.deploy(MIN_DELAY,[],[], owner.address);

        await deployedTimeLock.deployed();
    
        governor = await ethers.getContractFactory("GovernorContract");

        deployedGovernor=await governor.deploy(deployedToken.address,deployedTimeLock.address,QUORUM_PERCENTAGE,VOTING_PERIOD,VOTING_DELAY);
        await deployedGovernor.deployed();
        
        //实例的工厂
        box = await ethers.getContractFactory("Box");
        deployedBox=await box.deploy();
        await deployedBox.deployed();

        /** This is done so as to transfer the ownership to timelock contract so that it can execute the operation */
        //将部署的Target合约(Box)的所有权转移到TimeLock合约。这样做是为了TimeLock将有权对Box合约执行操作。
        const transferTx = await deployedBox.transferOwnership(deployedTimeLock.address);
        await transferTx.wait(1);
        /**
        * Granting roles to the relevant parties
        */
        const proposerRole = await deployedTimeLock.PROPOSER_ROLE();
        const executorRole = await deployedTimeLock.EXECUTOR_ROLE();
        const adminRole = await deployedTimeLock.TIMELOCK_ADMIN_ROLE();

        //Governor合约被授予提案者角色
        const proposerTx = await deployedTimeLock.grantRole(proposerRole, deployedGovernor.address);
        await proposerTx.wait(1);
        
        //执行角色被授予“零地址”，这意味着任何人都可以执行提案。
        const executorTx = await deployedTimeLock.grantRole(executorRole, ADDRESS_ZERO);
        await executorTx.wait(1);

        //将owner从admin角色移除
        const revokeTx = await deployedTimeLock.revokeRole(adminRole, owner.address);
        await revokeTx.wait(1);
      
        //创建提案。我们传递将在 Box 合约上调用的函数的编码值及其参数。
        const proposalDescription="propose this data";
        //我们的提案是在值为 77 的 Box 合约上触发store功能
        let encodedFunctionCall = box.interface.encodeFunctionData("store", [77]);

        //owner作为代表
        transactionResponse = await deployedToken.delegate(owner.address);
        await transactionResponse.wait(1);

        /**
         * Adding second user
         */
        const signer=await ethers.getSigner(addr1.address);
        const deployedTokenUser2=await deployedToken.connect(signer);

        //给第二个user发行200个代币
        await deployedTokenUser2.issueToken(addr1.address,200);
        transactionResponse = await deployedTokenUser2.delegate(addr1.address);
        await transactionResponse.wait(1);

        const proposeTx = await deployedGovernor.propose(
                [deployedBox.address], //合约地址数组
                [0],                    //eth数值
                [encodedFunctionCall],  //合约函数的哈希
                proposalDescription     //议题描述
        );

        await moveBlocks(VOTING_DELAY + 1);
        const proposeReceipt = await proposeTx.wait(1);
        proposalId = proposeReceipt.events[0].args.proposalId;
        console.log(`Proposed with proposal ID:\n  ${proposalId}`);

        let proposalState = await deployedGovernor.state(proposalId);
        const proposalSnapShot = await deployedGovernor.proposalSnapshot(proposalId);
        const proposalDeadline = await deployedGovernor.proposalDeadline(proposalId);

                // The state of the proposal. 1 is not passed. 0 is passed.
        console.log(`Current Proposal State: ${proposalState}`);
        // What block # the proposal was snapshot
        console.log(`Current Proposal Snapshot: ${proposalSnapShot}`);
        // The block number the proposal voting expires
        console.log(`Current Proposal Deadline: ${proposalDeadline}`);
        const voteWay = 1;
        const reason = "I vote yes";
            
       
 
        let voteTx = await deployedGovernor.castVoteWithReason(proposalId, voteWay, reason);
        let voteTxReceipt = await voteTx.wait(1);
        console.log(voteTxReceipt.events[0].args.reason);
        proposalState = await deployedGovernor.state(proposalId);
        console.log(`Current Proposal State: ${proposalState}`);
        /**
        * Second user voting
        */
        const deployedGovernorUser2=await deployedGovernor.connect(signer);
        voteTx = await deployedGovernorUser2.castVoteWithReason(proposalId, voteWay, reason);
        voteTxReceipt = await voteTx.wait(1);
        console.log(voteTxReceipt.events[0].args.reason);
        proposalState = await deployedGovernor.state(proposalId);
        console.log(`Current Proposal State: ${proposalState}`);
        /**
         * Moving blocks to simulate completion of voting period
         */
        await moveBlocks(VOTING_PERIOD + 1);

        const descriptionHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(proposalDescription));


        console.log("Queueing...");
        const votes=await deployedGovernor.getVotes(owner.address,37);
        console.log("votes",votes);
        console.log(`Checkpoints: ${await deployedToken.numCheckpoints(owner.address)}`);
     
        const quorum=await deployedGovernor.quorum(37);
        console.log("quorum",quorum);
        proposalState = await deployedGovernor.state(proposalId);
        console.log(`Current Proposal State: ${proposalState}`);
        const queueTx = await deployedGovernor.queue([deployedBox.address],[0],[encodedFunctionCall],descriptionHash);
        await queueTx.wait(1);

        await moveTime(MIN_DELAY + 1);
        await moveBlocks(1);


        console.log("Executing...");
    
        const executeTx = await deployedGovernor.execute(
                [deployedBox.address],
                [0],
                [encodedFunctionCall],
                descriptionHash
        );
        await executeTx.wait(1);
        const value=await deployedBox.retrieve();
        console.log(value);
   });



  
});