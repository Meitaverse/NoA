# NoA Protocol

Description: 
   Basically this protocol can hold some nfts and split or merge to a new one.

Metadata:
   We use slot[0] to store common characteristics and status. slot[1] to store special characteristic, such as digital model files uri. slot[2] to store sourse tokenIds.
    
### Setup

Run `npm install` in the root directory

## Unit Tests

Run `npm test` to run the unit tests


## The Graph

Login AWS Server: 16.163.166.55
```
$ cd /home/ubuntu/developments/solidity/anvil-graph-node

$ docker-compose up -d
```

查看docker 日志
```
$ docker-compose logs -f 
```