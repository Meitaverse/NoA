import { log, Address, BigInt, Bytes, store, TypedMap } from "@graphprotocol/graph-ts";

import {
    AddMarket,
    MarketPlaceERC3525Received,
    FixedPriceSet,
    RemoveMarket,
    PublishSale,
    RemoveSale,
    Traded,
} from "../generated/MarketPlace/Events"

import {
    Market,
    MarketPlaceERC3525ReceivedHistory,
    PublishSaleRecord,
    TradedHistory,
} from "../generated/schema"

export function handleAddMarket(event: AddMarket): void {
    log.info("handleAddMarket, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.derivativeNFT.toHexString()
    const market = Market.load(_idString) || new Market(_idString)

    if (market) {
        market.derivativeNFT = event.params.derivativeNFT
        market.feePayType = event.params.feePayType
        market.feeShareType = event.params.feeShareType
        market.royaltyBasisPoints = event.params.royaltyBasisPoints
        market.isRemove = false
        market.timestamp = event.block.timestamp
        market.save()
        
    } 
}

export function handleMarketPlaceERC3525Received(event: MarketPlaceERC3525Received): void {
    log.info("handleMarketPlaceERC3525Received, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.operator.toHexString() + "-" +  event.block.timestamp.toString()
    const history = MarketPlaceERC3525ReceivedHistory.load(_idString) || new MarketPlaceERC3525ReceivedHistory(_idString)

    if (history) {
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

export function handleFixedPriceSet(event: FixedPriceSet): void {
    log.info("handleFixedPriceSet, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.saleId.toString()
    const publishSaleRecord = PublishSaleRecord.load(_idString)

    if (publishSaleRecord) {
        publishSaleRecord.soulBoundTokenId = event.params.soulBoundTokenId
        publishSaleRecord.saleId = event.params.saleId
        publishSaleRecord.preSalePrice = event.params.preSalePrice
        publishSaleRecord.salePrice = event.params.newSalePrice
        publishSaleRecord.timestamp = event.params.timestamp
        publishSaleRecord.save()
    } 
}

export function handleRemoveMarket(event: RemoveMarket): void {
    log.info("handleRemoveMarket, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.derivativeNFT.toHexString()
    const market = Market.load(_idString)

    if (market) {
        market.derivativeNFT = event.params.derivativeNFT
        market.isRemove = true
        market.timestamp = event.block.timestamp
        market.save()
        // store.remove("Market", _idString);
    } 
}


export function handlePublishSale(event: PublishSale): void {
    log.info("handlePublishSale, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.saleId.toString()
    const publishSaleRecord = PublishSaleRecord.load(_idString) || new PublishSaleRecord(_idString)

    if (publishSaleRecord) {
        publishSaleRecord.soulBoundTokenId = event.params.saleParam.soulBoundTokenId
        publishSaleRecord.projectId = event.params.saleParam.projectId
        publishSaleRecord.tokenId = event.params.saleParam.tokenId
        publishSaleRecord.onSellUnits = event.params.saleParam.onSellUnits
        publishSaleRecord.startTime = event.params.saleParam.startTime
        publishSaleRecord.preSalePrice = BigInt.fromI32(0)
        publishSaleRecord.salePrice = event.params.saleParam.salePrice
        publishSaleRecord.priceType = event.params.saleParam.priceType
        publishSaleRecord.min = event.params.saleParam.min
        publishSaleRecord.max = event.params.saleParam.max
        publishSaleRecord.derivativeNFT = event.params.derivativeNFT
        publishSaleRecord.tokenIdOfMarket = event.params.tokenIdOfMarket
        publishSaleRecord.saleId = event.params.saleId
        publishSaleRecord.isRemove = false
        publishSaleRecord.timestamp = event.block.timestamp
        publishSaleRecord.save()
    } 
}


export function handleRemoveSale(event: RemoveSale): void {
    log.info("handleRemoveSale, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.saleId.toString()
    const publishSaleRecord = PublishSaleRecord.load(_idString) 

    if (publishSaleRecord) {
        publishSaleRecord.onSellUnits = event.params.onSellUnits
        publishSaleRecord.saledUnits = event.params.saledUnits
        publishSaleRecord.isRemove = true
        publishSaleRecord.timestamp = event.block.timestamp
        publishSaleRecord.save()
    }
}

export function handleTraded(event: Traded): void {
    log.info("handleTraded, event.address: {}", [event.address.toHexString()])

    let _idString = event.params.tradeId.toString() + "-" +  event.block.timestamp.toString()
    const history = TradedHistory.load(_idString) || new TradedHistory(_idString)

    if (history) {
        
        history.saleId = event.params.saleId
        history.buyer = event.params.buyer
        history.tradeId = event.params.tradeId
        history.tradeTime = event.params.tradeTime
        history.price = event.params.price
        history.newTokenIdBuyer = event.params.newTokenIdBuyer
        history.tradedUnits = event.params.tradedUnits
        history.treasuryAmount = event.params.royaltyAmounts.treasuryAmount
        history.genesisAmount = event.params.royaltyAmounts.genesisAmount
        history.previousAmount = event.params.royaltyAmounts.previousAmount
        history.adjustedAmount = event.params.royaltyAmounts.adjustedAmount
        history.save()
    }

    let _idStringOfSale = event.params.saleId.toString()
    const publishSaleRecord = PublishSaleRecord.load(_idStringOfSale) 
    if (publishSaleRecord) {
        publishSaleRecord.onSellUnits = publishSaleRecord.onSellUnits.plus(event.params.tradedUnits) 
        publishSaleRecord.saledUnits = publishSaleRecord.saledUnits.minus(event.params.tradedUnits)
        publishSaleRecord.timestamp = event.block.timestamp
        publishSaleRecord.save()
    } 
}
