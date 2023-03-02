// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Events} from "../libraries/Events.sol";
import {Errors} from "../libraries/Errors.sol";
import "./DNFTMarketCore.sol";
import {ICollectModule} from "../interfaces/ICollectModule.sol";
// import "hardhat/console.sol";


/**
 * @title Allows sellers to set a buy price of their DNFTs that may be accepted and instantly transferred to the buyer.
 * @notice DNFTs with a buy price set are escrowed in the market contract.
 * @author bitsoul Protocol
 */
abstract contract DNFTMarketBuyPrice is
  Initializable,
  DNFTMarketCore
{

  /// @notice Stores the current buy price for each DNFT.
  mapping(address => mapping(uint256 => DataTypes.BuyPrice)) internal dnftContractToTokenIdToBuyPrice;

  /**
   * @notice Buy the DNFT at the set buy price.
   * the account's available EarnestFunds balance must be >= `maxPrice`
   * @dev `maxPrice` protects the buyer in case a the price is increased but allows the transaction to continue
   * when the price is reduced (and any surplus funds provided are refunded).
   * @param soulBoundTokenIdBuyer The SBT id of buyer.
   * @param derivativeNFT The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   * @param maxPrice The maximum price to pay for the DNFT.
   * @param soulBoundTokenIdReferrer The SBT id of the referrer.
   */
  function buy(
    uint256 soulBoundTokenIdBuyer,
    address derivativeNFT,
    uint256 tokenId,
    uint256 maxPrice,
    uint256 soulBoundTokenIdReferrer
  ) public {
    if ( soulBoundTokenIdBuyer == 0 || tokenId == 0 || maxPrice == 0 )
      revert Errors.InvalidParameter();

    // validate martket is open for this contract?
    if (!_getMarketInfo(derivativeNFT).isOpen)
        revert Errors.Market_DNFT_Is_Not_Open(derivativeNFT);
       
    address buyer = _getWallet(soulBoundTokenIdBuyer);
    
    if (buyer != msg.sender ) 
      revert Errors.Unauthorized();

    DataTypes.BuyPrice storage buyPrice = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];
    if (buyPrice.salePrice > maxPrice) {
      revert Errors.DNFTMarketBuyPrice_Cannot_Buy_At_Lower_Price(buyPrice.salePrice);
    } else if (buyPrice.seller == address(0)) {
      revert Errors.DNFTMarketBuyPrice_Cannot_Buy_Unset_Price();
    }
    
    _buy(soulBoundTokenIdBuyer, derivativeNFT, tokenId, soulBoundTokenIdReferrer);
  }

  /**
   * @notice Removes the buy price set for an DNFT.
   * @dev The DNFT is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * 
   * @param derivativeNFT The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   */
  function cancelBuyPrice(
    address derivativeNFT, 
    uint256 tokenId
  ) external { 

    address seller = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId].seller;
    if (seller == address(0)) {
      // This check is redundant with the next one, but done in order to provide a more clear error message.
      revert Errors.DNFTMarketBuyPrice_Cannot_Cancel_Unset_Price();
    } else if (seller != msg.sender) {
      revert Errors.DNFTMarketBuyPrice_Only_Owner_Can_Cancel_Price(seller);
    }

    // Remove the buy price
    delete dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];

    // Transfer the DNFT back to the owner if it is not listed in auction.
    _transferFromEscrowIfAvailable(derivativeNFT, tokenId, seller);

    emit Events.BuyPriceCanceled(derivativeNFT, tokenId);
  }

  /**
   * @notice Sets the buy price for an DNFT and escrows it in the market contract.
   * A 0 price is acceptable and valid price you can set, enabling a giveaway to the first collector that calls `buy`.
   * @dev If there is an offer for this amount or higher, that will be accepted instead of setting a buy price.
   * @param buyPriceParam The sale param to set buy price
   *      --soulBoundTokenId: SBT id of owner
   *      --derivativeNFT: DNFT contract addrss
   *      --tokenId: DNFT token id
   *      --currency: The ERC20 currency
   *      --salePrice: The sale price of one unit, amount = units * salePrice
   */
  function setBuyPrice(
    DataTypes.BuyPriceParam memory buyPriceParam
  ) external{ 
    if (buyPriceParam.salePrice == 0 || 
      buyPriceParam.derivativeNFT == address(0) ||
      buyPriceParam.tokenId == 0 ||
      buyPriceParam.currency == address(0)
    )
      revert Errors.InvalidParameter();
    
    // validate martket is open for this contract
    if (!_getMarketInfo(buyPriceParam.derivativeNFT).isOpen)
        revert Errors.Market_DNFT_Is_Not_Open(buyPriceParam.derivativeNFT);
        
    // validate currency is in whitelisted
    if (!_isCurrencyWhitelisted(buyPriceParam.currency))
        revert Errors.CurrencyNotInWhitelisted(buyPriceParam.currency);

    uint256 projectId = _getMarketInfo(buyPriceParam.derivativeNFT).projectId;
    if (projectId == 0) 
        revert Errors.UnsupportedDerivativeNFT();

    uint256 publishId = IDerivativeNFT(buyPriceParam.derivativeNFT).getPublishIdByTokenId(buyPriceParam.tokenId);

    //save to storage
    DataTypes.BuyPrice storage buyPrice = dnftContractToTokenIdToBuyPrice[buyPriceParam.derivativeNFT][buyPriceParam.tokenId];
    address seller = buyPrice.seller;

    buyPrice.soulBoundTokenIdSeller = buyPriceParam.soulBoundTokenId;
    buyPrice.tokenId = buyPriceParam.tokenId;
    buyPrice.derivativeNFT = buyPriceParam.derivativeNFT;
    
    if (buyPrice.salePrice == buyPriceParam.salePrice && seller != address(0)) {
      revert Errors.DNFTMarketBuyPrice_Price_Already_Set();
    }
    if (buyPrice.salePrice > type(uint96).max) {
      // This ensures that no data is lost when storing the price as `uint96`.
      revert Errors.DNFTMarketBuyPrice_Price_Too_High();
    }

    // Store the new salePrice for this DNFT.
    buyPrice.salePrice = uint96(buyPriceParam.salePrice);

    buyPrice.projectId = projectId;    
    buyPrice.publishId = publishId;
      
    uint128 units = uint128(IERC3525(buyPriceParam.derivativeNFT).balanceOf(buyPriceParam.tokenId));

    buyPrice.units = units;
    buyPrice.amount = uint96(units * buyPrice.salePrice);

    buyPrice.currency = buyPriceParam.currency;


    if (seller == address(0)) {

      // Transfer the DNFT into escrow, if it's already in escrow confirm the `msg.sender` is the owner.
      //must approve manager before
      _transferToEscrow(buyPriceParam.derivativeNFT, buyPriceParam.tokenId);

      // The salePrice was not previously set for this DNFT, store the seller.
      buyPrice.seller = payable(msg.sender);

    } else if (seller != msg.sender) {
      // Buy price was previously set by a different user
      revert Errors.DNFTMarketBuyPrice_Only_Owner_Can_Set_Price(seller);
    }

    // If there is a valid offer at this salePrice or higher, accept that instead.
     _autoAcceptOffer(buyPriceParam, units); 

    emit Events.BuyPriceSet(
      buyPriceParam.derivativeNFT,
      buyPriceParam.tokenId
    );

  }

  /**
   * @notice If there is a buy price at this price or lower, accept that and return true.
   */
  function _autoAcceptBuyPrice(
    uint256 soulBoundTokenIdBuyer, 
    address derivativeNFT,
    uint256 tokenId,
    uint96 amount
  ) internal override returns (bool) {

    DataTypes.BuyPrice storage buyPrice = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];

    if (buyPrice.seller == address(0) || buyPrice.amount > amount) {
      // No buy price was found, or the price is too high.
      return false;
    }

    _buy(soulBoundTokenIdBuyer, derivativeNFT, tokenId, 0);
    return true;
  }
  
  /**
   * @inheritdoc DNFTMarketCore
   * @dev Invalidates the buy price on a auction start, if one is found.
   */
  function _beforeAuctionStarted(address derivativeNFT, uint256 tokenId) internal virtual override(DNFTMarketCore) {
    DataTypes.BuyPrice storage buyPrice = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];
    
    if (buyPrice.seller != address(0)) {

      // A buy price was set for this DNFT, invalidate it.
      _invalidateBuyPrice(derivativeNFT, tokenId);
    }
    super._beforeAuctionStarted(derivativeNFT, tokenId);
  }

  /**
   * @notice Process the purchase of an DNFT at the current buy price.
   * @dev The caller must confirm that the seller != address(0) before calling this function.
   */
  function _buy(
    uint256 soulBoundTokenIdBuyer, 
    address derivativeNFT,
    uint256 tokenId,
    uint256 soulBoundTokenIdReferrer
  ) private { 
    DataTypes.BuyPrice memory buyPrice = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];

    // Cancel the buyer's offer if there is one in order to free up their EarnestFunds balance
    // even if they don't need the EarnestFunds for this specific purchase.
    _cancelSendersOffer(derivativeNFT, tokenId);

    address buyer = msg.sender;
    // Transfer the DNFT to the buyer.
    // The seller was already authorized when the buyPrice was set originally set.
    _transferFromEscrow(derivativeNFT, tokenId, buyer, address(0));

    //Use free earnest funs balance for pay 
    IBankTreasury(treasury).useEarnestFundsForPay(
        soulBoundTokenIdBuyer,
        buyPrice.currency,
        buyPrice.amount
    );


    // Distribute revenue for this sale.
    address collectModule = _getMarketInfo(derivativeNFT).collectModule;
  
    bytes memory collectModuleInitData = abi.encode(
      soulBoundTokenIdReferrer, 
      BUY_REFERRER_FEE_DENOMINATOR,
      buyPrice.units
    );

    DataTypes.RoyaltyAmounts memory royaltyAmounts = ICollectModule(collectModule).processCollect(
        buyPrice.soulBoundTokenIdSeller,
        soulBoundTokenIdBuyer,
        buyPrice.publishId,
        buyPrice.amount, 
        collectModuleInitData
    );
    
    delete dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];
    
    emit Events.BuyPriceAccepted(
      derivativeNFT,
      buyPrice.tokenId, 
      buyPrice.seller, 
      msg.sender,  //buyer
      buyPrice.currency,
      royaltyAmounts
    );
    
  }

  /**
   * @notice Clear a buy price and emit BuyPriceInvalidated.
   * @dev The caller must confirm the buy price is set before calling this function.
   */
  function _invalidateBuyPrice(address derivativeNFT, uint256 tokenId) private {
    delete dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];
    emit Events.BuyPriceInvalidated(derivativeNFT, tokenId);
  }

  /**
   * @inheritdoc DNFTMarketCore
   * @dev Checks if there is a buy price set, if not then allow the transfer to proceed.
   */
  function _transferFromEscrowIfAvailable(
    address derivativeNFT,
    uint256 tokenId,
    address recipient
  ) internal virtual override {
    address seller = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId].seller;
    if (seller == address(0)) {
      // A buy price has been set for this DNFT so it should remain in escrow.
      super._transferFromEscrowIfAvailable(derivativeNFT, tokenId, recipient);
    }
  }

  /**
   * @inheritdoc DNFTMarketCore
   * @dev Checks if the DNFT is already in escrow for buy now.
   */
  function _transferToEscrow(address derivativeNFT, uint256 tokenId) 
      internal virtual override
  {
    address seller = dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId].seller;
    if (seller == address(0)) {
      // The DNFT is not in escrow for buy now.
       super._transferToEscrow(derivativeNFT, tokenId);
    } else if (seller != msg.sender) {
      // When there is a buy price set, the `seller` is the owner of the DNFT.
      revert Errors.DNFTMarketBuyPrice_Seller_Mismatch(seller);
    }
  }

  /**
   * @notice Returns the buy price details for an DNFT if one is available.
   * @dev If no price is found, seller will be address(0) and price will be max uint256.
   * @param derivativeNFT The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   * @return buyPrice The BuyPrice details data.
   */
  function getBuyPrice(address derivativeNFT, uint256 tokenId) external view returns (DataTypes.BuyPrice memory) {
    return dnftContractToTokenIdToBuyPrice[derivativeNFT][tokenId];
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  // uint256[1_000] private __gap;
}
