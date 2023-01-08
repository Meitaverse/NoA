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
     * @dev Emitted when a publish is created.
     *
     * @param publishId The newly created project's ID.
     * @param soulBoundTokenId The newly created profile's token ID.
     * @param hubId The hub ID.
     * @param projectId The project ID.
     * @param newTokenId The new token id .
     * @param amount The amount of the token.
     * @param collectModuleInitData The data include some variables.
     * @param timestamp The current block timestamp.
     */
    event PublishCreated(
        uint256 publishId,
        uint256 soulBoundTokenId,
        uint256 hubId,
        uint256 projectId,
        uint256 newTokenId,
        uint256 amount,
        bytes collectModuleInitData,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a hub is created.
     *
     * @param soulBoundTokenId The newly created profile's token ID.
     * @param creator The profile creator, who created the token with the given profile ID.
     * @param hubId The hub ID.
     * @param name The name set for the hub.
     * @param description The description set for the hub.
     * @param imageURI The image uri set for the profile.
     * @param timestamp The current block timestamp.
     */
    event HubCreated(
        uint256 indexed soulBoundTokenId,
        address indexed creator,
        uint256 indexed hubId,
        string name,
        string description,
        string imageURI,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a dNFT is burned.
     *
     * @param projectId The newly created profile's token ID.
     * @param tokenId The profile creator, who created the token with the given profile ID.
     * @param owner The image uri set for the profile.
     * @param timestamp The current block timestamp.
     */
    event BurnToken(
        uint256 projectId, 
        uint256 tokenId, 
        address owner,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a dNFT is burned with sig.
     *
     * @param projectId The newly created profile's token ID.
     * @param tokenId The profile creator, who created the token with the given profile ID.
     * @param owner The image uri set for the profile.
     * @param timestamp The current block timestamp.
     */
    event BurnTokenWithSig(
        uint256 projectId, 
        uint256 tokenId, 
        address owner,
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
     * @dev MUST emits when an operator is approved or disapproved to manage all of `_owner`'s
     *  tokens with the same slot.
     * @param owner The address whose tokens are approved
     * @param slot The slot to approve, all of `_owner`'s tokens with this slot are approved
     * @param operator The operator being approved or disapproved
     * @param approved Identify if `_operator` is approved or disapproved
     */
    event ApprovalForSlot(
        address indexed owner, 
        uint256 indexed slot, 
        address indexed operator, 
        bool approved
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
     * @param operator The operator who called by.
     * @param fromTokenId The from token id
     * @param toTokenId The to token id
     * @param value The value of token
     * @param data The data extend
     * @param gas The gas left
     */    
    event ERC3525Received(
        address operator, 
        uint256 fromTokenId, 
        uint256 toTokenId, 
        uint256 value, 
        bytes data, 
        uint256 gas
    );

    /**
     * @dev Emitted when the market place receive ERC3525 tokens
     *
     * @param operator The operator who called by.
     * @param fromTokenId The from token id
     * @param toTokenId The to token id
     * @param value The value of token
     * @param data The data extend
     * @param gas The gas left
     */    
    event MarketPlaceERC3525Received(
        address operator, 
        uint256 fromTokenId, 
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
        address operator, 
        uint256 fromTokenId, 
        uint256 toTokenId, 
        uint256 value, 
        bytes data, 
        uint256 gas
    );

    /**
     * @dev Emitted when SBT contract the bank treasury is set
     *
     * @param soulBoundTokenId The bank treasury token id, default is 1
     * @param bankTrerasury The address of bank treasury
     * @param initialSupply The initial supply
     * @param timestamp The block timestamp
     */  
    event BankTreasurySet(
        uint256 indexed soulBoundTokenId, 
        address indexed bankTrerasury, 
        uint256 indexed initialSupply, 
        uint256 timestamp
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
    
    event ModuleGlobalsVoucherSet(
        address indexed prevVoucher,
        address indexed newVoucher,
        uint256 timestamp
    );

    event ModuleGlobalsManagerSet(
        address indexed prevManager,
        address indexed newManager,
        uint256 timestamp
    );
    
    event ModuleGlobalsSBTSet(
        address indexed prevSBT,
        address indexed newSBT,
        uint256 timestamp
    );

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
     * @param timestamp The current block timestamp.
     */
    event ModuleBaseConstructed(address indexed manager, uint256 timestamp);

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
     * @param timestamp The current block timestamp.
     */
    event ProfileCreatorWhitelisted(
        address indexed profileCreator,
        bool indexed whitelisted,
        uint256 timestamp
    );

    event HubCreatorWhitelisted(
        uint256 indexed soulBoundTokenId,
        bool indexed whitelisted,
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
     * @param projectId The project ID.
     * @param soulBoundTokenId The user's SoulBound token ID.
     * @param derivativeNFT The address of the newly deployed DerivativeNFT clone.
     * @param timestamp The current block timestamp.
     */
    event DerivativeNFTDeployed(
        uint256 indexed projectId,
        uint256 indexed soulBoundTokenId,
        address derivativeNFT,
        uint256 timestamp
    );

    event BurnSBT(
        uint256 soulBoundTokenId, 
        uint256 timestamp
    );

    event BurnSBTValue(
        uint256 soulBoundTokenId, 
        uint256 value, 
        uint256 timestamp
    );

    /**
     * @dev Emitted when Manager call to mintValue of SBT Tokens.
     * @param soulBoundTokenId The token id of SBT
     * @param value The value of mint SBT
     * @param timestamp The current block timestamp.
     */
    event MintSBTValue(
        uint256 soulBoundTokenId,
        uint256 value,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a profile's URI is set.
     *
     * @param soulBoundTokenId The token ID of the profile for which the URI is set.
     * @param imageURI The URI set for the given profile.
     * @param timestamp The current block timestamp.
     */
    event ProfileImageURISet(
        uint256 indexed soulBoundTokenId, 
        string imageURI, 
        uint256 timestamp
    );

    event DerivativeNFTCollected(
        uint256 projectId,
        address derivativeNFT,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        uint256 newTokenId,
        uint256 timestamp
    );

    event DerivativeNFTAirdroped(
        uint256 projectId,
        address derivativeNFT,
        uint256 fromSoulBoundTokenId,
        uint256 tokenId,
        uint256[] toSoulBoundTokenIds,
        uint256[] values,
        uint256[] newTokenIds,
        uint256 timestamp
    );


    event TransferDerivativeNFT(
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 projectId,
        uint256 tokenId,
        uint256 timestamp
    );

    event TransferValueDerivativeNFT(
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 projectId,
        uint256 tokenId,
        uint256 value,
        uint256 newTokenId,
        uint256 timestamp
    );

    event FixedPriceSet (
       uint256 soulBoundTokenId,
       uint128  saleId,
       uint128  preSalePrice,
       uint128  newSalePrice,
       uint256  timestamp
    );

    event PublishSale(
        DataTypes.SaleParam saleParam,
        address derivativeNFT,
        uint256 newTokenId,
        uint128 saleId
    );

   event AddMarket(
        address derivativeNFT,
        DataTypes.FeePayType feePayType,
        DataTypes.FeeShareType feeShareType,
        // uint128 feeAmount,
        uint16 royaltyBasisPoints
    );

   event RemoveMarket(address derivativeNFT);

   event RemoveSale(
        uint256 soulBoundTokenId,
        uint128    saleId,
        uint256    onSellUnits,
        uint256    saledUnits
    ); 
    
    event Traded(
        uint24 indexed saleId,
        uint256 tradeId,
        uint32 tradeTime,
        uint128 price,
        uint256 newTokenIdBuyer,
        uint128 tradedUnits
    );

    //BankTreasury

    event Deposit(
        address indexed sender, 
        uint256 amount, 
        uint256 balance
    );

    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );    

    event ConfirmTransaction(
        address indexed owner, 
        uint256 indexed txIndex
    );

    event RevokeConfirmation(
        address indexed owner, 
        uint256 indexed txIndex
    );

    event ExecuteTransaction(
        address indexed owner, 
        uint256 indexed txIndex, 
        address to, 
        uint256 value
    );

    event ExecuteTransactionERC3525(
        address indexed owner, 
        uint256 indexed txIndex, 
        uint256 indexed fromTokenId, 
        uint256 toTokenId, 
        uint256 value
    );
    
    event WithdrawERC3525(
        uint256 indexed fromTokenId, 
        uint256 indexed toTokenId, 
        uint256 value,
        uint256 timestamp
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

    event PublishPrepared(
        DataTypes.Publication publication,
        uint256 publishId,
        uint256 previousPublishId,
        uint256 publishTaxAmount,
        uint256 timestamp
    );
   
    event PublishUpdated(
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

    event GenerateVoucher(
        DataTypes.VoucherParValueType vouchType,
        uint256 tokenId,
        uint256 etherValue,
        uint256 sbtValue,
        uint256 generateTimestamp,
        uint256 endTimestamp
    );

    event MintNFTVoucher(
        uint256 soulBoundTokenId,
        address account,
        DataTypes.VoucherParValueType vouchType,
        uint256 tokenId,
        uint256 sbtValue,
        uint256 generateTimestamp
    );

    event UserAmountLimitSet(
        uint256 preUserAmountLimit,
        uint256 userAmountLimit,
        uint256 endTimestamp
    );

    event SetContractWhitelisted(
        address indexed contractAddress,
        bool indexed prevWhitelisted,
        bool indexed whitelisted,
        uint256 timestamp
    );
    
    event UpdateRoyaltyPoints(
        uint256 indexed projectId,
        uint16[5] indexed newRoyaltyPoints,
        uint256 timestamp
    );

    event FeesForCollect (
        uint256 publishId, 
        DataTypes.CollectFeeUsers collectFeeUsers,
        DataTypes.RoyaltyAmounts royaltyAmounts
    );

    event ExchangeSBTByEth(
        uint256 indexed soulBoundTokenId,
        address indexed exchangeWallet,
        uint256 indexed sbtValue,
        uint256 timestamp
    );

    event ExchangeEthBySBT(
         uint256 indexed soulBoundTokenId,
         address indexed toWallet,
         uint256 indexed sbtValue,
         uint256 exchangePrice,
         uint256 ethAmount,
         uint256 timestamp
    );

    event ExchangeVoucher(
        uint256 indexed soulBoundTokenId,
        address indexed operator,
        uint256 indexed tokenId,
        uint256 sbtValue,
        uint256 timestamp
    );

}

