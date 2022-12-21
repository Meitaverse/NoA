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
import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 *
 * @param amount The total supply with this publication.
 * @param price The collecting cost associated with this publication.
 * @param currency The currency associated with this publication.
 * @param toSoulBoundTokenId The toSoulBoundTokenId associated with this publication.
 * @param genesisBPS The genesis BPS associated with this publication.
 */
struct ProfilePublicationData {
    uint256 tokenId;      //发行对应的tokenId
    uint256 amount;      //发行总量
    uint256 price;       //发行单价
    address currency;    //计价的ERC20，0地址为NDPT
    uint256 ownerSoulBoundTokenId; //发行人的灵魂币ID
    uint16 genesisBPS; //创世NFT版税点数，最多90%，以后每个衍生NFT都需要支付
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
        uint256 ownerSoulBoundTokenId,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data 
    ) external override onlyManager returns (bytes memory) {
        //解码出费率的相关传参
        (uint16 genesisBPS, address currency, uint256 price, bool followerOnly) = abi.decode(
            data,
            (uint16, address, uint256, bool)
        );
        if (currency == address(0)) {
            currency= _ndpt();
        } 

        if (!_currencyWhitelisted(currency) || ownerSoulBoundTokenId == 0 || genesisBPS > BPS_MAX - 1000 || amount == 0)
            revert Errors.InitParamsInvalid();

        //Save 
        _dataByPublicationByProfile[publishId].tokenId = tokenId;
        _dataByPublicationByProfile[publishId].amount = amount;
        _dataByPublicationByProfile[publishId].price = price;
        _dataByPublicationByProfile[publishId].currency = currency;
        _dataByPublicationByProfile[publishId].ownerSoulBoundTokenId = ownerSoulBoundTokenId;
        _dataByPublicationByProfile[publishId].genesisBPS = genesisBPS;
        _dataByPublicationByProfile[publishId].followerOnly = followerOnly;


        return data;
    }

    /**
     * @dev Processes a collect by:
     *  1.  will pay royalty to ownerSoulBoundTokenId
     *  2. Charging a fee
     *  3. TODO: pay to genesis publisher
     */
    function processCollect(
        uint256 ownerSoulBoundTokenId,
        uint256 collectorSoulBoundTokenId,
        uint256 publishId,
        uint256 collectValue
    ) external virtual override onlyManager {
        _processCollect(ownerSoulBoundTokenId, collectorSoulBoundTokenId, publishId, collectValue);
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
        uint256 ownerSoulBoundTokenId,
        uint256 collectorSoulBoundTokenId,
        uint256 projectId, 
        uint256 collectValue
    ) internal {
        uint256 amountOfAll = collectValue.mul(_dataByPublicationByProfile[projectId].amount);
        address currency = _dataByPublicationByProfile[projectId].currency;

        //获取交易税点
        (address treasury, uint16 treasuryFee) = _treasuryData();
        uint256 treasuryAmount = amountOfAll.mul(treasuryFee).div(BPS_MAX);
        uint256 adjustedAmount = amountOfAll.sub(treasuryAmount);

        if (currency == _ndpt()) {
            IERC3525(_ndpt()).transferFrom(_tokenIdOfIncubator(collectorSoulBoundTokenId), _tokenIdOfIncubator(ownerSoulBoundTokenId), adjustedAmount);
            
            uint256 treasuryOfSoulBoundTokenId = IBankTreasury(treasury).getSoulBoundTokenId();
            IERC3525(_ndpt()).transferFrom(_tokenIdOfIncubator(collectorSoulBoundTokenId), treasuryOfSoulBoundTokenId, treasuryAmount);

        } else {
            //向owner支付剩余的currency
            IERC20Upgradeable(currency).safeTransferFrom(_incubator(collectorSoulBoundTokenId), _incubator(ownerSoulBoundTokenId), adjustedAmount);

            //支付给金库
            if (treasuryAmount > 0) IERC20Upgradeable(currency).safeTransferFrom(_incubator(collectorSoulBoundTokenId), treasury, treasuryAmount);

        }
    }
}
