# NFT Derivative Protocol Main Subgraph Doc 

## 白名单

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


### 查询SBT Id 是否可以允许创建Hub的白名单记录
id - SBT id
```
{
  hubCreatorWhitelistedRecord(id: "2") {
    whitelisted
  }
}
```

## Query User

### 查询Profile记录
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

### 查询某用户钱包对应的 SBT Asset 记录
```
{
  sbtasset(id: "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc") {
    balance
  }
}
```

### 用户信息组合查询
 包括： 
  -- 用户创建的hub
  -- 用户profile(呢称及头像)
  -- 用户SBT资产余额
  -- 用户钱包名下的所有dNFT(tokenId)
```
{
  accounts {
    id,
    hub {
      id
    }
    profile {
      id,
      nickName
      imageURI
    }
    sbtAsset {
      id
      balance
    }
    dnfts{
      id
      tokenId
    }
  }
}
```

## 查询Hub,Project,预发布，已发布及dNFT相关

### 查询Hub详细信息
id - hubId
```
{
  hub(id: "1"){
    name
    description
    imageURI
    timestamp
  }
}

```

### 查询Projdct id的详细信息 
id - projectId
```
{
  project(id: "1"){
    derivativeNFT {
      contract
      name
      symbol
      baseURI
    }
    projectCreator {
      id
    }
    hub {
      id
    }
  }
}

```
### 查询已发行的Publish id对应的记录
id = publishId
```
{
  publish(id: "1"){
    publisher {
      id
    }
    publication {
      name
      salePrice
      royaltyBasisPoints
      canCollect
      materialURIs
      fromTokenIds
    }
    newTokenId
    amount
    collectModuleInitData
  }
}

```


### 查询预发布id对应的记录
id = publicationId
```
{
  publication(id: "1") {
    hub {
      id
    }
    project {
      id
    }
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

### 查询用户的前100条dDNT数据
```
id - 用户的钱包地址
{
  account(id: "0x90f79bf6eb2c4f870365e785982e1f101e93b906"){
    dnfts (first: 100){
      id
      tokenId
    }
  }
}
```

## Collect及Airdrop查询

### 查询collect历史记录, 以及支付创世及上一个二创的版税
```
{
  feesForCollectHistories(first: 100) {
    owner {
      id
    }
    collector {
      id
    }
    genesisCreator {
      id
    }
    previousCreator {
      id
    }
    publish {
      id
    }
    tokenId
    collectUnits
    treasuryAmount
    genesisAmount
    previousAmount
    adjustedAmount
  }
}
```

### 查询airdrop历史记录
```
{
  dnftAirdropedHistories(first: 100) {
    publish {
      newTokenId
    }
    derivativeNFT {
      id
    }
    from {
      id
    }
    tokenId
    toAccounts
    values
    newTokenIds
  }
}
```
