# NoA Protocol

Description: 
   Basically this protocol can hold some erc3525 tokens and split or merge to a new one.


### Setup

Run  `yarn install` in the root directory

## Unit Tests

Run `yarn test` to run the unit tests


## The Graph

### Login AWS Server: 16.163.166.55
Start docker-compose
```

$ yarn graph-local-node-start
```

### 查看docker 日志
```
$ yarn node-logs  

$ yarn graph-node-logs

```

## Accounts
```
$ yarn hardhat accounts --network local 
Accounts
========
Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (1000000 ETH)
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

Account #1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (1000000 ETH)
Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

Account #2: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC (1000000 ETH)
Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

Account #3: 0x90F79bf6EB2c4f870365E785982E1f101E93b906 (1000000 ETH)
Private Key: 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6

Account #4: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 (1000000 ETH)
Private Key: 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a

Account #5: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc (1000000 ETH)
Private Key:  0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba

Account #6: 0x976EA74026E726554dB657fA54763abd0C3a0aa9 (1000000 ETH)
Private Key: 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e

Account #7: 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955 (1000000 ETH)
Private Key: 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356

Account #8: 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f (1000000 ETH)
Private Key: 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97

Account #9: 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720 (1000000 ETH)
Private Key: 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6


```

## deploy
```
$ yarn hardhat full-deploy
  	
```


### 执行 Graph Node 相关命令
```
$  yarn graph-local-codegen && yarn graph-local-build

$ yarn create-local-subgraph-node && yarn deploy-local-subgraph-node

Deployed to http://localhost:8000/subgraphs/name/NoA/MySubgraph/graphql

Subgraph endpoints:
Queries (HTTP):     http://localhost:8000/subgraphs/name/NoA/MySubgraph
```


### 查询设置注册白名单历史
```
query {
  profileCreatorWhitelistedHistories(first: 100) {
    id
    profileCreator
    whitelisted
    timestamp
  }
}
```

### 查询所有Profile
```
query {
  profiles(first:100){
    id,
    soulBoundTokenId,
    creator,
    wallet,
    nickName,
    imageURI,
    timestamp
  }
}	
```

### 查询所有Hub
```
query{
  hubs(first:100){
    id,
    soulBoundTokenId,
    creator,
    hubId,
    name,
    description,
    imageURI,
    timestamp
  }
}

```

### 查询所有Projdct
```
query{
  projects(first:100){
    id,
    projectId,
    soulBoundTokenId,
    derivativeNFT,
    timestamp
  }
}

```
### 查询所有Publish历史
```
query{
  publishCreatedHistories(first:100){
    id,
    publishId,
    soulBoundTokenId,
    hubId,
    projectId,
    newTokenId,
    amount,
    collectModuleInitData,
    timestamp
  }
}

```


### 查询所有NDP value铸造历史
```
query {
  mintNDPValueHistories(first: 100) {
    id
    soulBoundTokenId
    value
    timestamp
  }
}
```


### 查询所有collect
```
query {
  feesForCollectHistories(first: 100) {
    id
    collectorSoulBoundTokenId
    publishId
    treasuryAmount
    genesisAmount
    adjustedAmount
    timestamp
  }
}
```

### 查询所有airdrop histories
```
query {
  derivativeNFTAirdropedHistories(first: 100) {
    id
    projectId
    derivativeNFT
    fromSoulBoundTokenId
    tokenId
    toSoulBoundTokenIds
    values
    newTokenIds
    timestamp
  }
}
```


## 获取合约大小
```
$ yarn add --dev hardhat-contract-sizer

or 

$ npm instal --save-dev hardhat-contract-sizer
```

