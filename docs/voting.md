# Voting and Delegation

## 1 Abstract

This document elaborates the logic behind the voting power distribution and delegation implemented in the TelediskoDAO contracts.
本文件阐述了TelediskoDAO合同中实施的投票权分配和授权背后的逻辑。

## 2 Motivation

One of the main components of the TelediskoDAO is the automatic voting and settlement of resolutions. The Article of Association of the DAO describes how the voting process for a resolution should be implemented. More in detail:
TelediskoDAO的主要组成部分之一是自动投票和解决决议。DAO的章程描述了如何实施决议的投票过程。更多详细信息：

* it specifies on how the voting power should be distributed among token holders
它规定了如何在代币持有者之间分配投票权

* it specifies how the delegation among contributors should work
它规定了贡献者之间的授权应该如何工作

It boils down to set of rules governing the voting and delegation process. Such rules need to be implemented via a Smart Contract in order to enable to automatic execution of this part of the DAO. 
它归结为一套关于投票和授权程序的规则。这些规则需要通过智能合约来实现，以便能够自动执行DAO的这一部分。

## 3 Specification - 规范
### 3.1 Rules  - 规则
### 3.1.1 AoA rules:
* Only Contributors can vote. 只有贡献者才能投票。
* A Contributor's voting power equals the amount of TT tokens it owns.
贡献者的投票权等于其拥有的TT代币数量。

* A Contributor A can delegate another Contributor B, thus transferring A's voting power to B.
贡献者A可以委托另一个贡献者B，从而将A的投票权转移给B。

* A Contributor A cannot delegate another Contributor B if B already delegated someone else.
如果B已经委派了其他人，则贡献者A不能委派其他贡献者B。

* A Contributor A cannot delegate another Contributor if A itself has already been delegated.
如果A本身已被委派，则参与者A不能委派其他参与者。

* When a Contributor receives new tokens from any source, its voting power increases by the transferred amount.
当贡献者从任何来源接收到新的代币时，其投票权将按转移的金额增加

* The total voting power at a given time in the DAO is the sum of the voting power of the individual Contributors.
DAO中给定时间的总投票权是各个贡献者的投票权之和。


### 3.1.2 Additional rules:
* A Contributor must first delegate itself to be able to delegate others
参与者必须首先委托自己才能委托他人

### 3.2 Voting
The voting power of an account changes after the following actions:
账户的投票权在以下行为后发生变化：
* Delegation - 委托模式
* Token transfer - token交易
* Removal of Contributor status - 移除贡献者状态

The following conditions always hold true:
以下条件始终成立：
* A token holder that is not a Contributor, has voting power 0
非贡献者的令牌持有者具有投票权0,光有token，但不是Contributor， 无投票权

* A token holder that is a Contributor who delegated someone else, has voting power 0
授权他人的参与者，拥有投票权0

* A token holder that is a Contributor who didn't delegate itself (not someone else), has voting power 0
未授权自己（而非其他人）的参与者的令牌持有者拥有投票权0

* A token holder that is a Contributor who delegated itself and has no delegators, has voting power equal to its TT balance
一个代币持有者是一个自己授权但没有授权人的贡献者，其投票权等于其TT余额

* A token holder that is a Contributor who delegated itself and has 1 or more delegators, has voting power equal to its TT balance + the sum of the balance of its delegators
一个代币持有者是一个委托自己并拥有一个或多个委托人的贡献者，其投票权等于其TT余额+其委托人余额之和

#### 3.2.2 Delegation use cases - 授权用例
Preconditions:  前提条件
* Both A and B are Contributors A和B都是贡献者
* A has a delegate C (who is also a Contributor) A有一个代表C（也是参与者）
* B has delegated itself B已授权给自己

Flow: 流程
1. A delegates B - A 代表 B
2. The balance of A is added as voting power to B. - A的投票权等于A+B
3. The balance of A is removed from the voting power of C. A的余额从C的投票权中删除。
---
Preconditions: 
* Both A and B are Contributors
* A has delegated itself
* B has delegated itself

Flow:
1. A delegates B, 
2. The balance of A is added as voting power to B.
3. The balance of A is removed from the voting power of A.
---
Preconditions:
* A is a Contributor
* A has no delegate

1. A delegates A
2. The balance of A is added as voting power to A
---
In all the following cases, delegation fails:
* A is delegating B, but A has currently no delegates
* A is delegating B, but B has currently no delegates
* A is delegating B, but B already has a delegate different from itself
* A is delegating B, but A already has a delegator different from itself
* A is delegating B, but B is not a contributor
* A is delegating B, but A is not a contributor

#### 3.2.2 Token transfer use cases
Preconditions: 
* Both A and B are self-delegated Contributors

Flow:
1. A transfers 10 tokens to B.
2. The voting power of B is increased by 10.
3. The voting power of A is decreased by 10.
---
Preconditions:
* A is a Contributor

Flow:
1. The DAO mints 10 tokens to A. 
2. The voting power of A increases by 10.
3. The total voting power increases by 10.
---
Preconditions:
* A is a Contributor who delegated X
* B is a Contributor who delegated Y

Flow:
1. A transfers 10 tokens to B, 
2. The voting power of Y is increased by 10.
3. The voting power of X is decreased by 10.
---
Preconditions:
* A is a self-delegated Contributor
* B is not a Contributor

Flow:
1. A transfers 10 tokens to B, 
2. The voting power of A is decreased by 10.
3. The total voting power is decreased by 10.
---
Preconditions:
* A is not a Contributor
* B is a self-delegated Contributor

Flow:
1. A transfers 10 tokens to B, 
2. The voting power of B is increased by 10.
3. The total voting power is increased by 10.
---
In the following cases, no voting power is changed
* A is not a Contributor and sends token to B who is not a Contributor
* A has no delegate and sends token to B who has no delegate
* The DAO mints token to A who is not a Contributor
* The DAO mints token to A who has no delegate

#### 3.2.3 Removal of Contributor status
Preconditions:
* A is Contributor
* A has voting power 10

Flow: 
1. The DAO removes the Contributor status from A
2. The voting power of A goes to 0
3. The total voting power is decreased by 10.


## 4 Rationale 原理

The logic has been modelled as described mainly to match the requirements of the AoA. 
逻辑已按照所述进行建模，主要是为了满足AoA的要求。

Additionally, the self-delegation step has been added to the rules.
此外，自我授权步骤已添加到规则中。

The rationale behind this decision is to keep the gas cost for transfer cheaper and to simplify the logic.
这一决定背后的基本原理是保持天然气成本更低，并简化逻辑。

Not having done this would have implied that for each token transfer, we needed to check whether the two parties involved where Contributors (calling an external contract) and then perform the due actions. By making the self-delegation mandatory, instead, we can assume that an account that has a delegate (even if it's a self-delegate) is also a Contributor, because it must have first called the `delegate` function whose access is granted only to Contributors.

This and the rest of the contract has been inspired by `ERC20Vote`, in order not to reinvent the wheel.

## 5 Implementation

Implementation can be found in `Voting.sol`, which contains the base logic, and in `VotingSnapshot.sol`, which add snapshotting capabilities to the original contract.

All scenarios are tested in `Voting.ts` and `VotingSnapshot.ts`.

## 6 Copyright

<!--All TIPs MUST be released to the public domain.-->

Copyright and related rights waived via
[CC0](https://creativecommons.org/publicdomain/zero/1.0/)