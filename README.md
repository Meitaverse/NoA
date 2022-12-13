# NoA Protocol

Description: 
   Basically this protocol can hold some erc3525 tokens and split or merge to a new one.

    
### Setup

Run  `yarn install` in the root directory

## Unit Tests

Run `yarn test` to run the unit tests

## deploy
```
$ yarn deploy

Proxy contract deployed to: 0x0165878A594ca255338adfa4d48449f69242Eb8F

```

## The Graph

### Login AWS Server: 16.163.166.55
```
$ cd /home/ubuntu/developments/solidity/NoA.main

$ yarn graph-local-node-start
```

### 查看docker 日志
```
$ yarn node-logs  

$ yarn graph-node-logs

```

### 部署Graph Node
```
$  yarn graph-local-codegen && yarn graph-local-build

$ yarn create-local-subgraph-node && yarn deploy-local-subgraph-node

Deployed to http://16.163.166.55:8000/subgraphs/name/NoA/MySubgraph/graphql

Subgraph endpoints:
Queries (HTTP):     http://16.163.166.55:8000/subgraphs/name/NoA/MySubgraph
```

### 查询所有组织者
```
query{
  organizers(first:100){
    id,
    organizer
  }
}

```

### 查询所有event
```
{
  eventItems(first: 100) {
    id
    projectId
    name
    description
  }
}
```

### 查询所有NoA
```
query{
  tokens(first:100){
    id,
    projectId,
    tokenId,
    tokenURI,
    slotURI,
    owner,
    organizer {
      id
    },
    history {
      id
    },
    createdAtTimestamp
  }
}

```

## 获取合约大小
```
$ yarn add --dev hardhat-contract-sizer

or 

$ npm instal --save-dev hardhat-contract-sizer
```

