# NFT Derivative Protocol Main Subgraph

## Module全局设置相关

### 查询预发布PublishModule白名单
    在module白名单内的才能用于预发布
```
{
  publishModuleWhitelistedRecords(first: 100) {
    id
    publishModule
    whitelisted
    timestamp
  }
}
```

### 查询CollectModule白名单
    在module白名单内的才能用于collect,默认是二级分润模型
```
{
  collectModuleWhitelistedRecords(first: 100) {
    id
    collectModule
    whitelisted
    timestamp
  }
}
```

### 查询模版Template白名单
    在模版白名单内的Template才能用于publish
```
{
  templateWhitelistedRecords(first: 100) {
    id
    template
    whitelisted
    timestamp
  }
}
```


## 社区金库版税及预发布固定收费设置


### 查询社区金库收取的税点
    每当用户collect的时候，社区金库均会收取固定的税点
    
```
 {
  treasuryFeeRecords(first: 100) {
    id
    prevTreasuryFee
    newTreasuryFee
    timestamp
  }
}
```

### 查询预发布固定收费价格
    
```
{
  publishRoyaltyRecords(first: 100) {
    id
    prevPublishRoyalty
    newPublishRoyalty
    timestamp
  }
}
```


## 个人注册及创建Hub白名单

### 查询设置注册白名单记录
    用户钱包地址在注册白名单里才能进行createProfile
```
 {
  profileCreatorWhitelistedRecords(first: 100) {
    id
    profileCreator
    whitelisted
    caller
    timestamp
  }
}
```

### 查询所有Profile
```
{
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

### 查询所有SBT Asset 记录
```
 {
  sbtassets(first: 100) {
    id
    wallet
    soulBoundTokenId
    value
    timestamp
  }
}
```


### 查询允许创建Hub的白名单记录

```
{
  hubCreatorWhitelistedRecords (first: 100) {
    id
    soulBoundTokenId
    whitelisted
    timestamp
    
  }
}
```

### 查询所有Hub
```
{
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
{
  projects(first:100){
    id,
    projectId,
    soulBoundTokenId,
    derivativeNFT,
    timestamp
  }
}

```
### 查询所有Publish记录
```
{
  publishRecords(first:100){
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


### 查询所有SBT value铸造历史
```
{
  mintSBTValueHistories(first: 100) {
    id
    soulBoundTokenId
    value
    timestamp
  }
}
```

### 查询预发布的记录
```
{
  publications(first: 100) {
    id
    soulBoundTokenId
    hubId
    projectId
    salePrice
    royaltyBasisPoints
    amount
    name
    description
    materialURIs
    fromTokenIds
    collectModule
    collectModuleInitData
    publishModule
    publishModuleInitData
    publishId
    previousPublishId
    publishTaxAmount
    timestamp
  }
}
```

### 查询所有collect历史记录, 以及支付创世及上一个二创的版税
```
{
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

### 查询所有airdrop历史记录
```
{
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


### 查询所有SBT Asset，用户资产
```
{ 
  sbtassets(first: 100) {
    id
    wallet
    soulBoundTokenId
    value
    timestamp
  }
}
```

## 系统设置相关查询 

### Treasury Set - 全局金库地址设置历史
```
 {
  moduleGlobalsTreasurySetHistories(first: 100) {
    id
    prevTreasury
    newTreasury
    timestamp
  }
}
```

### Voucher Set - 全局Voucher地址设置历史
```
{
  moduleGlobalsVoucherSetHistories(first: 100) {
    id
    prevVoucher
    newVoucher
    timestamp
  }
}

```

### Manager Set - 全局Manager地址设置历史
```
{
  moduleGlobalsManagerSetHistories(first: 100) {
    id
    prevManager
    newManager
    timestamp
  }
}

```

### SBT Set - 全局SBT地址设置历史
```
{
  moduleGlobalsSBTSetHistories(first: 100) {
    id
    prevSBT
    newSBT
    timestamp
  }
}

```

### SBT Set - 全局Governance地址设置历史
```
{
  moduleGlobalsGovernanceSetHistories(first: 100) {
    id
    prevGovernance
    newGovernance
    timestamp
  }
}

```
