// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
// import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
// import "../libraries/SafeMathUpgradeable128.sol";
import {IManager} from "../interfaces/IManager.sol";
import {IBankTreasury} from '../interfaces/IBankTreasury.sol';
import {INFTDerivativeProtocolTokenV1} from "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import {Events} from "../libraries/Events.sol";
import {Errors} from "../libraries/Errors.sol";
import {DataTypes} from '../libraries/DataTypes.sol';
import "../libraries/Constants.sol";
import "./DNFTMarketCore.sol";
import "./MarketSharedCore.sol";

abstract contract MarketFees is  MarketSharedCore, DNFTMarketCore {
    // using AddressUpgradeable for address;
    // using SafeMathUpgradeable for uint256;
    // using SafeMathUpgradeable128 for uint128;
    // using ArrayLibrary for uint256[]; 
/*
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
*/
    /**
     * @notice Distributes funds to foundation, creator recipients, buy referrer and DNFT owner after a sale.
     */
    /*
    function _distributeFunds(
        DataTypes.CollectFeeUsers memory collectFeeUsers,
        uint256 projectId,
        address derivativeNFT,
        uint256 tokenId,
        uint96 payValue
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
            //Transfer SBT Value = payValue + treasuryAmount
            payValue = payValue + royaltyAmounts.treasuryAmount;
        }

        treasury.saveFundsToUserRevenue(
            collectFeeUsers.collectorSoulBoundTokenId,
            payValue,
            collectFeeUsers,
            royaltyAmounts
        );

    }
    */

    //  /**
    //  * @notice Returns how funds will be distributed for a sale at the given price point.
    //  * @param soulBoundTokenId The soulBoundTokenId of owner 
    //  * @param projectId The project id
    //  * @param derivativeNFT The address of the DNFT contract.
    //  * @param tokenId The id of the DNFT.
    //  * @param amount The units * price
    //  * @return treasuryFee How much will be sent to the Foundation treasury and/or referrals.
    //  * @return creatorRev How much will be sent across all the genesis creator defined.
    //  * @return previousCreatorRev How much will be sent across all the previous creator defined.
    //  * @return sellerRev How much will be sent to the owner/seller of the DNFT.
    //  * If the DNFT is being sold by the creator, this may be 0 and the full revenue will appear as `creatorRev`.
    //  * @return seller The address of the owner of the DNFT.
    //  * If `sellerRev` is 0, this may be `address(0)`.
    //  */
    // function getFeesAndRecipients(
    //     uint256 soulBoundTokenId,
    //     uint256 projectId,
    //     address derivativeNFT,
    //     uint256 tokenId,
    //     uint96 amount 
    // )
    //     external
    //     view
    //     returns (
    //         uint256 treasuryFee,
    //         uint256 creatorRev,
    //         uint256 previousCreatorRev,
    //         uint256 sellerRev,
    //         address payable seller
    //     )
    // {

    //     DataTypes.CollectFeeUsers memory collectFeeUsers =  DataTypes.CollectFeeUsers({
    //             ownershipSoulBoundTokenId: soulBoundTokenId,
    //             collectorSoulBoundTokenId: manager.getSoulBoundTokenIdByWallet(msg.sender),
    //             genesisSoulBoundTokenId: 0,
    //             previousSoulBoundTokenId: 0,
    //             referrerSoulBoundTokenId: 0
    //     });        

    //     seller = _getSellerOrOwnerOf(derivativeNFT, tokenId);

    //     (DataTypes.RoyaltyAmounts memory royaltyAmounts,  ) = _getFees(
    //         collectFeeUsers,
    //         projectId,
    //         derivativeNFT,
    //         tokenId,
    //         amount
    //     );

    //    treasuryFee = royaltyAmounts.treasuryAmount;
    //    creatorRev = royaltyAmounts.genesisAmount;
    //    previousCreatorRev = royaltyAmounts.previousAmount;
    //    sellerRev = royaltyAmounts.adjustedAmount;
    // }

    /**
     * @notice Calculates how funds should be distributed for the given sale details.
     * @dev When the DNFT is being sold by the `tokenCreator`, all the seller revenue will
     * be split with the royalty recipients defined for that DNFT.
     */
    // solhint-disable-next-line code-complexity
    /*
    function _getFees(
            DataTypes.CollectFeeUsers memory collectFeeUsers,
            uint256 projectId,
            address derivativeNFT,
            uint256 tokenId,
            uint96 payValue
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
            uint256 royaltyBasisPoint_gengesis,
            uint256 soulBoundTokenId_previous,
            uint256 royaltyBasisPoint_previous
        ) =  manager.getGenesisAndPreviousInfo(projectId, tokenId);
            
            collectFeeUsers.genesisSoulBoundTokenId = soulBoundTokenId_gengesis;
            collectFeeUsers.previousSoulBoundTokenId = soulBoundTokenId_previous;

        unchecked {

            // calculate fees
            royaltyAmounts.treasuryAmount = uint96(payValue * protocolFeeInBasisPoints / BASIS_POINTS);

            if (collectFeeUsers.referrerSoulBoundTokenId != 0 && 
                collectFeeUsers.referrerSoulBoundTokenId != collectFeeUsers.ownershipSoulBoundTokenId &&
                collectFeeUsers.referrerSoulBoundTokenId != collectFeeUsers.collectorSoulBoundTokenId &&
                protocolFeeInBasisPoints > 0 &&
                protocolFeeInBasisPoints < BUY_REFERRER_FEE_DENOMINATOR) {           
                //1%
                royaltyAmounts.referrerAmount = uint96(payValue * BUY_REFERRER_FEE_DENOMINATOR / BASIS_POINTS);
                royaltyAmounts.treasuryAmount -= royaltyAmounts.referrerAmount; 
            }

            market = _getMarketInfo(derivativeNFT);
            if (market.feeShareType == DataTypes.FeeShareType.LEVEL_TWO) {
                royaltyAmounts.genesisAmount = uint96(payValue * royaltyBasisPoint_gengesis / BASIS_POINTS);
                royaltyAmounts.previousAmount = uint96(payValue * royaltyBasisPoint_previous / BASIS_POINTS);

                if (market.feePayType == DataTypes.FeePayType.BUYER_PAY) {
                    royaltyAmounts.adjustedAmount = payValue - royaltyAmounts.genesisAmount - royaltyAmounts.previousAmount;
                } else {
                    royaltyAmounts.adjustedAmount = payValue - royaltyAmounts.treasuryAmount - royaltyAmounts.referrerAmount - royaltyAmounts.genesisAmount - royaltyAmounts.previousAmount;
                }

            } else if (market.feeShareType == DataTypes.FeeShareType.LEVEL_FIVE) {
                royaltyAmounts.genesisAmount =  uint96(payValue * market.royaltySharesPoints / BASIS_POINTS);
                royaltyAmounts.previousAmount = 0;
                
                if (market.feePayType == DataTypes.FeePayType.BUYER_PAY) {
                    royaltyAmounts.adjustedAmount = payValue - royaltyAmounts.genesisAmount;
                } else {
                    royaltyAmounts.adjustedAmount = payValue - royaltyAmounts.treasuryAmount - royaltyAmounts.referrerAmount - royaltyAmounts.genesisAmount;
                }
            }
        }
    }
    */




}