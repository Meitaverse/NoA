# NoA Protocol

Description: 
   Basically this protocol can hold some nfts and split or merge to a new one.

Metadata:
   We use slot[0] to store common characteristics and status. slot[1] to store special characteristic, such as digital model files uri. slot[2] to store sourse tokenIds.
    
### Setup

Run `npm install` in the root directory

## Unit Tests

Run `npm test` to run the unit tests

## deploy
```
$ npx hardhat run scripts/deploy.js
NoAMetadataDescriptor deployed to: 0x68B1D87F95878fE05B998F19b66F4baba5De1aed

uToken deployed to: 0xc6e7DF5E7b4f2A278906862b61205850344D4e7d

ProxyAdmin deployed to: 0x59b670e9fA9D0A427751Af201D676719a970857b
Proxy contract deployed to: 0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44

```
## The Graph

### Login AWS Server: 16.163.166.55
```
$ cd /home/ubuntu/developments/solidity/anvil-graph-node

$ docker-compose up -d
```

### 查看docker 日志
```
$ docker-compose logs -f -t --tail="100" anvil   

$ docker-compose logs -f -t --tail="100" graph-node   

```

### 部署
```
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
    eventId
    eventName
    eventDescription
  }
}
```

### 查询所有NoA
```
query{
  tokens(first:100){
    id,
    eventId,
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