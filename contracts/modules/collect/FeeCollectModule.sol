// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ICollectModule} from "../../interfaces/ICollectModule.sol";
import {IBankTreasury} from "../../interfaces/IBankTreasury.sol";
import {Errors} from "../../libraries/Errors.sol";
import {FeeModuleBase} from "../FeeModuleBase.sol";
import {ModuleBase} from "../ModuleBase.sol";
import {FollowValidationModuleBase} from "../FollowValidationModuleBase.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {INFTDerivativeProtocolTokenV1} from "../../interfaces/INFTDerivativeProtocolTokenV1.sol";

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 *
 * @param genesisSoulBoundTokenId The genesi sSoulBoundTokenId with this publication.
 * @param tokenId The tokenId with this publication.
 * @param amount The total supply with this publication.
 * @param price The collecting cost associated with this publication.
 * @param currency The currency associated with this publication.
 * @param ownershipSoulBoundTokenId The toSoulBoundTokenId associated with this publication.
 * @param genesisFee The percentage of the fee that will be transferred to the genesis soulBoundTokenId of this publication.
 * @param followerOnly Set if follower can collect.
 */
struct ProfilePublicationData {
    uint256 genesisSoulBoundTokenId;       //创世的soulBoundTokenId
    uint256 tokenId;                       //发行对应的tokenId
    uint256 amount;                        //发行总量
    uint256 price;                         //发行单价
    address currency;                      //计价的ERC20，0地址为NDPT
    uint256 ownershipSoulBoundTokenId;         //发行人的灵魂币ID
    uint16 genesisFee;                     //创世NFT版税点数，最多90%，以后每个衍生NFT都需要支付
    bool followerOnly;
}

/**
 * @title FeeCollectModule
 * @author Bitsoul Protocol
 *
 * @notice This is a simple dNFT CollectModule implementation, inheriting from the ICollectModule interface and
 * the FeeCollectModuleBase abstract contract.
 *
 * This module works by allowing unlimited collects for a publication at a given price.
 */
contract FeeCollectModule is FeeModuleBase, FollowValidationModuleBase, ICollectModule {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // publishId => ProfilePublicationData
    mapping(uint256 =>  ProfilePublicationData) internal _dataByPublicationByProfile;

    constructor(address manager, address moduleGlobals) FeeModuleBase(moduleGlobals) ModuleBase(manager) {}

    function initializePublicationCollectModule(
        uint256 publishId,
        uint256 ownershipSoulBoundTokenId,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data 
    ) external override onlyManager returns (bytes memory) {
        //解码出费率的相关传参
        (uint256 genesisSoulBoundTokenId, uint16 genesisFee, address currency, uint256 price, bool followerOnly) = abi.decode(
            data,
            (uint256, uint16, address, uint256, bool)
        );
        if (currency == address(0)) {
            currency= _ndpt();
        } 
       
        if (!_currencyWhitelisted(currency) || 
            publishId == 0 || 
            ownershipSoulBoundTokenId == 0 || 
            genesisFee > BPS_MAX - 1000 || 
            amount == 0)
            revert Errors.InitParamsInvalid();

        //Save 
        _dataByPublicationByProfile[publishId].tokenId = tokenId;
        _dataByPublicationByProfile[publishId].amount = amount;
        _dataByPublicationByProfile[publishId].price = price;
        _dataByPublicationByProfile[publishId].currency = currency;
        _dataByPublicationByProfile[publishId].ownershipSoulBoundTokenId = ownershipSoulBoundTokenId;
        _dataByPublicationByProfile[publishId].genesisSoulBoundTokenId = genesisSoulBoundTokenId;
        _dataByPublicationByProfile[publishId].genesisFee = genesisFee;
        _dataByPublicationByProfile[publishId].followerOnly = followerOnly;

        return data;
    }

    /**
     * @dev Processes a collect by:
     *  1.  will pay royalty to ownershipSoulBoundTokenId
     *  2. Charging a fee
     *  3. TODO: pay to genesis publisher
     */
    function processCollect(
        uint256 ownershipSoulBoundTokenId,
        uint256 collectorSoulBoundTokenId,
        uint256 publishId,
        uint256 collectValue
    ) external virtual override onlyManager {
        _processCollect(
            ownershipSoulBoundTokenId, 
            collectorSoulBoundTokenId, 
            publishId, 
            collectValue
        );
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param publishId The publish ID of the profile mapped to the publication to query.
     *
     * @return ProfilePublicationData The ProfilePublicationData struct mapped to that publication.
     */
    function getPublicationData(
        uint256 publishId
    ) external view returns (ProfilePublicationData memory) {
        return _dataByPublicationByProfile[publishId];
    }

    function _processCollect(
        uint256 ownershipSoulBoundTokenId,
        uint256 collectorSoulBoundTokenId,
        uint256 publishId, 
        uint256 collectValue
    ) internal {
        uint256 amountOfAll = collectValue.mul(_dataByPublicationByProfile[publishId].amount);
        address currency = _dataByPublicationByProfile[publishId].currency;
        uint256 genesisSoulBoundTokenId = _dataByPublicationByProfile[publishId].genesisSoulBoundTokenId;
        
        //获取交易税点
        (address treasury, uint16 treasuryFee) = _treasuryData();
        uint256 treasuryAmount = amountOfAll.mul(treasuryFee).div(BPS_MAX);
        uint256 genesisAmount = amountOfAll.mul(_dataByPublicationByProfile[publishId].genesisFee).div(BPS_MAX);
        uint256 adjustedAmount = amountOfAll.sub(treasuryAmount).sub(genesisAmount);

        if (currency == _ndpt()) {
            if (adjustedAmount>0) 
                INFTDerivativeProtocolTokenV1(_ndpt()).transferValue(collectorSoulBoundTokenId, ownershipSoulBoundTokenId, adjustedAmount);
            
            uint256 treasuryOfSoulBoundTokenId = IBankTreasury(treasury).getSoulBoundTokenId();
            
            if (treasuryAmount > 0) INFTDerivativeProtocolTokenV1(_ndpt()).transferValue(collectorSoulBoundTokenId, treasuryOfSoulBoundTokenId, treasuryAmount);
            if (genesisSoulBoundTokenId >0 && genesisAmount > 0) INFTDerivativeProtocolTokenV1(_ndpt()).transferValue(collectorSoulBoundTokenId, genesisSoulBoundTokenId, genesisAmount);

        } else {
            //向owner支付剩余的currency
            if (adjustedAmount>0) IERC20Upgradeable(currency).safeTransferFrom(_wallet(collectorSoulBoundTokenId), _wallet(ownershipSoulBoundTokenId), adjustedAmount);

            //pay to treasury and genesis publisher
            if (treasuryAmount > 0) IERC20Upgradeable(currency).safeTransferFrom(_wallet(collectorSoulBoundTokenId), treasury, treasuryAmount);
            if (genesisSoulBoundTokenId >0 && genesisAmount > 0) IERC20Upgradeable(currency).safeTransferFrom(_wallet(collectorSoulBoundTokenId), _wallet(genesisSoulBoundTokenId), genesisAmount);
        }
    }
}
