// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../libraries/SafeMathUpgradeable128.sol";
import {IManager} from "../interfaces/IManager.sol";
import {Events} from "../libraries/Events.sol";
import {Errors} from "../libraries/Errors.sol";
import {DataTypes} from '../libraries/DataTypes.sol';
import {IBankTreasury} from '../interfaces/IBankTreasury.sol';
import "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import "../libraries/Constants.sol";
import "./DNFTMarketCore.sol";
import "./MarketSharedCore.sol";

abstract contract MarketFees is  MarketSharedCore, DNFTMarketCore {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable128 for uint128;
    
    /// @notice The fee collected by the buy referrer for sales facilitated by this market contract.
    ///         This fee is calculated from the total protocol fee.
    uint256 private constant BUY_REFERRER_FEE_DENOMINATOR = BASIS_POINTS / 100; // 1%

    constructor() {}

  /**
   * @notice Withdraw the msg.sender's available SBT Value balance if they requested more than the msg.value provided.
   * @dev This may revert if the msg.sender is non-receivable.
   * This helper should not be used anywhere that may lead to locked assets.
   * @param totalAmount The total amount of SBT Value required (including the msg.value).
   * @param shouldRefundSurplus If true, refund msg.value - totalAmount to the msg.sender.
   */
  function _tryUseSBTValueBalance(uint256 totalAmount, bool shouldRefundSurplus) internal {
    if (totalAmount > msg.value) {
      // Withdraw additional ETH required from the user's available FETH balance.
      unchecked {
        // The if above ensures delta will not underflow.
        // Withdraw ETH from the user's account in the FETH token contract,
        // making the funds available in this contract as ETH.
        // feth.marketWithdrawFrom(msg.sender, totalAmount - msg.value);
      }
    } else if (shouldRefundSurplus && totalAmount < msg.value) {
      // Return any surplus ETH to the user.
      unchecked {
        // The if above ensures this will not underflow
        // payable(msg.sender).sendValue(msg.value - totalAmount);
      }
    }
  }    

    /**
     * @notice Distributes funds to foundation, creator recipients, buy referrer and DNFT owner after a sale.
     */
    function _distributeFunds(
        DataTypes.CollectFeeUsers memory collectFeeUsers,
        uint256 projectId,
        address derivativeNFT,
        uint256 tokenId,
        uint256 payValue
    )
        internal
        returns (
            DataTypes.RoyaltyAmounts memory royaltyAmounts
        )
    {
        //Transfer Value of total pay to treasury 
        INFTDerivativeProtocolTokenV1(_getSBT()).transferValue(collectFeeUsers.collectorSoulBoundTokenId, BANK_TREASURY_SOUL_BOUND_TOKENID, payValue);

        //get realtime bank treasury fee points
        (address treasury, uint16 treasuryFee) = _getTreasuryData();

       (
        uint256 soulBoundTokenId_gengesis,
        uint256 royaltyBasisPoints_gengesis,
        uint256 soulBoundTokenId_previous,
        uint256 royaltyBasisPoints_previous
       ) =  IManager(_getManager()).getGenesisAndPreviousInfo(projectId, tokenId);
        
        collectFeeUsers.genesisSoulBoundTokenId = soulBoundTokenId_gengesis;
        collectFeeUsers.previousSoulBoundTokenId = soulBoundTokenId_previous;

        // calculate fees
        royaltyAmounts.treasuryAmount = payValue.mul(treasuryFee).div(BASIS_POINTS);
        royaltyAmounts.genesisAmount = payValue.mul(royaltyBasisPoints_gengesis).div(BASIS_POINTS);
        royaltyAmounts.previousAmount = payValue.mul(royaltyBasisPoints_previous).div(BASIS_POINTS);

        {
            DataTypes.Market memory market = _getMarketInfo(derivativeNFT);

            if (royaltyAmounts.treasuryAmount > 0) {
                if (market.feePayType == DataTypes.FeePayType.BUYER_PAY) {
                    royaltyAmounts.adjustedAmount = payValue.sub(royaltyAmounts.treasuryAmount).sub(royaltyAmounts.genesisAmount).sub(royaltyAmounts.previousAmount);
                    
                } else {
                    royaltyAmounts.adjustedAmount = payValue.sub(royaltyAmounts.genesisAmount).sub(royaltyAmounts.previousAmount);
                }
            }

            if(market.feeShareType == DataTypes.FeeShareType.LEVEL_FIVE) {
                royaltyAmounts.adjustedAmount = payValue.mul(market.royaltyBasisPoints);
            }
        }

        IBankTreasury(treasury).saveFundsToUserRevenue(
            collectFeeUsers,
            royaltyAmounts
        );
        
       
    }
}