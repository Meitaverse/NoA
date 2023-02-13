# GraphQL for market palce
## Retrieve a list of BuyNows:
```
{
 dnftMarketBuyNows(first: 100) {
    id,
    dnft {
      id,
      tokenId,
      dateMinted,
    },
    derivativeNFT {
      id,
      name,
      symbol
    },
    status,
    seller {
      id
    },
    currency,
    salePrice,
  }
}
```

## Retrieve historical BuyNow Events:
```
{
  dnftHistories(
    where: {buyNow_not: null},
    first: 100,
    orderBy: date,
    orderDirection: asc) {
      id,
      contractAddress,
      dnft {
        id,
        tokenId,
        dateMinted,
      },
      buyNow {
        id,
        status,
        dateCreated,
        dateCanceled,
        dateAccepted,
        dateInvalidated,
        seller{
          id
        },
        buyer {
          id
        },
        buyReferrer {
          id
        },
        buyReferrerFee
      },
    }
}
```