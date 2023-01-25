// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../libraries/SafeMathUpgradeable128.sol";
import {IManager} from "../interfaces/IManager.sol";
import {IBankTreasury} from '../interfaces/IBankTreasury.sol';
import {INFTDerivativeProtocolTokenV1} from "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import {Events} from "../libraries/Events.sol";
import {Errors} from "../libraries/Errors.sol";
import {DataTypes} from '../libraries/DataTypes.sol';
import "../libraries/ArrayLibrary.sol";
import "../libraries/Constants.sol";
import "./DNFTMarketCore.sol";
import "./MarketSharedCore.sol";

abstract contract MarketFees is  MarketSharedCore, DNFTMarketCore {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable128 for uint128;
    using ArrayLibrary for uint256[];
    
    /// @notice The fee collected by the buy referrer for sales facilitated by this market contract.
    ///         This fee is calculated from the total protocol fee.
    uint256 private constant BUY_REFERRER_FEE_DENOMINATOR = BASIS_POINTS / 100; // 1%

    IManager internal immutable manager;
    IBankTreasury internal immutable treasury;
    INFTDerivativeProtocolTokenV1 internal immutable sbt;

    constructor(
        address manager_,
        address treasury_,
        address sbt_
    ) {
        manager = IManager(manager_);
        treasury = IBankTreasury(treasury_);
        sbt = INFTDerivativeProtocolTokenV1(sbt_);
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
       DataTypes.Market memory market;

       (royaltyAmounts, market) = _getFees(
            collectFeeUsers,
            projectId,
            derivativeNFT,
            tokenId,
            payValue
        );

        if (market.feePayType == DataTypes.FeePayType.BUYER_PAY) {
            //Transfer SBT Value = payValue +  treasuryAmount
            payValue += royaltyAmounts.treasuryAmount;
        }

        // sbt.transferValue(
        //     collectFeeUsers.collectorSoulBoundTokenId, 
        //     BANK_TREASURY_SOUL_BOUND_TOKENID, 
        //     payValue
        // );

        treasury.saveFundsToUserRevenue(
            collectFeeUsers.collectorSoulBoundTokenId,
            payValue,
            collectFeeUsers,
            royaltyAmounts
        );

    }

     /**
     * @notice Returns how funds will be distributed for a sale at the given price point.
     * @param soulBoundTokenId The soulBoundTokenId of owner 
     * @param projectId The project id
     * @param derivativeNFT The address of the DNFT contract.
     * @param tokenId The id of the DNFT.
     * @param units The units
     * @param price The sale price to calculate the fees for.
     * @return totalFees How much will be sent to the Foundation treasury and/or referrals.
     * @return creatorRev How much will be sent across all the `creatorRecipients` defined.
     * @return creatorRecipients The addresses of the recipients to receive a portion of the creator fee.
     * @return creatorShares The percentage of the creator fee to be distributed to each `creatorRecipient`.
     * If there is only one `creatorRecipient`, this may be an empty array.
     * Otherwise `creatorShares.length` == `creatorRecipients.length`.
     * @return sellerRev How much will be sent to the owner/seller of the DNFT.
     * If the DNFT is being sold by the creator, this may be 0 and the full revenue will appear as `creatorRev`.
     * @return seller The address of the owner of the DNFT.
     * If `sellerRev` is 0, this may be `address(0)`.
     */
    function getFeesAndRecipients(
        uint256 soulBoundTokenId,
        uint256 projectId,
        address derivativeNFT,
        uint256 tokenId,
        uint256 units,
        uint256 price
    )
        external
        view
        returns (
            uint256 totalFees,
            uint256 creatorRev,
            uint256[] memory creatorRecipients,
            uint256[] memory creatorShares,
            uint256 sellerRev,
            address payable seller
        )
    {

        DataTypes.CollectFeeUsers memory collectFeeUsers =  DataTypes.CollectFeeUsers({
                ownershipSoulBoundTokenId: soulBoundTokenId,
                collectorSoulBoundTokenId: manager.getSoulBoundTokenIdByWallet(msg.sender),
                genesisSoulBoundTokenId: 0,
                previousSoulBoundTokenId: 0,
                referrerSoulBoundTokenId: 0
        });        

        seller = _getSellerOrOwnerOf(derivativeNFT, tokenId);

         (DataTypes.RoyaltyAmounts memory royaltyAmounts,  ) = _getFees(
            collectFeeUsers,
            projectId,
            derivativeNFT,
            tokenId,
            price * units
        );

       totalFees = royaltyAmounts.treasuryAmount;
       creatorRev = royaltyAmounts.genesisAmount + royaltyAmounts.previousAmount;

       creatorRecipients.capLength(2);
       creatorShares.capLength(2);

       creatorRecipients[0] = collectFeeUsers.genesisSoulBoundTokenId;
       creatorRecipients[1] = collectFeeUsers.previousSoulBoundTokenId;

       creatorShares[0] = royaltyAmounts.genesisAmount;
       creatorShares[1] = royaltyAmounts.previousAmount;

       sellerRev = royaltyAmounts.adjustedAmount;

    }

    /**
     * @notice Calculates how funds should be distributed for the given sale details.
     * @dev When the DNFT is being sold by the `tokenCreator`, all the seller revenue will
     * be split with the royalty recipients defined for that DNFT.
     */
    // solhint-disable-next-line code-complexity
    function _getFees(
            DataTypes.CollectFeeUsers memory collectFeeUsers,
            uint256 projectId,
            address derivativeNFT,
            uint256 tokenId,
            uint256 payValue
    )
        private
        view
        returns (
            DataTypes.RoyaltyAmounts memory royaltyAmounts,
            DataTypes.Market memory market 
        )
    {
        //get realtime bank treasury fee points
        uint16 protocolFeeInBasisPoints;
        (, protocolFeeInBasisPoints) = _getTreasuryData();
            
        (
            uint256 soulBoundTokenId_gengesis,
            uint256 royaltyBasisPoints_gengesis,
            uint256 soulBoundTokenId_previous,
            uint256 royaltyBasisPoints_previous
        ) =  manager.getGenesisAndPreviousInfo(projectId, tokenId);
            
            collectFeeUsers.genesisSoulBoundTokenId = soulBoundTokenId_gengesis;
            collectFeeUsers.previousSoulBoundTokenId = soulBoundTokenId_previous;

            // calculate fees
            royaltyAmounts.treasuryAmount = payValue.mul(protocolFeeInBasisPoints).div(BASIS_POINTS);

            if (collectFeeUsers.referrerSoulBoundTokenId != 0 && 
                collectFeeUsers.referrerSoulBoundTokenId != collectFeeUsers.ownershipSoulBoundTokenId &&
                collectFeeUsers.referrerSoulBoundTokenId != collectFeeUsers.collectorSoulBoundTokenId &&
                protocolFeeInBasisPoints > 0 &&
                protocolFeeInBasisPoints < BUY_REFERRER_FEE_DENOMINATOR) {           
                //1%
                royaltyAmounts.referrerAmount = payValue.mul(BUY_REFERRER_FEE_DENOMINATOR).div(BASIS_POINTS);
                royaltyAmounts.treasuryAmount -= royaltyAmounts.referrerAmount; 
            }

            market = _getMarketInfo(derivativeNFT);
            if (market.feeShareType == DataTypes.FeeShareType.LEVEL_TWO) {
                royaltyAmounts.genesisAmount = payValue.mul(royaltyBasisPoints_gengesis).div(BASIS_POINTS);
                royaltyAmounts.previousAmount = payValue.mul(royaltyBasisPoints_previous).div(BASIS_POINTS);

                if (market.feePayType == DataTypes.FeePayType.BUYER_PAY) {
                    royaltyAmounts.adjustedAmount = payValue - royaltyAmounts.genesisAmount - royaltyAmounts.previousAmount;
                } else {
                    royaltyAmounts.adjustedAmount = payValue - royaltyAmounts.treasuryAmount - royaltyAmounts.referrerAmount - royaltyAmounts.genesisAmount - royaltyAmounts.previousAmount;
                }

            } else if (market.feeShareType == DataTypes.FeeShareType.LEVEL_FIVE) {
                royaltyAmounts.genesisAmount = payValue.mul(market.royaltyBasisPoints).div(BASIS_POINTS);
                royaltyAmounts.previousAmount = 0;
                
                if (market.feePayType == DataTypes.FeePayType.BUYER_PAY) {
                    royaltyAmounts.adjustedAmount = payValue - royaltyAmounts.genesisAmount;
                } else {
                    royaltyAmounts.adjustedAmount = payValue - royaltyAmounts.treasuryAmount - royaltyAmounts.referrerAmount - royaltyAmounts.genesisAmount;
                }
            }
    }


    /**
     * @notice Try to use bidder in teasury SBT balance to pay first.
     * @dev Transfer SBT value to treasury if revenueAmounts is not enough for.
     * This helper should not be used anywhere that may lead to locked assets.
     * @param soulBoundTokenIdBidder The SBT id of bidder
     * @param amount The amount(price) to place bid.
     */
    // solhint-disable-next-line code-complexity
    function _tryUseEarnestMoneyForPay(
        uint256 soulBoundTokenIdBidder,
        uint256 amount
    ) internal {
        treasury.useEarnestMoneyForPay(
            soulBoundTokenIdBidder,
            amount
        );
    }

}