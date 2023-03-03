import { log, Address, BigInt, Bytes, store, TypedMap, BigDecimal } from "@graphprotocol/graph-ts";

import {
    AddMarket,
    MarketPlaceERC3525Received,
    RemoveMarket,
    BuyPriceSet,
    BuyPriceAccepted,
    BuyPriceCanceled,
    BuyPriceInvalidated,
    OfferAccepted,
    OfferInvalidated,
    OfferMade,
    ReserveAuctionBidPlaced,
    ReserveAuctionCanceled,
    ReserveAuctionCreated,
    ReserveAuctionFinalized,
    ReserveAuctionInvalidated,
    ReserveAuctionUpdated,
} from "../generated/MarketPlace/Events"

import {
  DerivativeNFT,
} from "../generated/MarketPlace/DerivativeNFT"

import {
    Market,
    MarketPlaceERC3525ReceivedHistory,
    Account,
    Creator,
    DNFT,
    DnftMarketAuction,
    DnftMarketBid,
    DnftMarketBuyNow,
    DnftMarketContract,
    DnftMarketOffer,
    DerivativeNFTContract,
} from "../generated/schema"

import {
  MarketPlace
} from "../generated/MarketPlace/MarketPlace"

import {
  FeeCollectModule
} from "../generated/MarketPlace/FeeCollectModule"


import { loadProject } from "./shared/project";
import { loadOrCreateAccount } from "./shared/accounts";
import { loadLatestBuyNow } from "./shared/buyNow";
import { BASIS_POINTS, ONE_BIG_INT, ZERO_ADDRESS_STRING, ZERO_BIG_INT } from "./shared/constants";
import { toETH } from "./shared/conversions";
import { recordDnftEvent, removePreviousTransferEvent } from "./shared/events";
import { getLogId } from "./shared/ids";
import { loadLatestOffer, outbidOrExpirePreviousOffer } from "./shared/offers";
import { recordSale } from "./shared/revenue";
import { loadOrCreateDNFT, loadOrCreateDNFTContract, saveTransactionHashHistory } from "./dnft";

export function loadOrCreateDNFTMarketContract(address: Address): DnftMarketContract {
    let dnftMarketContract = DnftMarketContract.load(address.toHex());
    if (!dnftMarketContract) {
      dnftMarketContract = new DnftMarketContract(address.toHex());
      dnftMarketContract.numberOfBidsPlaced = ZERO_BIG_INT;
      dnftMarketContract.save();
    }
    return dnftMarketContract as DnftMarketContract;
  }

export function handleAddMarket(event: AddMarket): void {
    log.info("handleAddMarket, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.derivativeNFT.toHexString()
    const market = Market.load(_idString) || new Market(_idString)

    if (market) {
        market.derivativeNFT = loadOrCreateDNFTContract(event.params.derivativeNFT).id;
        market.project = loadProject(event.params.projectId).id
        market.feePayType = event.params.feePayType
        market.feeShareType = event.params.feeShareType
        market.royaltyBasisPoints = event.params.royaltyBasisPoints
        market.collectModule = event.params.collectModule
        market.timestamp = event.block.timestamp
        market.save()
    } 

    saveTransactionHashHistory("AddMarket", event);
}

export function handleMarketPlaceERC3525Received(event: MarketPlaceERC3525Received): void {
    log.info("handleMarketPlaceERC3525Received, event.address: {}", [event.address.toHexString()])

    let _idString =  getLogId(event)
    const history = MarketPlaceERC3525ReceivedHistory.load(_idString) || new MarketPlaceERC3525ReceivedHistory(_idString)

    if (history) {
        history.sender = event.params.sender
        history.operator = event.params.operator
        history.fromTokenId = event.params.fromTokenId
        history.toTokenId = event.params.toTokenId
        history.value = event.params.value
        history.data = event.params.data
        history.gas = event.params.gas
        history.timestamp = event.block.timestamp
        history.save()
    } 

    saveTransactionHashHistory("MarketPlaceERC3525Received", event);
}

export function handleRemoveMarket(event: RemoveMarket): void {
    log.info("handleRemoveMarket, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.derivativeNFT.toHexString()
    store.remove("Market", _idString);

    saveTransactionHashHistory("RemoveMarket", event);
}

export function handleBuyPriceSet(event: BuyPriceSet): void {
    log.info("handleBuyPriceSet, event.address: {}, derivativeNFT:{}, tokenId:{}", [
      event.address.toHexString(),
      event.params.derivativeNFT.toHex(),
      event.params.tokenId.toString()
    ])
    
    let market = MarketPlace.bind(event.address);
    let resultBuyPrice = market.try_getBuyPrice(event.params.derivativeNFT,  event.params.tokenId);
    if (resultBuyPrice.reverted) {
      log.info("resultBuyPrice.reverted", []);
      return;
    }

    let dnft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);

    let project = loadProject(resultBuyPrice.value.projectId);
    let seller = loadOrCreateAccount(resultBuyPrice.value.seller);
    if (project && seller && dnft) {

      let buyNow = loadLatestBuyNow(dnft);
      if (!buyNow) {
        buyNow = new DnftMarketBuyNow(getLogId(event));
      }
      
      buyNow.dnftMarketContract = loadOrCreateDNFTMarketContract(event.address).id;
      buyNow.dnft = dnft.id;
      buyNow.derivativeNFT = dnft.derivativeNFT;
      buyNow.status = "Open";
      buyNow.seller = seller.id;
      buyNow.project = project.id;
      buyNow.currency = resultBuyPrice.value.currency;
      buyNow.salePrice = resultBuyPrice.value.salePrice;
      buyNow.tokenId = event.params.tokenId;
      buyNow.units = resultBuyPrice.value.units;
      buyNow.dateCreated = event.block.timestamp;
      buyNow.transactionHashCreated = event.transaction.hash;
      buyNow.save();

      removePreviousTransferEvent(event);
      recordDnftEvent(
        event,
        dnft,
        "BuyPriceSet",
        seller,
        null,
        "Foundation",
        buyNow.currency,
        resultBuyPrice.value.salePrice.times(resultBuyPrice.value.units),
        null,
        null,
        null,
        null,
        null,
        buyNow,
      );
      dnft.mostRecentBuyNow = buyNow.id;
      dnft.ownedOrListedBy = seller.id;
      dnft.save();
    }
    saveTransactionHashHistory("BuyPriceSet", event);
}


export function handleBuyPriceAccepted(event: BuyPriceAccepted): void {
    let dnft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    if (dnft) {

      let buyNow = loadLatestBuyNow(dnft);
      if (!buyNow) {
        return;
      }
      buyNow.status = "Accepted";
      let buyer = loadOrCreateAccount(event.params.buyer);
      let seller = loadOrCreateAccount(event.params.seller);
      buyNow.buyer = buyer.id;
      buyNow.seller = seller.id;
      buyNow.dateAccepted = event.block.timestamp;
      buyNow.transactionHashAccepted = event.transaction.hash;
      buyNow.creatorRevenue = event.params.royaltyAmounts.genesisAmount;
      buyNow.previousCreatorRevenue = event.params.royaltyAmounts.previousAmount;
      buyNow.foundationRevenue = event.params.royaltyAmounts.treasuryAmount;
      buyNow.ownerRevenue = event.params.royaltyAmounts.adjustedAmount;
      if (!buyNow.buyReferrerSellerFee) {
        buyNow.buyReferrerSellerFee = ZERO_BIG_INT;
      }
      if (!buyNow.buyReferrerFee) {
        buyNow.buyReferrerFee = ZERO_BIG_INT;
      }
      buyNow.currency = event.params.currency;

      // buyNow.foundationProtocolFee = event.params.royaltyAmounts.treasuryAmount).plus(buyNow.buyReferrerFee!; // eslint-disable-line @typescript-eslint/no-non-null-assertion
      buyNow.isPrimarySale = dnft.isFirstSale && buyNow.seller == dnft.creator;
      buyNow.save();
    
      removePreviousTransferEvent(event);
      recordDnftEvent(
        event,
        dnft,
        "BuyPriceAccepted",
        seller,
        null,
        "Foundation",
        buyNow.currency,
        buyNow.salePrice.times(buyNow.units),
        buyer,
        null,
        null,
        null,
        null,
        buyNow,
      );
      recordSale(
        dnft, 
        seller, 
        buyNow.creatorRevenue, 
        buyNow.previousCreatorRevenue, 
        buyNow.ownerRevenue, 
        buyNow.foundationRevenue
      );
    }

    saveTransactionHashHistory("BuyPriceAccepted", event);
}
  

export function handleBuyPriceInvalidated(event: BuyPriceInvalidated): void {
    let dnft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    if (dnft) {

      let buyNow = loadLatestBuyNow(dnft);
      if (!buyNow) {
        return;
      }
      let seller = Account.load(buyNow.seller) as Account;
      buyNow.status = "Invalidated";
      buyNow.dateInvalidated = event.block.timestamp;
      buyNow.transactionHashInvalidated = event.transaction.hash;
      buyNow.save();
      recordDnftEvent(
        event,
        dnft,
        "BuyPriceInvalidated",
        seller,
        null,
        "Foundation",
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        buyNow,
      );
    }

    saveTransactionHashHistory("BuyPriceInvalidated", event);
}
  

export function handleBuyPriceCanceled(event: BuyPriceCanceled): void {
    let dnft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    if (dnft) {

      let buyNow = loadLatestBuyNow(dnft);
      if (!buyNow) {
        return;
      }
      let seller = Account.load(buyNow.seller) as Account;
      buyNow.status = "Canceled";
      buyNow.dateCanceled = event.block.timestamp;
      buyNow.transactionHashCanceled = event.transaction.hash;
      buyNow.save();
      removePreviousTransferEvent(event);
      recordDnftEvent(
        event,
        dnft,
        "BuyPriceCanceled",
        seller,
        null,
        "Foundation",
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        buyNow,
      );
    }

    saveTransactionHashHistory("BuyPriceCanceled", event);
}

function loadAuction(marketAddress: Address, auctionId: BigInt): DnftMarketAuction | null {
    return DnftMarketAuction.load(marketAddress.toHex() + "-" + auctionId.toString());
}

export function handleReserveAuctionBidPlaced(event: ReserveAuctionBidPlaced): void {
  
  let auction = loadAuction(event.address, event.params.auctionId);
  if (!auction) {
    return;
  }
  
  let marketDict = Market.load(auction.derivativeNFT);
  if (!marketDict) return;

  let collectModule = Address.fromBytes(marketDict.collectModule);

  let feeCollectModule = FeeCollectModule.bind(collectModule);
  
    // Save new high bid
    let currentBid = new DnftMarketBid(auction.id + "-" + getLogId(event));
  
    let dnft = DNFT.load(auction.dnft) as DNFT;
    let creator: Creator | null;
    if (dnft.creator) {
      creator = Creator.load(dnft.creator as string);
    } else {
      creator = null;
    }
    let owner = Account.load(auction.seller) as Account;
  
    // Update previous high bid
    let highestBid = auction.highestBid;
    if (highestBid) {
      let previousBid = DnftMarketBid.load(highestBid) as DnftMarketBid;
      previousBid.status = "Outbid";
      previousBid.dateLeftActiveStatus = event.block.timestamp;
      previousBid.transactionHashLeftActiveStatus = event.transaction.hash;
      previousBid.outbidByBid = currentBid.id;
      previousBid.save();

      currentBid.bidThisOutbid = previousBid.id;
  
      // Subtract the previous pending value
      if (creator) {
        creator.netRevenuePending = creator.netRevenuePending.minus(auction.creatorRevenue as BigInt);
        creator.netSalesPending = creator.netSalesPending.minus(
          (auction.creatorRevenue as BigInt)
            .plus(auction.ownerRevenue as BigInt)
            .plus(auction.previousCreatorRevenue as BigInt)
            .plus(auction.foundationRevenue as BigInt),
        );
      }
      owner.netRevenuePending = owner.netRevenuePending.plus(auction.ownerRevenue as BigInt);
      // creator and owner are saved below
    } else {
      auction.dateStarted = event.block.timestamp;
    }
  
    currentBid.dnftMarketAuction = auction.id;
    currentBid.dnft = auction.dnft;
    let bidder = loadOrCreateAccount(event.params.bidder);
    currentBid.bidder = bidder.id;
    currentBid.datePlaced = event.block.timestamp;
    currentBid.transactionHashPlaced = event.transaction.hash;
    currentBid.amount = event.params.amount;
    currentBid.status = "Highest";
    currentBid.seller = auction.seller;

    auction.isPrimarySale = dnft.isFirstSale && auction.seller == dnft.creator;
  
    // Calculate the expected revenue for this bid
    let totalFees: BigInt;
    let creatorRev: BigInt;
    let previousCreatorRev: BigInt;
    let sellerRev: BigInt;
    
    let publishId = BigInt.fromString(dnft.publish);
    let fees = feeCollectModule.try_getFees(
      publishId,
      event.params.amount
    );

    if (!fees.reverted) {
      totalFees = fees.value.value0;
      creatorRev = fees.value.value1;
      previousCreatorRev = fees.value.value2;
      sellerRev = fees.value.value3;
    } else {
      totalFees = ZERO_BIG_INT;
      creatorRev = ZERO_BIG_INT;
      previousCreatorRev = ZERO_BIG_INT;
      sellerRev = ZERO_BIG_INT;
    }
  
    auction.foundationRevenue = totalFees;
    if (auction.seller == dnft.creator) {
      auction.creatorRevenue = creatorRev.plus(sellerRev);
      auction.previousCreatorRevenue = ZERO_BIG_INT;
      auction.ownerRevenue = ZERO_BIG_INT;
    } else {
      auction.creatorRevenue = creatorRev;
      auction.previousCreatorRevenue = previousCreatorRev;
      auction.ownerRevenue = sellerRev;
    }
  
    // Add in the new pending revenue
    let saleAmount = (auction.creatorRevenue as BigInt)
      .plus(auction.ownerRevenue as BigInt)
      .plus(auction.previousCreatorRevenue as BigInt)
      .plus(auction.foundationRevenue as BigInt);
    if (creator) {
      creator.netRevenuePending = creator.netRevenuePending.plus(auction.creatorRevenue as BigInt);
      creator.netSalesPending = creator.netSalesPending.plus(saleAmount);
      creator.save();
    }
    owner.netRevenuePending = owner.netRevenuePending.plus(auction.ownerRevenue as BigInt);
    owner.save();
    dnft.netRevenuePending = dnft.netRevenuePending.plus(auction.creatorRevenue as BigInt);
    dnft.netSalesPending = dnft.netSalesPending.plus(saleAmount);
    dnft.save();
  
    if (!auction.highestBid) {
      auction.initialBid = currentBid.id;
      currentBid.extendedAuction = false;
    } else {
      currentBid.extendedAuction = auction.dateEnding !== event.params.endTime;
    }
    auction.dateEnding = event.params.endTime;
    auction.numberOfBids = auction.numberOfBids.plus(ONE_BIG_INT);
    auction.bidVolume = auction.bidVolume.plus(currentBid.amount);
    currentBid.save();
    auction.highestBid = currentBid.id;
    auction.save();
  
    // Count bids
    let market = loadOrCreateDNFTMarketContract(event.address);
    market.numberOfBidsPlaced = market.numberOfBidsPlaced.plus(ONE_BIG_INT);
    market.save();
  
    recordDnftEvent(
      event, 
      dnft as DNFT, 
      "Bid", 
      bidder, 
      auction, 
      "Foundation", 
      null,
      currentBid.amount
    );

    saveTransactionHashHistory("DnftMarketAuction", event);

  }
  
  export function handleReserveAuctionCanceled(event: ReserveAuctionCanceled): void {
    let auction = loadAuction(event.address, event.params.auctionId);
    if (!auction) {
      return;
    }
  
    auction.status = "Canceled";
    auction.dateCanceled = event.block.timestamp;
    auction.transactionHashCanceled = event.transaction.hash;
    auction.save();
    
    let dnft = DNFT.load(auction.dnft) as DNFT;
    dnft.mostRecentActiveAuction = dnft.latestFinalizedAuction;
    dnft.save();
  
    removePreviousTransferEvent(event);
    recordDnftEvent(
      event,
      DNFT.load(auction.dnft) as DNFT,
      "Unlisted",
      Account.load(auction.seller) as Account,
      auction,
      "Foundation",
    );

    saveTransactionHashHistory("ReserveAuctionCanceled", event);
  }

  export function handleReserveAuctionCreated(event: ReserveAuctionCreated): void {
    const market = MarketPlace.bind(event.address);
    let resultReserveAuction = market.try_getReserveAuction(event.params.auctionId);
    if (resultReserveAuction.reverted) {
      log.info("resultReserveAuction.reverted", []);
      return;
    }

    let project = loadProject(resultReserveAuction.value.projectId);
    if (!project) return;

    let dnft = loadOrCreateDNFT(resultReserveAuction.value.derivativeNFT, resultReserveAuction.value.tokenId, event);
    if (dnft) {

      let marketContract = loadOrCreateDNFTMarketContract(event.address);
      let auction = new DnftMarketAuction(marketContract.id + "-" + event.params.auctionId.toString());
      auction.dnftMarketContract = marketContract.id;
      auction.auctionId = event.params.auctionId;
      auction.dnft = dnft.id;
      auction.derivativeNFT = resultReserveAuction.value.derivativeNFT.toHex();
      auction.project = project.id;
      auction.status = "Open";
      let seller = loadOrCreateAccount(resultReserveAuction.value.seller);
      auction.seller = seller.id;
      auction.duration = resultReserveAuction.value.duration;
      auction.dateCreated = event.block.timestamp;
      auction.transactionHashCreated = event.transaction.hash;
      auction.extensionDuration = resultReserveAuction.value.extensionDuration;
      auction.currency = resultReserveAuction.value.currency
      auction.reservePrice = resultReserveAuction.value.amount;
      auction.isPrimarySale = dnft.isFirstSale && auction.seller == dnft.creator;
      auction.numberOfBids = ZERO_BIG_INT;
      auction.bidVolume = ZERO_BIG_INT;
      auction.save();
    
      dnft.ownedOrListedBy = seller.id;
      dnft.mostRecentAuction = auction.id;
      dnft.mostRecentActiveAuction = auction.id;
      dnft.save();
    
      removePreviousTransferEvent(event);
      recordDnftEvent(
        event, 
        dnft as DNFT, 
        "Listed", 
        seller, 
        auction, 
        "Foundation", 
        auction.currency, 
        auction.reservePrice
      );
    }

    saveTransactionHashHistory("ReserveAuctionCreated", event);
  }
  
  export function handleReserveAuctionFinalized(event: ReserveAuctionFinalized): void {
    let auction = loadAuction(event.address, event.params.auctionId);
    if (!auction) {
      return;
    }
  
    auction.status = "Finalized";
    auction.dateFinalized = event.block.timestamp;
    auction.ownerRevenue = event.params.royaltyAmounts.adjustedAmount;
    auction.creatorRevenue = event.params.royaltyAmounts.genesisAmount;
    auction.previousCreatorRevenue = event.params.royaltyAmounts.previousAmount;
    auction.foundationRevenue = event.params.royaltyAmounts.treasuryAmount;
    let currentBid = DnftMarketBid.load(auction.highestBid as string) as DnftMarketBid;
    currentBid.status = "FinalizedWinner";
    currentBid.dateLeftActiveStatus = event.block.timestamp;
    currentBid.transactionHashLeftActiveStatus = event.transaction.hash;
    currentBid.save();
    let dnft = DNFT.load(auction.dnft) as DNFT;
    dnft.latestFinalizedAuction = auction.id;
    dnft.lastSalePrice = currentBid.amount;
    dnft.save();
  
    let creator: Creator | null;
    if (dnft.creator) {
      creator = Creator.load(dnft.creator as string);
    } else {
      creator = null;
    }
    let owner = Account.load(auction.seller) as Account;
  
    // Subtract from pending revenue
    let saleAmount = (auction.creatorRevenue as BigInt)
      .plus(auction.ownerRevenue as BigInt)
      .plus(auction.previousCreatorRevenue as BigInt)
      .plus(auction.foundationRevenue as BigInt);
    if (creator) {
      creator.netRevenuePending = creator.netRevenuePending.minus(auction.creatorRevenue as BigInt);
      creator.netSalesPending = creator.netSalesPending.minus(saleAmount);
    }
    if (!auction.buyReferrerSellerFee) {
      auction.buyReferrerSellerFee = ZERO_BIG_INT;
    }
    if (!auction.buyReferrerFee) {
      auction.buyReferrerFee = ZERO_BIG_INT;
    }
    // auction.foundationProtocolFee = event.params.royaltyAmounts.treasuryAmount).plus(auction.buyReferrerFee!); // eslint-disable-line @typescript-eslint/no-non-null-assertion
  
    owner.netRevenuePending = owner.netRevenuePending.minus(auction.ownerRevenue as BigInt);
    dnft.netRevenuePending = dnft.netRevenuePending.minus(auction.creatorRevenue as BigInt);
    dnft.netSalesPending = dnft.netSalesPending.minus(saleAmount);
    dnft.save();
    auction.save();
  
    recordSale(
      dnft, 
      owner, 
      auction.creatorRevenue, 
      auction.previousCreatorRevenue, 
      auction.ownerRevenue, 
      auction.foundationRevenue
    );

    // TODO: Ideally this row would be added when the auction ended instead of waiting for settlement
    recordDnftEvent(
      event,
      dnft as DNFT,
      "Sold",
      Account.load(currentBid.bidder) as Account,
      auction,
      "Foundation",
      auction.currency,
      currentBid.amount,
      null,
      auction.dateEnding,
    );

    removePreviousTransferEvent(event);

    recordDnftEvent(
      event,
      dnft as DNFT,
      "Settled",
      loadOrCreateAccount(event.transaction.from),
      auction,
      "Foundation",
      auction.currency, 
      null,
      Account.load(currentBid.bidder) as Account,
    );

    saveTransactionHashHistory("ReserveAuctionFinalized", event);
}

export function handleReserveAuctionUpdated(event: ReserveAuctionUpdated): void {
    let auction = loadAuction(event.address, event.params.auctionId);
    if (!auction) {
      return;
    }
  
    auction.reservePrice = event.params.reservePrice;
    auction.save();
  
    recordDnftEvent(
      event,
      DNFT.load(auction.dnft) as DNFT,
      "PriceChanged",
      Account.load(auction.seller) as Account,
      auction,
      "Foundation",
      auction.currency, 
      auction.reservePrice,
    );

    saveTransactionHashHistory("ReserveAuctionUpdated", event);
}
  
export function handleReserveAuctionInvalidated(event: ReserveAuctionInvalidated): void {
    let auction = loadAuction(event.address, event.params.auctionId);
    if (!auction) {
      return;
    }
  
    auction.status = "Invalidated";
    auction.dateInvalidated = event.block.timestamp;
    auction.transactionHashInvalidated = event.transaction.hash;
    auction.save();
  
    let dnft = DNFT.load(auction.dnft) as DNFT;
    dnft.mostRecentActiveAuction = dnft.latestFinalizedAuction;
    dnft.save();
  
    recordDnftEvent(
      event, 
      dnft, 
      "AuctionInvalidated", 
      Account.load(auction.seller) as Account, 
      auction, 
      "Foundation",
      auction.currency, 
    );

    saveTransactionHashHistory("ReserveAuctionInvalidated", event);
}

export function handleOfferAccepted(event: OfferAccepted): void {
    let dnft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    if (dnft) {

      let offer = loadLatestOffer(dnft);
      if (!offer) {
        return;
      }
      offer.status = "Accepted";
      let buyer = loadOrCreateAccount(event.params.buyer);
      let seller = loadOrCreateAccount(event.params.seller);
      offer.seller = seller.id;
      offer.dateAccepted = event.block.timestamp;
      offer.transactionHashAccepted = event.transaction.hash;
      offer.creatorRevenue = event.params.royaltyAmounts.genesisAmount;
      offer.previousCreatorRevenue = event.params.royaltyAmounts.previousAmount;
      offer.foundationRevenue = event.params.royaltyAmounts.treasuryAmount;
      offer.ownerRevenue = event.params.royaltyAmounts.adjustedAmount;
      if (!offer.buyReferrerSellerFee) {
        offer.buyReferrerSellerFee = ZERO_BIG_INT;
      }
      if (!offer.buyReferrerFee) {
        offer.buyReferrerFee = ZERO_BIG_INT;
      }
      offer.foundationProtocolFee = event.params.royaltyAmounts.treasuryAmount.plus(offer.buyReferrerFee!); // eslint-disable-line @typescript-eslint/no-non-null-assertion
    
      offer.isPrimarySale = dnft.isFirstSale && offer.seller == dnft.creator;
      offer.save();
      removePreviousTransferEvent(event); // Only applicable if the dNFT was escrowed
      
      recordDnftEvent(
        event,
        dnft,
        "OfferAccepted",
        seller,
        null,
        "Foundation",
        offer.currency,
        offer.amount,
        buyer,
        null,
        null,
        null,
        offer,
      );
  
      recordSale(
        dnft, 
        seller, 
        offer.creatorRevenue, 
        offer.previousCreatorRevenue, 
        offer.ownerRevenue, 
        offer.foundationRevenue
      );
    }

    saveTransactionHashHistory("OfferAccepted", event);
}
  
export function handleOfferInvalidated(event: OfferInvalidated): void {
    let dnft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    if (dnft) {

      let offer = loadLatestOffer(dnft);
      if (!offer) {
        return;
      }
      let buyer = Account.load(offer.buyer) as Account; // Buyer was set on offer made
      offer.status = "Invalidated";
      offer.dateInvalidated = event.block.timestamp;
      offer.transactionHashInvalidated = event.transaction.hash;
      offer.save();
      recordDnftEvent(
        event, 
        dnft, 
        "OfferInvalidated", 
        buyer, 
        null, 
        "Foundation", 
        offer.currency, 
        null, 
        null, 
        null, 
        null, 
        null, 
        offer
      );
    }

    saveTransactionHashHistory("OfferInvalidated", event);
}

export function handleOfferMade(event: OfferMade): void {
    let dnft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    if (dnft) {

      let buyer = loadOrCreateAccount(event.params.buyer);
      let offer = new DnftMarketOffer(getLogId(event));
      let isIncrease = outbidOrExpirePreviousOffer(event, dnft, buyer, offer);
      let amount = event.params.amount;
      offer.dnftMarketContract = loadOrCreateDNFTMarketContract(event.address).id;
      offer.dnft = dnft.id;
      offer.derivativeNFT = dnft.derivativeNFT;
      offer.status = "Open";
      offer.buyer = buyer.id;
      offer.currency = event.params.currency;
      offer.amount = amount;
      offer.dateCreated = event.block.timestamp;
      offer.transactionHashCreated = event.transaction.hash;
      offer.dateExpires = event.params.expiration;
      offer.save();
      recordDnftEvent(
        event,
        dnft,
        isIncrease ? "OfferChanged" : "OfferMade",
        buyer,
        null,
        "Foundation",
        offer.currency,
        amount,
        null,
        null,
        null,
        null,
        offer,
      );
      dnft.mostRecentOffer = offer.id;
      dnft.save();
    }

    saveTransactionHashHistory("OfferMade", event);
}
