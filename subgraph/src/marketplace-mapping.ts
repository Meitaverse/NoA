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
    NftMarketAuction,
    NftMarketBid,
    NftMarketBuyNow,
    NftMarketContract,
    NftMarketOffer,
    DerivativeNFTContract,
} from "../generated/schema"

import {
  MarketPlace
} from "../generated/MarketPlace/MarketPlace"


import { loadProject } from "./shared/project";
import { loadOrCreateAccount } from "./shared/accounts";
import { loadLatestBuyNow } from "./shared/buyNow";
import { BASIS_POINTS, ONE_BIG_INT, ZERO_ADDRESS_STRING, ZERO_BIG_DECIMAL, ZERO_BIG_INT } from "./shared/constants";
import { toETH } from "./shared/conversions";
import { recordDnftEvent, removePreviousTransferEvent } from "./shared/events";
import { getLogId } from "./shared/ids";
import { loadLatestOffer, outbidOrExpirePreviousOffer } from "./shared/offers";
import { recordSale } from "./shared/revenue";
import { loadOrCreateDNFT, loadOrCreateDNFTContract } from "./dnft";

export function loadOrCreateNFTMarketContract(address: Address): NftMarketContract {
    let nftMarketContract = NftMarketContract.load(address.toHex());
    if (!nftMarketContract) {
      nftMarketContract = new NftMarketContract(address.toHex());
      nftMarketContract.numberOfBidsPlaced = ZERO_BIG_INT;
      nftMarketContract.save();
    }
    return nftMarketContract as NftMarketContract;
  }

export function handleAddMarket(event: AddMarket): void {
    log.info("handleAddMarket, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.derivativeNFT.toHexString()
    const market = Market.load(_idString) || new Market(_idString)

    if (market) {
        market.derivativeNFT = loadOrCreateDNFTContract(event.params.derivativeNFT).id;
        market.feePayType = event.params.feePayType
        market.feeShareType = event.params.feeShareType
        market.royaltyBasisPoints = event.params.royaltyBasisPoints
        market.timestamp = event.block.timestamp
        market.save()
    } 
}

export function handleMarketPlaceERC3525Received(event: MarketPlaceERC3525Received): void {
    log.info("handleMarketPlaceERC3525Received, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.operator.toHexString() + "-" +  event.block.timestamp.toString()
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
}

export function handleRemoveMarket(event: RemoveMarket): void {
    log.info("handleRemoveMarket, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.derivativeNFT.toHexString()
    store.remove("Market", _idString);
}

export function handleBuyPriceSet(event: BuyPriceSet): void {
    log.info("handleBuyPriceSet, event.address: {}", [event.address.toHexString()])
    let nft = loadOrCreateDNFT(event.params.buyPrice.derivativeNFT, event.params.buyPrice.tokenId, event);

    let project = loadProject(event.params.buyPrice.projectId);
    let seller = loadOrCreateAccount(event.params.buyPrice.seller);
    if (project && seller) {

      let buyNow = loadLatestBuyNow(nft);
      if (!buyNow) {
        buyNow = new NftMarketBuyNow(getLogId(event));
      }
      
      let amountInSBTValue = toETH(event.params.buyPrice.salePrice);
      buyNow.nftMarketContract = loadOrCreateNFTMarketContract(event.address).id;
      buyNow.dnft = nft.id;
      buyNow.derivativeNFT = nft.derivativeNFT;
      buyNow.status = "Open";
      buyNow.seller = seller.id;
      buyNow.project = project.id;
      buyNow.amountInSBTValue = amountInSBTValue;
      buyNow.onSellUnits = event.params.buyPrice.onSellUnits;
      buyNow.seledUnits = event.params.buyPrice.seledUnits;
      buyNow.dateCreated = event.block.timestamp;
      buyNow.transactionHashCreated = event.transaction.hash;
      buyNow.save();
      removePreviousTransferEvent(event);
      recordDnftEvent(
        event,
        nft,
        "BuyPriceSet",
        seller,
        null,
        "Foundation",
        amountInSBTValue,
        null,
        null,
        null,
        null,
        null,
        buyNow,
      );
      nft.mostRecentBuyNow = buyNow.id;
      nft.ownedOrListedBy = seller.id;
      nft.save();
    }

}


export function handleBuyPriceAccepted(event: BuyPriceAccepted): void {
    let nft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    let buyNow = loadLatestBuyNow(nft);
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
    buyNow.creatorRevenueInSBTValue = toETH(event.params.royaltyAmounts.genesisAmount);
    buyNow.previousCreatorRevenueInSBTValue = toETH(event.params.royaltyAmounts.previousAmount);
    buyNow.foundationRevenueInSBTValue = toETH(event.params.royaltyAmounts.treasuryAmount);
    buyNow.ownerRevenueInSBTValue = toETH(event.params.royaltyAmounts.adjustedAmount);
    if (!buyNow.buyReferrerSellerFee) {
      buyNow.buyReferrerSellerFee = toETH(ZERO_BIG_INT);
    }
    if (!buyNow.buyReferrerFee) {
      buyNow.buyReferrerFee = toETH(ZERO_BIG_INT);
    }
    buyNow.foundationProtocolFeeInSBTValue = toETH(event.params.royaltyAmounts.treasuryAmount).plus(buyNow.buyReferrerFee!); // eslint-disable-line @typescript-eslint/no-non-null-assertion
    buyNow.isPrimarySale = nft.isFirstSale && buyNow.seller == nft.creator;
    buyNow.save();
  
    removePreviousTransferEvent(event);
    recordDnftEvent(
      event,
      nft,
      "BuyPriceAccepted",
      seller,
      null,
      "Foundation",
      buyNow.amountInSBTValue,
      buyer,
      null,
      null,
      null,
      null,
      buyNow,
    );
    recordSale(
      nft, 
      seller, 
      buyNow.creatorRevenueInSBTValue, 
      buyNow.previousCreatorRevenueInSBTValue, 
      buyNow.ownerRevenueInSBTValue, 
      buyNow.foundationRevenueInSBTValue
    );
}
  

export function handleBuyPriceInvalidated(event: BuyPriceInvalidated): void {
    let nft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    let buyNow = loadLatestBuyNow(nft);
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
      nft,
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
      buyNow,
    );
}
  

export function handleBuyPriceCanceled(event: BuyPriceCanceled): void {
    let nft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    let buyNow = loadLatestBuyNow(nft);
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
      nft,
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
      buyNow,
    );
}

function loadAuction(marketAddress: Address, auctionId: BigInt): NftMarketAuction | null {
    return NftMarketAuction.load(marketAddress.toHex() + "-" + auctionId.toString());
}

export function handleReserveAuctionBidPlaced(event: ReserveAuctionBidPlaced): void {
    
  /*
    let auction = loadAuction(event.address, event.params.auctionId);
    if (!auction) {
      return;
    }
  
    // Save new high bid
    let currentBid = new NftMarketBid(auction.id + "-" + getLogId(event));
  
    let nft = DNFT.load(auction.dnft) as DNFT;
    let creator: Creator | null;
    if (nft.creator) {
      creator = Creator.load(nft.creator as string);
    } else {
      creator = null;
    }
    let owner = Account.load(auction.seller) as Account;
  
    // Update previous high bid
    let highestBid = auction.highestBid;
    if (highestBid) {
      let previousBid = NftMarketBid.load(highestBid) as NftMarketBid;
      previousBid.status = "Outbid";
      previousBid.dateLeftActiveStatus = event.block.timestamp;
      previousBid.transactionHashLeftActiveStatus = event.transaction.hash;
      previousBid.outbidByBid = currentBid.id;
      previousBid.save();

      currentBid.bidThisOutbid = previousBid.id;
  
      // Subtract the previous pending value
      if (creator) {
        creator.netRevenuePendingInSBTValue = creator.netRevenuePendingInSBTValue.minus(auction.creatorRevenueInSBTValue as BigDecimal);
        creator.netSalesPendingInSBTValue = creator.netSalesPendingInSBTValue.minus(
          (auction.creatorRevenueInSBTValue as BigDecimal)
            .plus(auction.ownerRevenueInSBTValue as BigDecimal)
            .plus(auction.previousCreatorRevenueInSBTValue as BigDecimal)
            .plus(auction.foundationRevenueInSBTValue as BigDecimal),
        );
      }
      owner.netRevenuePendingInSBTValue = owner.netRevenuePendingInSBTValue.plus(auction.ownerRevenueInSBTValue as BigDecimal);
      // creator and owner are saved below
    } else {
      auction.dateStarted = event.block.timestamp;
    }
  
    currentBid.nftMarketAuction = auction.id;
    currentBid.dnft = auction.dnft;
    let bidder = loadOrCreateAccount(event.params.bidder);
    currentBid.bidder = bidder.id;
    currentBid.datePlaced = event.block.timestamp;
    currentBid.transactionHashPlaced = event.transaction.hash;
    currentBid.amountInSBTValue = toETH(event.params.amount);
    currentBid.status = "Highest";
    currentBid.seller = auction.seller;

    auction.isPrimarySale = nft.isFirstSale && auction.seller == nft.creator;
  
    // Calculate the expected revenue for this bid
    let totalFees: BigInt;
    let creatorRev: BigInt;
    let previousCreatorRev: BigInt;
    let sellerRev: BigInt;
    
    let marketPlaceContract = MarketPlace.bind(event.address);
    let fees = marketPlaceContract.try_getFeesAndRecipients(
      BigInt.fromI32(2),
      BigInt.fromI32(1),
      Address.fromString(auction.derivativeNFT),
      event.params.soulBoundTokenIdBidder,
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
  
    auction.foundationRevenueInSBTValue = toETH(totalFees);
    if (auction.seller == nft.creator) {
      auction.creatorRevenueInSBTValue = toETH(creatorRev.plus(sellerRev));
      auction.previousCreatorRevenueInSBTValue = ZERO_BIG_DECIMAL;
      auction.ownerRevenueInSBTValue = ZERO_BIG_DECIMAL;
    } else {
      auction.creatorRevenueInSBTValue = toETH(creatorRev);
      auction.previousCreatorRevenueInSBTValue = toETH(previousCreatorRev);
      auction.ownerRevenueInSBTValue = toETH(sellerRev);
    }
  
    // Add in the new pending revenue
    let saleAmountInSBTValue = (auction.creatorRevenueInSBTValue as BigDecimal)
      .plus(auction.ownerRevenueInSBTValue as BigDecimal)
      .plus(auction.previousCreatorRevenueInSBTValue as BigDecimal)
      .plus(auction.foundationRevenueInSBTValue as BigDecimal);
    if (creator) {
      creator.netRevenuePendingInSBTValue = creator.netRevenuePendingInSBTValue.plus(auction.creatorRevenueInSBTValue as BigDecimal);
      creator.netSalesPendingInSBTValue = creator.netSalesPendingInSBTValue.plus(saleAmountInSBTValue);
      creator.save();
    }
    owner.netRevenuePendingInSBTValue = owner.netRevenuePendingInSBTValue.plus(auction.ownerRevenueInSBTValue as BigDecimal);
    owner.save();
    nft.netRevenuePendingInSBTValue = nft.netRevenuePendingInSBTValue.plus(auction.creatorRevenueInSBTValue as BigDecimal);
    nft.netSalesPendingInSBTValue = nft.netSalesPendingInSBTValue.plus(saleAmountInSBTValue);
    nft.save();
  
    if (!auction.highestBid) {
      auction.initialBid = currentBid.id;
      currentBid.extendedAuction = false;
    } else {
      currentBid.extendedAuction = auction.dateEnding != event.params.endTime;
    }
    auction.dateEnding = event.params.endTime;
    auction.numberOfBids = auction.numberOfBids.plus(ONE_BIG_INT);
    auction.bidVolumeInSBTValue = auction.bidVolumeInSBTValue.plus(currentBid.amountInSBTValue);
    currentBid.save();
    auction.highestBid = currentBid.id;
    auction.save();
  
    // Count bids
    let market = loadOrCreateNFTMarketContract(event.address);
    market.numberOfBidsPlaced = market.numberOfBidsPlaced.plus(ONE_BIG_INT);
    market.save();
  
    recordDnftEvent(event, nft as DNFT, "Bid", bidder, auction, "Foundation", currentBid.amountInSBTValue);

    */
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
    
    let nft = DNFT.load(auction.dnft) as DNFT;
    nft.mostRecentActiveAuction = nft.latestFinalizedAuction;
    nft.save();
  
    removePreviousTransferEvent(event);
    recordDnftEvent(
      event,
      DNFT.load(auction.dnft) as DNFT,
      "Unlisted",
      Account.load(auction.seller) as Account,
      auction,
      "Foundation",
    );
  }

  export function handleReserveAuctionCreated(event: ReserveAuctionCreated): void {
    let nft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    let marketContract = loadOrCreateNFTMarketContract(event.address);
    let auction = new NftMarketAuction(marketContract.id + "-" + event.params.auctionId.toString());
    auction.nftMarketContract = marketContract.id;
    auction.auctionId = event.params.auctionId;
    auction.dnft = nft.id;
    auction.derivativeNFT = event.params.derivativeNFT.toHex();
    auction.status = "Open";
    let seller = loadOrCreateAccount(event.params.seller);
    auction.seller = seller.id;
    auction.duration = event.params.duration;
    auction.dateCreated = event.block.timestamp;
    auction.transactionHashCreated = event.transaction.hash;
    auction.extensionDuration = event.params.extensionDuration;
    auction.reservePriceInSBTValue = toETH(event.params.reservePrice);
    auction.isPrimarySale = nft.isFirstSale && auction.seller == nft.creator;
    auction.numberOfBids = ZERO_BIG_INT;
    auction.bidVolumeInSBTValue = ZERO_BIG_DECIMAL;
    auction.save();
  
    nft.ownedOrListedBy = seller.id;
    nft.mostRecentAuction = auction.id;
    nft.mostRecentActiveAuction = auction.id;
    nft.save();
  
    removePreviousTransferEvent(event);
    recordDnftEvent(event, nft as DNFT, "Listed", seller, auction, "Foundation", auction.reservePriceInSBTValue);
  }
  
  export function handleReserveAuctionFinalized(event: ReserveAuctionFinalized): void {
    let auction = loadAuction(event.address, event.params.auctionId);
    if (!auction) {
      return;
    }
  
    auction.status = "Finalized";
    auction.dateFinalized = event.block.timestamp;
    auction.ownerRevenueInSBTValue = toETH(event.params.royaltyAmounts.adjustedAmount);
    auction.creatorRevenueInSBTValue = toETH(event.params.royaltyAmounts.genesisAmount);
    auction.previousCreatorRevenueInSBTValue = toETH(event.params.royaltyAmounts.previousAmount);
    auction.foundationRevenueInSBTValue = toETH(event.params.royaltyAmounts.treasuryAmount);
    let currentBid = NftMarketBid.load(auction.highestBid as string) as NftMarketBid;
    currentBid.status = "FinalizedWinner";
    currentBid.dateLeftActiveStatus = event.block.timestamp;
    currentBid.transactionHashLeftActiveStatus = event.transaction.hash;
    currentBid.save();
    let nft = DNFT.load(auction.dnft) as DNFT;
    nft.latestFinalizedAuction = auction.id;
    nft.lastSalePriceInSBTValue = currentBid.amountInSBTValue;
    nft.save();
  
    let creator: Creator | null;
    if (nft.creator) {
      creator = Creator.load(nft.creator as string);
    } else {
      creator = null;
    }
    let owner = Account.load(auction.seller) as Account;
  
    // Subtract from pending revenue
    let saleAmountInSBTValue = (auction.creatorRevenueInSBTValue as BigDecimal)
      .plus(auction.ownerRevenueInSBTValue as BigDecimal)
      .plus(auction.previousCreatorRevenueInSBTValue as BigDecimal)
      .plus(auction.foundationRevenueInSBTValue as BigDecimal);
    if (creator) {
      creator.netRevenuePendingInSBTValue = creator.netRevenuePendingInSBTValue.minus(auction.creatorRevenueInSBTValue as BigDecimal);
      creator.netSalesPendingInSBTValue = creator.netSalesPendingInSBTValue.minus(saleAmountInSBTValue);
    }
    if (!auction.buyReferrerSellerFee) {
      auction.buyReferrerSellerFee = toETH(ZERO_BIG_INT);
    }
    if (!auction.buyReferrerFee) {
      auction.buyReferrerFee = toETH(ZERO_BIG_INT);
    }
    auction.foundationProtocolFeeInSBTValue = toETH(event.params.royaltyAmounts.treasuryAmount).plus(auction.buyReferrerFee!); // eslint-disable-line @typescript-eslint/no-non-null-assertion
  
    owner.netRevenuePendingInSBTValue = owner.netRevenuePendingInSBTValue.minus(auction.ownerRevenueInSBTValue as BigDecimal);
    nft.netRevenuePendingInSBTValue = nft.netRevenuePendingInSBTValue.minus(auction.creatorRevenueInSBTValue as BigDecimal);
    nft.netSalesPendingInSBTValue = nft.netSalesPendingInSBTValue.minus(saleAmountInSBTValue);
    nft.save();
    auction.save();
  
    recordSale(
      nft, 
      owner, 
      auction.creatorRevenueInSBTValue, 
      auction.previousCreatorRevenueInSBTValue, 
      auction.ownerRevenueInSBTValue, 
      auction.foundationRevenueInSBTValue
    );

    // TODO: Ideally this row would be added when the auction ended instead of waiting for settlement
    recordDnftEvent(
      event,
      nft as DNFT,
      "Sold",
      Account.load(currentBid.bidder) as Account,
      auction,
      "Foundation",
      currentBid.amountInSBTValue,
      null,
      auction.dateEnding,
    );

    removePreviousTransferEvent(event);

    recordDnftEvent(
      event,
      nft as DNFT,
      "Settled",
      loadOrCreateAccount(event.transaction.from),
      auction,
      "Foundation",
      null,
      Account.load(currentBid.bidder) as Account,
    );
}
  
export function handleReserveAuctionUpdated(event: ReserveAuctionUpdated): void {
    let auction = loadAuction(event.address, event.params.auctionId);
    if (!auction) {
      return;
    }
  
    auction.reservePriceInSBTValue = toETH(event.params.reservePrice);
    auction.save();
  
    recordDnftEvent(
      event,
      DNFT.load(auction.dnft) as DNFT,
      "PriceChanged",
      Account.load(auction.seller) as Account,
      auction,
      "Foundation",
      auction.reservePriceInSBTValue,
    );
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
  
    let nft = DNFT.load(auction.dnft) as DNFT;
    nft.mostRecentActiveAuction = nft.latestFinalizedAuction;
    nft.save();
  
    recordDnftEvent(event, nft, "AuctionInvalidated", Account.load(auction.seller) as Account, auction, "Foundation");
}

export function handleOfferAccepted(event: OfferAccepted): void {
    let nft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    let offer = loadLatestOffer(nft);
    if (!offer) {
      return;
    }
    offer.status = "Accepted";
    let buyer = loadOrCreateAccount(event.params.buyer);
    let seller = loadOrCreateAccount(event.params.seller);
    offer.seller = seller.id;
    offer.dateAccepted = event.block.timestamp;
    offer.transactionHashAccepted = event.transaction.hash;
    offer.creatorRevenueInSBTValue = toETH(event.params.royaltyAmounts.genesisAmount);
    offer.previousCreatorRevenueInSBTValue = toETH(event.params.royaltyAmounts.previousAmount);
    offer.foundationRevenueInSBTValue = toETH(event.params.royaltyAmounts.treasuryAmount);
    offer.ownerRevenueInSBTValue = toETH(event.params.royaltyAmounts.adjustedAmount);
    if (!offer.buyReferrerSellerFee) {
      offer.buyReferrerSellerFee = toETH(ZERO_BIG_INT);
    }
    if (!offer.buyReferrerFee) {
      offer.buyReferrerFee = toETH(ZERO_BIG_INT);
    }
    offer.foundationProtocolFeeInSBTValue = toETH(event.params.royaltyAmounts.treasuryAmount).plus(offer.buyReferrerFee!); // eslint-disable-line @typescript-eslint/no-non-null-assertion
  
    offer.isPrimarySale = nft.isFirstSale && offer.seller == nft.creator;
    offer.save();
    removePreviousTransferEvent(event); // Only applicable if the NFT was escrowed
    recordDnftEvent(
      event,
      nft,
      "OfferAccepted",
      seller,
      null,
      "Foundation",
      offer.amountInSBTValue,
      buyer,
      null,
      null,
      null,
      offer,
    );
    recordSale(
      nft, 
      seller, 
      offer.creatorRevenueInSBTValue, 
      offer.previousCreatorRevenueInSBTValue, 
      offer.ownerRevenueInSBTValue, 
      offer.foundationRevenueInSBTValue
    );
}
  
export function handleOfferInvalidated(event: OfferInvalidated): void {
    let nft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    let offer = loadLatestOffer(nft);
    if (!offer) {
      return;
    }
    let buyer = Account.load(offer.buyer) as Account; // Buyer was set on offer made
    offer.status = "Invalidated";
    offer.dateInvalidated = event.block.timestamp;
    offer.transactionHashInvalidated = event.transaction.hash;
    offer.save();
    recordDnftEvent(event, nft, "OfferInvalidated", buyer, null, "Foundation", null, null, null, null, null, offer);
}

export function handleOfferMade(event: OfferMade): void {
    let nft = loadOrCreateDNFT(event.params.derivativeNFT, event.params.tokenId, event);
    let buyer = loadOrCreateAccount(event.params.buyer);
    let offer = new NftMarketOffer(getLogId(event));
    let isIncrease = outbidOrExpirePreviousOffer(event, nft, buyer, offer);
    let amountInSBTValue = toETH(event.params.amount);
    offer.nftMarketContract = loadOrCreateNFTMarketContract(event.address).id;
    offer.dnft = nft.id;
    offer.derivativeNFT = nft.derivativeNFT;
    offer.status = "Open";
    offer.buyer = buyer.id;
    offer.amountInSBTValue = amountInSBTValue;
    offer.dateCreated = event.block.timestamp;
    offer.transactionHashCreated = event.transaction.hash;
    offer.dateExpires = event.params.expiration;
    offer.save();
    recordDnftEvent(
      event,
      nft,
      isIncrease ? "OfferChanged" : "OfferMade",
      buyer,
      null,
      "Foundation",
      amountInSBTValue,
      null,
      null,
      null,
      null,
      offer,
    );
    nft.mostRecentOffer = offer.id;
    nft.save();
}
