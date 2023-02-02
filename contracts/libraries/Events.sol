// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from "./DataTypes.sol";

library Events {

    /**
     * @dev Emitted when a profile is created.
     *
     * @param soulBoundTokenId The newly created profile's token ID.
     * @param creator The profile creator, who created the token with the given profile ID.
     * @param wallet The address receiving the profile with the given profile ID.
     * @param nickName The nickName set for the profile.
     * @param imageURI The image uri set for the profile.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreated(
        uint256 indexed soulBoundTokenId,
        address indexed creator,
        address indexed wallet,
        string nickName,
        string imageURI,
        uint256 timestamp
    );

    /**
     * @dev Emitted when prepare a publish
     *
     * @param publication The Publication data
     * @param publishId The publish Id, 
     * @param previousPublishId The previous publish Id
     * @param publishTaxAmount The publish tax amount
     */
    event PublishPrepared(
        DataTypes.Publication publication,
        uint256 publishId,
        uint256 previousPublishId,
        uint256 publishTaxAmount
    );

    /**
     * @dev Emitted when update a publish while not publish on chain
     *
     * @param hubId The hub Id
     * @param publishId The publish Id
     * @param soulBoundTokenId The soulBoundToken Id
     * @param salePrice The sale price while collet 
     * @param royaltyBasisPoints The royalty basis points
     * @param amount The amount of publish
     * @param name The name of publish
     * @param description The description of publish
     * @param materialURIs Array of materialURI 
     * @param fromTokenIds Array of fromTokenId 
     * @param addedPublishTaxes The added publish taxes while taxed increased
     * @param timestamp The current block timestamp.
     */
    event PublishUpdated(
        uint256 hubId,
        uint256 projectId,
        uint256 publishId,
        uint256 soulBoundTokenId,
        uint256 salePrice,
        uint256 royaltyBasisPoints,
        uint256 amount,
        string name,
        string description,
        string[] materialURIs,
        uint256[] fromTokenIds,
        uint256 addedPublishTaxes,
        uint256 timestamp
    );

    // Signals frozen metadata to OpenSea; emitted in minting functions
    event PermanentURI(string _value, uint256 indexed _id);    
    
    /**
     * @dev Emitted when a publish is created.
     *
     * @param publishId The newly created project's ID.
     * @param soulBoundTokenId The newly created profile's token ID.
     * @param hubId The hub ID.
     * @param projectId The project ID.
     * @param amount The amount of the token.
     * @param collectModuleInitData The data include some variables.
     */
    event PublishCreated(
        uint256 indexed publishId,
        uint256 indexed soulBoundTokenId,
        uint256 hubId,
        uint256 projectId,
        uint256 amount,
        bytes collectModuleInitData
    );

    /**
     * @dev Emitted when a publish is minted .
     *
     * @param publishId The newly created project's ID.
    //  * @param newTokenId The new token id .
     */
    event PublishMinted(
        uint256 indexed publishId,
        uint256 indexed newTokenId
    );

    /**
     * @dev Emitted when a hub is created.
     *
     * @param soulBoundTokenId The newly created profile's token ID.
     * @param hubOwner The profile creator, who created the token with the given profile ID.
     * @param hubId The hub ID.
     * @param name The name set for the hub.
     * @param description The description set for the hub.
     * @param imageURI The image uri set for the profile.
     * @param timestamp The current block timestamp.
     */
    event HubCreated(
        uint256 indexed soulBoundTokenId,
        address indexed hubOwner,
        uint256 indexed hubId,
        string name,
        string description,
        string imageURI,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a hub is updated.
     *
     * @param hubId The hub id.
     * @param hubOwner The hub creator.
     * @param name The name set for the hub.
     * @param description The description set for the hub.
     * @param imageURI The image uri set for the profile.
     * @param timestamp The current block timestamp.
     */
    event HubUpdated(
        uint256 indexed hubId,
        address indexed hubOwner,
        string name,
        string description,
        string imageURI,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a dispatcher is set for a specific soulBoundToken.
     *
     * @param soulBoundTokenId The token ID of the soulBoundToken for which the dispatcher is set.
     * @param dispatcher The dispatcher set for the given profile.
     * @param timestamp The current block timestamp.
     */
    event DispatcherSet(
        uint256 indexed soulBoundTokenId, 
        address indexed dispatcher, 
        uint256 timestamp
    );

    /**
     * @dev Emitted when the hub state is set.
     *
     * @param caller The caller who set the state.
     * @param prevState The previous protocol state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param newState The newly set state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param timestamp The current block timestamp.
     */
    event StateSet(
        address indexed caller,
        DataTypes.ProtocolState indexed prevState,
        DataTypes.ProtocolState indexed newState,
        uint256 timestamp
    );

    event DerivativeNFTStateSet(
        address indexed caller,
        DataTypes.DerivativeNFTState indexed prevState,
        DataTypes.DerivativeNFTState indexed newState,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the bank treasury receive ERC3525 tokens
     *
     * @param sender The msg.sender.
     * @param operator The operator who called by.
     * @param fromTokenId The from token id
     * @param toTokenId The to token id
     * @param value The value of token
     * @param data The data extend
     * @param gas The gas left
     */    
    event ERC3525Received(
        address indexed sender, 
        address indexed operator, 
        uint256 indexed fromTokenId, 
        uint256 toTokenId, 
        uint256 value, 
        bytes data, 
        uint256 gas
    );

    //Receiver

    /**
     * @dev Emitted when the Receiver contract receive ERC3525 tokens
     *
     * @param operator The operator who called by.
     * @param fromTokenId The from token id
     * @param toTokenId The to token id
     * @param value The value of token
     * @param data The data extend
     * @param gas The gas left
     */      
    event ReceiverReceived(
        address indexed operator, 
        uint256 indexed fromTokenId, 
        uint256 indexed toTokenId, 
        uint256 value, 
        bytes data, 
        uint256 gas
    );

    // Module-Specific

    /**
     * @notice Emitted when the ModuleGlobals treasury address is set.
     *
     * @param prevTreasury The previous treasury address.
     * @param newTreasury The new treasury address set.
     * @param timestamp The current block timestamp.
     */
    event ModuleGlobalsTreasurySet(
        address indexed prevTreasury,
        address indexed newTreasury,
        uint256 timestamp
    );
    
    /**
     * @notice Emitted when the ModuleGlobals voucher address is set.
     *
     * @param prevVoucher The previous voucher address.
     * @param newVoucher The new voucher address set.
     * @param timestamp The current block timestamp.
     */    
    event ModuleGlobalsVoucherSet(
        address indexed prevVoucher,
        address indexed newVoucher,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the ModuleGlobals manager address is set.
     *
     * @param prevManager The previous manager address.
     * @param newManager The new manager address set.
     * @param timestamp The current block timestamp.
     */ 
    event ModuleGlobalsManagerSet(
        address indexed prevManager,
        address indexed newManager,
        uint256 timestamp
    );
    
    /**
     * @notice Emitted when the ModuleGlobals SBT address is set.
     *
     * @param prevSBT The previous SBT address.
     * @param newSBT The new SBT address set.
     * @param timestamp The current block timestamp.
     */     
    event ModuleGlobalsSBTSet(
        address indexed prevSBT,
        address indexed newSBT,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the ModuleGlobals publish royalty points is set.
     *  When prepare publish , SBT value will transfer from publisher to bank treasury
     *
     * @param prevPublishRoyalty The previous publish royalty points in BPS.
     * @param newPublishRoyalty The new publish royalty points in BPS.
     * @param timestamp The current block timestamp.
     */
    event ModuleGlobalsPublishRoyaltySet(
        uint256 indexed prevPublishRoyalty,
        uint256 indexed newPublishRoyalty,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the ModuleGlobals treasury fee is set.
     *
     * @param prevTreasuryFee The previous treasury fee in BPS.
     * @param newTreasuryFee The new treasury fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event ModuleGlobalsTreasuryFeeSet(
        uint16 indexed prevTreasuryFee,
        uint16 indexed newTreasuryFee,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a module inheriting from the `FeeModuleBase` is constructed.
     *
     * @param moduleGlobals The ModuleGlobals contract address used.
     * @param timestamp The current block timestamp.
     */
    event FeeModuleBaseConstructed(address indexed moduleGlobals, uint256 timestamp);

    /**
     * @notice Emitted when a module inheriting from the `ModuleBase` is constructed.
     *
     * @param manager The Manager contract address used.
     * @param market The MarketPlace contract address used.
     * @param timestamp The current block timestamp.
     */
    event ModuleBaseConstructed(
        address indexed manager, 
        address indexed market, 
        uint256 timestamp
        );

    /**
     * @notice Emitted when the ModuleGlobals governance address is set.
     *
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event ModuleGlobalsGovernanceSet(
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the governance address is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the governance address.
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event ManagerGovernanceSet(
        address indexed caller,
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );
    
    /**
     * @dev Emitted when a profile creator is added to or removed from the whitelist.
     *
     * @param profileCreator The address of the profile creator.
     * @param whitelisted Whether or not the profile creator is being added to the whitelist.
     * @param caller The address of caller.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreatorWhitelisted(
        address indexed profileCreator,
        bool indexed whitelisted,
        address indexed caller,
        uint256 timestamp
    );
    
    /**
     * @dev Emitted when a hub creator is added to or removed from the whitelist.
     *
     * @param soulBoundTokenId The SBT Id of the hub creator.
     * @param whitelisted Whether or not the profile creator is being added to the whitelist.
     * @param caller The addreKss of caller.
     * @param timestamp The current block timestamp.
     */
    event HubCreatorWhitelisted(
        uint256 indexed soulBoundTokenId,
        bool indexed whitelisted,
        address indexed caller,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the emergency admin is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the emergency admin address.
     * @param oldEmergencyAdmin The previous emergency admin address.
     * @param newEmergencyAdmin The new emergency admin address set.
     * @param timestamp The current block timestamp.
     */
    event EmergencyAdminSet(
        address indexed caller,
        address indexed oldEmergencyAdmin,
        address indexed newEmergencyAdmin,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a DerivativeNFT clone is deployed using a lazy deployment pattern.
     * @param creator The project creator.
     * @param projectId The project ID.
     * @param soulBoundTokenId The user's SoulBound token ID.
     * @param derivativeNFT The address of the newly deployed DerivativeNFT clone.
     * @param timestamp The current block timestamp.
     */
    event DerivativeNFTDeployed(
        address creator,
        uint256 indexed hubId,
        uint256 indexed projectId,
        uint256 indexed soulBoundTokenId,
        address derivativeNFT,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a SBT Id is burned. The balance of this SBT Id will tranfer to bank treasury before burned.
     * only manager can call
     * @param caller The caller who burn SBT Id.
     * @param soulBoundTokenId The SBT ID.
     * @param balance The balance of SBT Id.
     * @param timestamp The current block timestamp.
     */
    event BurnSBT(
        address indexed caller,
        uint256 indexed soulBoundTokenId, 
        uint256 indexed balance, 
        uint256 timestamp
    );

    /**
     * @dev Emitted when Manager call to mintValue of SBT Tokens.
     * 
     * @param caller The caller who mint SBT value.
     * @param soulBoundTokenId The token id of SBT
     * @param value The value of mint SBT
     * @param timestamp The current block timestamp.
     */
    event MintSBTValue(
        address indexed caller,
        uint256 indexed soulBoundTokenId,
        uint256 indexed value,
        uint256 timestamp
    );

    /**
     * @dev Emitted when derivativeNFT is collected and a new tokenId is generated.
     * 
     * @param projectId The project id of derivativeNFT.
     * @param derivativeNFT The derivativeNFT contract address
     * @param fromSoulBoundTokenId The from SoulBoundTokenId, owner of derivativeNFT
     * @param toSoulBoundTokenId The to SoulBoundTokenId, collector
     * @param tokenId The token id of the derivativeNFT
     * @param value The collect value 
     * @param newTokenId The new tokenId  of collect
     * @param royaltyAmounts The royalty amounts data
     */
    event DerivativeNFTCollected(
        uint256 projectId,
        address derivativeNFT,
        uint256 indexed fromSoulBoundTokenId,
        uint256 indexed toSoulBoundTokenId,
        uint256 indexed tokenId,
        uint256 value,
        uint256 newTokenId,
        DataTypes.RoyaltyAmounts royaltyAmounts
    );

    /**
     * @dev Emitted when derivativeNFT is airdrop by owner
     * 
     * @param projectId The project id of derivativeNFT.
     * @param publishId The publish id of derivativeNFT.
     * @param derivativeNFT The derivativeNFT contract address
     * @param fromSoulBoundTokenId The from SoulBoundTokenId, owner of derivativeNFT
     * @param tokenId The token id of the derivativeNFT
     * @param toSoulBoundTokenIds Array of to SoulBoundTokenIds
     * @param values Array of to values
     * @param newTokenIds Array of new tokenIds
     * @param timestamp The current block timestamp.
     */
    event DerivativeNFTAirdroped(
        uint256 projectId,
        uint256 publishId,
        address derivativeNFT,
        uint256 fromSoulBoundTokenId,
        uint256 tokenId,
        uint256[] toSoulBoundTokenIds,
        uint256[] values,
        uint256[] newTokenIds,
        uint256 timestamp
    );

// Market

    /**
     * @dev Emitted when the market place receive ERC3525 tokens
     *
     * @param sender The msg.sender
     * @param operator The operator who called by.
     * @param fromTokenId The from token id
     * @param toTokenId The to token id
     * @param value The value of token
     * @param data The data extend
     * @param gas The gas left
     */    
    event MarketPlaceERC3525Received(
        address indexed sender,
        address indexed operator, 
        uint256 indexed fromTokenId, 
        uint256 toTokenId, 
        uint256 value, 
        bytes data, 
        uint256 gas
    );

    
/**
     * @dev Emitted when ether send to  market place contract
     *
     * 
     * @param sender The sender 
     * @param amount The amount
     * @param sender The receiver 
     * @param balance balance of contract
     */
    event MarketPlaceDeposit(
        address indexed sender, 
        uint256 amount, 
        address indexed receiver, 
        uint256 balance
    );
    
    /**
     * @dev Emitted when ether send to market place contract
     *
     * 
     * @param sender The sender 
     * @param amount The amount
     * @param sender The receiver 
     * @param balance balance of contract
     * @param data msg.data 
     */
    event MarketPlaceDepositByFallback(
        address indexed sender, 
        uint256 amount, 
        address indexed receiver, 
        uint256 balance,
        bytes data
    );
    
    /**
     * @dev Emitted when a derivativeNFT contract is add to market
     * only governor called
     *
     * @param derivativeNFT The derivativeNFT address
     * @param projectId The project id
     * @param feePayType The fee who pay 
     * @param feeShareType The share type, default is level two
     * @param royaltyBasisPoints The royalty Basis Points 
     * @param collectModule The collectModule contract
     */
    event AddMarket(
        address derivativeNFT,
        uint256 projectId,
        DataTypes.FeePayType feePayType,
        DataTypes.FeeShareType feeShareType,
        uint16 royaltyBasisPoints,
        address collectModule
    );

    /**
     * @dev Emitted when a derivativeNFT contract removed from market
     * only governor called 
     *
     * @param derivativeNFT The derivativeNFT address
     */
    event RemoveMarket(address derivativeNFT);
    

    /**
     * @notice Emitted when an DNFT is bought by accepting the buy price,
     * indicating that the DNFT has been transferred and revenue from the sale distributed.
     * @dev The total buy price that was accepted is `totalFees` + `creatorRev` + `sellerRev`.
     * @param derivativeNFT The address of the DNFT contract.
     * @param tokenId The token id of seller.
     * @param newTokenIdBuyer The new token id of buyer .
     * @param seller The address of the seller which originally set the buy price.
     * @param buyer The address of the collector that purchased the DNFT using `buy`.
     * @param royaltyAmounts The Royalty Amounts data
     */
    event BuyPriceAccepted(
        address indexed derivativeNFT,
        uint256 indexed tokenId,
        uint256 indexed newTokenIdBuyer,
        address seller,
        address buyer,
        DataTypes.RoyaltyAmounts royaltyAmounts
    );
    
    /**
     * @notice Emitted when the buy price is removed by the owner of an DNFT.
     * @dev The DNFT is transferred back to the owner unless it's still escrowed for another market tool,
     * e.g. listed for sale in an auction.
     * @param derivativeNFT The address of the DNFT contract.
     * @param tokenId The id of the DNFT.
     */
    event BuyPriceCanceled(address indexed derivativeNFT, uint256 indexed tokenId);
    
    /**
     * @notice Emitted when a buy price is invalidated due to other market activity.
     * @dev This occurs when the buy price is no longer eligible to be accepted,
     * e.g. when a bid is placed in an auction for this DNFT.
     * @param derivativeNFT The address of the DNFT contract.
     * @param tokenId The id of the DNFT.
     */
    event BuyPriceInvalidated(address indexed derivativeNFT, uint256 indexed tokenId);

    /**
     * @notice Emitted when a buy price is set by the owner of an DNFT.
     * @dev The DNFT is transferred into the market contract for escrow unless it was already escrowed,
     * e.g. for auction listing.
     * @param buyPrice The BuyPrice data.
     */
    event BuyPriceSet(
        DataTypes.BuyPrice buyPrice
    );

    /**
     * @notice Emitted when an offer is accepted,
     * indicating that the DNFT has been transferred and revenue from the sale distributed.
     * @dev The accepted total offer amount is `totalFees` + `creatorRev` + `sellerRev`.
     * @param derivativeNFT The address of the DNFT contract.
     * @param tokenId The id of the DNFT.
     * @param buyer The address of the collector that made the offer which was accepted.
     * @param seller The address of the seller which accepted the offer.
     * @param royaltyAmounts The royalty amounts.
     */
    event OfferAccepted(
        address indexed derivativeNFT,
        uint256 indexed tokenId,
        address indexed buyer,
        address seller,
        DataTypes.RoyaltyAmounts royaltyAmounts
    );

    /**
     * @notice Emitted when an offer is invalidated due to other market activity.
     * When this occurs, the collector which made the offer has their SBT Value balance unlocked
     * and the funds are available to place other offers or to be withdrawn.
     * @dev This occurs when the offer is no longer eligible to be accepted,
     * e.g. when a bid is placed in an auction for this DNFT.
     * @param derivativeNFT The address of the DNFT contract.
     * @param tokenId The id of the DNFT.
     */
    event OfferInvalidated(address indexed derivativeNFT, uint256 indexed tokenId);
    
    /**
     * @notice Emitted when an offer is made.
     * @dev The `amount` of the offer is locked in the SBT contract, guaranteeing that the funds
     * remain available until the `expiration` date.
     * @param derivativeNFT The address of the DNFT contract.
     * @param tokenId The id of the DNFT.
     * @param buyer The address of the collector that made the offer to buy this DNFT.
     * @param amount The amount, in wei, of the offer.
     * @param expiration The expiration timestamp for the offer.
     */
    event OfferMade(
        address indexed derivativeNFT,
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 amount,
        uint256 expiration
    );

    /**
     * @notice Emitted when a bid is placed.
     * @param auctionId The id of the auction this bid was for.
     * @param originalSoulBoundTokenIdBidder The SBT id of the original bidder.
     * @param originalAmount Refund originalAmount to original bidder.
     * @param soulBoundTokenIdBidder The SBT id of the bidder.
     * @param bidder The bidder address.
     * @param amount The amount of the bid.
     * @param endTime The new end time of the auction (which may have been set or extended by this bid).
     */
    event ReserveAuctionBidPlaced(
        uint256 indexed auctionId, 
        uint256 indexed originalSoulBoundTokenIdBidder, 
        uint256 indexed originalAmount,
        uint256 soulBoundTokenIdBidder, 
        address bidder,
        uint256 amount,
        uint256 endTime
    );
    
    /**
     * @notice Emitted when an auction is canceled.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was canceled.
     */
    event ReserveAuctionCanceled(uint256 indexed auctionId);
    
    /**
     * @notice Emitted when an DNFT is listed for auction.
     * @param seller The address of the seller.
     * @param derivativeNFT The address of the DNFT contract.
     * @param projectId The project id of the DNFT.
     * @param tokenId The id of the DNFT.
     * @param units The units of the DNFT.
     * @param tokenIdInEscrow The escrow token id of the DNFT.
     * @param duration The duration of the auction (always 24-hours).
     * @param extensionDuration The duration of the auction extension window (always 15-minutes).
     * @param reservePrice The reserve price to kick off the auction.
     * @param auctionId The id of the auction that was created.
     */
    event ReserveAuctionCreated(
        address indexed seller,
        address indexed derivativeNFT,
        uint256 indexed projectId,
        uint256 tokenId,
        uint256 units,
        uint256 tokenIdInEscrow,
        uint256 duration,
        uint256 extensionDuration,
        uint256 reservePrice,
        uint256 auctionId
    );
   
    /**
     * @notice Emitted when an auction that has already ended is finalized,
     * indicating that the DNFT has been transferred and revenue from the sale distributed.
     * @dev The amount of the highest bid / final sale price for this auction
     * is `totalFees` + `creatorRev` + `sellerRev`.
     * @param auctionId The id of the auction that was finalized.
     * @param seller The address of the seller.
     * @param bidder The address of the highest bidder that won the DNFT.
     * @param royaltyAmounts The royalty amounts data
     */
    event ReserveAuctionFinalized(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed bidder,
        DataTypes.RoyaltyAmounts royaltyAmounts
    );
    
    /**
     * @notice Emitted when an auction is invalidated due to other market activity.
     * @dev This occurs when the DNFT is sold another way, such as with `buy` or `acceptOffer`.
     * @param auctionId The id of the auction that was invalidated.
     */
    event ReserveAuctionInvalidated(uint256 indexed auctionId);
    
    /**
     * @notice Emitted when the auction's reserve price is changed.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was updated.
     * @param reservePrice The new reserve price for the auction.
     */
    event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);

   
    //Bank Treasury
    /**
     * @notice Emitted when SBT tokens are locked up by the Foundation market for 24-25 hours
     * and may include newly deposited SBT Value which is added to the account's total SBT balance.
     * @param account The address which has access to the SBT after the `expiration`.
     * @param soulBoundTokenId The soulBoundTokenId of account
     * @param expiration The time at which the `from` account will have access to the locked SBT.
     * @param amount The number of SBT tokens which where locked up.
     * @param valueDeposited The amount of ETH added to their account's total SBT balance,
     * this may be lower than `amount` if available SBT was leveraged.
     */
    event BalanceLocked(address indexed account, uint256 indexed soulBoundTokenId, uint256 indexed expiration, uint256 amount, uint256 valueDeposited);
    /**
     * @notice Emitted when SBT tokens are unlocked by the Foundation market.
     * @dev This event will not be emitted when lockups expire,
     * it's only for tokens which are unlocked before their expiry.
     * @param account The address which had locked SBT freed before expiration.
     * @param soulBoundTokenId The soulBoundTokenId of account
     * @param expiration The time this balance was originally scheduled to be unlocked.
     * @param amount The number of SBT tokens which were unlocked.
     */
    event BalanceUnlocked(
        address indexed account,
        uint256 indexed soulBoundTokenId, 
        uint256 indexed expiration, 
        uint256 amount
    );    

    /**
     * @notice Emitted when accept offer is withdrawn from a buyer's account.
     * @dev This may be triggered by the user, an approved operator, or the Foundation market.
     * @param buyer The address of buyer was deducted in order to pay for.
     * @param soulBoundTokenIdBuyer The soulBoundTokenId of buyer was deducted in order to pay for.
     * @param owner The address of owner
     * @param soulBoundTokenIdOwner The soulBoundTokenId of owner was added because owner accept the offer.
     * @param amount The number of tokens which were deducted from the buyer's account and transferred to owner account.
     */
    event OfferWithdrawn(
        address indexed buyer,
        uint256 indexed soulBoundTokenIdBuyer, 
        address owner,
        uint256 indexed soulBoundTokenIdOwner, 
        uint256 amount
    );

    /**
     * @dev Emitted when ether send to bank treasury contract
     *
     * @param sender The sender 
     * @param amount The amount
     * @param sender The receiver 
     * @param balance balance of contract
     */
    event Deposit(
        address indexed sender, 
        uint256 amount, 
        address indexed receiver, 
        uint256 balance
    );
    
    /**
     * @dev Emitted when ether send to bank treasury contract
     *
     * @param sender The sender 
     * @param amount The amount
     * @param data msg.data 
     * @param sender The receiver 
     * @param balance balance of contract
     */
    event DepositByFallback(
        address indexed sender, 
        uint256 amount, 
        bytes data,
        address indexed receiver, 
        uint256 balance
    );
    
    /**
     * @dev Emitted when transcation is submit
     *
     * @param owner The owner 
     * @param txIndex The index of tx
     * @param to The to 
     * @param value value of transcation
     * @param data data of transcation
     */
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );    

    /**
     * @dev Emitted when transcation is confirm
     *
     * @param owner The owner 
     * @param txIndex The index of tx
     */
    event ConfirmTransaction(
        address indexed owner, 
        uint256 indexed txIndex
    );

    /**
     * @dev Emitted when transcation is revoke confirm
     *
     * @param owner The owner 
     * @param txIndex The index of tx
     */
    event RevokeConfirmation(
        address indexed owner, 
        uint256 indexed txIndex
    );

    /**
     * @dev Emitted when transcation is execute
     *
     * @param owner The owner 
     * @param txIndex The index of tx
     * @param value The value of transcation
     * 
     */
    event ExecuteTransaction(
        address indexed owner, 
        uint256 indexed txIndex, 
        address to, 
        uint256 value
    );

    /**
     * @dev Emitted when ERC3525 transcation is execute
     *
     * @param owner The owner 
     * @param txIndex The index of tx
     * @param fromTokenId The from tokenId of transcation
     * @param toTokenId The to tokenId of transcation
     * @param value The value of transcation
     * 
     */
    event ExecuteTransactionERC3525(
        address indexed owner, 
        uint256 indexed txIndex, 
        uint256 indexed fromTokenId, 
        uint256 toTokenId, 
        uint256 value
    );

    /**
     * @dev Emitted when ERC3525 is withdrawn
     *
     * 
     * @param toSoulBoundTokenId The to tokenId of transcation
     * @param value The value of transcation
     * 
     */
    event WithdrawnEarnestMoney(
        uint256 indexed toSoulBoundTokenId, 
        address indexed to,
        uint256 indexed value,
        uint256 availableBalance
    );

    /**
     * @dev Emitted when a collect module is added to or removed from the whitelist.
     *
     * @param collectModule The address of the collect module.
     * @param whitelisted Whether or not the collect module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event CollectModuleWhitelisted(
        address indexed collectModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a template is added to or removed from the whitelist.
     *
     * @param template The address of the collect module.
     * @param whitelisted Whether or not the collect module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event TemplateWhitelisted(
        address indexed template,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a publish module is added to or removed from the whitelist.
     *
     * @param publishModule The address of the publish module.
     * @param whitelisted Whether or not the publish module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event PublishModuleWhitelisted(
        address indexed publishModule,
        bool indexed whitelisted,
        uint256 timestamp
    );


    /**
     * @dev Emitted when a voucher is generated
     *
     * @param vouchType The vouch type
     * @param tokenId The tokenId
     * @param etherValue The value of ether
     * @param sbtValue The value of SBT
     * @param generateTimestamp The current block timestamp.
     * @param endTimestamp The expired timestamp, if set to 0 is not limit
     */
    event GenerateVoucher(
        DataTypes.VoucherParValueType vouchType,
        uint256 tokenId,
        uint256 etherValue,
        uint256 sbtValue,
        uint256 generateTimestamp,
        uint256 endTimestamp
    );

    /**
     * @dev Emitted when a voucher is minted
     *
     * @param soulBoundTokenId  SBTId who mint this NFT voucher
     * @param account The mint address 
     * @param vouchType The vouch type
     * @param tokenId The tokenId
     * @param sbtValue The value of sbt
     * @param generateTimestamp The generated timestamp
     */
    event MintNFTVoucher(
        uint256 soulBoundTokenId,
        address account,
        DataTypes.VoucherParValueType vouchType,
        uint256 tokenId,
        uint256 sbtValue,
        uint256 generateTimestamp
    );

    /**
     * @dev Emitted when a voucher is minted
     *
     * @param preUserAmountLimit  The pre userAmountLimit
     * @param userAmountLimit The new userAmountLimit
     * @param timestamp  The current block timestamp.
     */
    event UserAmountLimitSet(
        uint256 preUserAmountLimit,
        uint256 userAmountLimit,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a contract is set to transferValue whilelist
     *
     * @param contractAddress  The contract address
     * @param prevWhitelisted The prev whitelisted
     * @param whitelisted The new whitelisted
     * @param timestamp  The current block timestamp.
     */
    event SetContractWhitelisted(
        address indexed contractAddress,
        bool indexed prevWhitelisted,
        bool indexed whitelisted,
        uint256 timestamp
    );


    /**
     * @dev Emitted when royalty points updated when set to Level-Five fee
     *
     * @param projectId  The contract address
     * @param newRoyaltyPoints new RoyaltyPoints
     * @param timestamp  The current block timestamp.
     */
    event UpdateRoyaltyPoints(
        uint256 indexed projectId,
        uint16[5] indexed newRoyaltyPoints,
        uint256 timestamp
    );

    /**
     * @dev Emitted when pay fees for collect
     *
     * @param publishId  The publishId 
     * @param tokenId  The tokenId collected
     * @param payValue  The SBT value will pay
     * @param collectFeeUsers The collectFeeUsers data
     * @param royaltyAmounts  The royaltyAmounts data
     */
    event FeesForCollect (
        uint256 publishId, 
        uint256 tokenId, 
        uint96 payValue, 
        DataTypes.CollectFeeUsers collectFeeUsers,
        DataTypes.RoyaltyAmounts royaltyAmounts
    );

    /**
     * @dev Emitted when exchange SBT value by ether
     *
     * @param soulBoundTokenId  The contract address
     * @param exchangeWallet The exchangeWallet
     * @param sbtValue  The sbtValue
     * @param timestamp  The current block timestamp.
     */
    event ExchangeSBTByEth(
        uint256 indexed soulBoundTokenId,
        address indexed exchangeWallet,
        uint256 indexed sbtValue,
        uint256 timestamp
    );

    /**
     * @dev Emitted when exchange ether by SBT value
     *
     * @param soulBoundTokenId  The contract address
     * @param toWallet The to Wallet
     * @param sbtValue  The sbtValue
     * @param exchangePrice  The exchange price set with admin
     * @param ethAmount  The exchange ether amount
     * @param timestamp  The current block timestamp.
     */
    event ExchangeEthBySBT(
         uint256 indexed soulBoundTokenId,
         address indexed toWallet,
         uint256 indexed sbtValue,
         uint256 exchangePrice,
         uint256 ethAmount,
         uint256 timestamp
    );

    /**
     * @dev Emitted when exchange voucher
     *
     * @param soulBoundTokenId  The contract address
     * @param operator The operator
     * @param tokenId  The tokenId
     * @param sbtValue  The sbtValue
     * @param timestamp  The current block timestamp.
     */
    event ExchangeVoucher(
        uint256 indexed soulBoundTokenId,
        address indexed operator,
        uint256 indexed tokenId,
        uint256 sbtValue,
        uint256 timestamp
    );

    //votes

     /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(
        address indexed delegator, 
        address indexed fromDelegate, 
        address indexed toDelegate, 
        uint256 tokeId_delegator
    );

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(
        address indexed delegate, 
        uint256 previousBalance, 
        uint256 newBalance
    );

    event RoyaltySet(
        uint256 indexed soulBoundTokenId,
        uint256 indexed projectId,
        uint256 indexed royaltyBasisPoints
    );

    event DefaultRoyaltySet(
        uint256 indexed soulBoundTokenId,
        uint256 indexed projectId,
        address indexed receiver,
        uint96 feeNumerator
    );



}

