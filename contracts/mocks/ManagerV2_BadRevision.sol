// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "../interfaces/IDerivativeNFTV1.sol";
import "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import "../interfaces/IManagerV2.sol";
import "../base/DerivativeNFTMultiState.sol";
import {DataTypes} from '../libraries/DataTypes.sol';
import {Events} from"../libraries/Events.sol";
import {InteractionLogic} from '../libraries/InteractionLogic.sol';
import {PublishLogic} from '../libraries/PublishLogic.sol';
import {PriceManager} from '../libraries/PriceManager.sol';
import {MockManagerV2Storage} from  "./MockManagerV2Storage.sol";
import {IModuleGlobals} from "../interfaces/IModuleGlobals.sol";

import "../libraries/SafeMathUpgradeable128.sol";

import {VersionedInitializable} from '../upgradeability/VersionedInitializable.sol';

contract ManagerV2_BadRevision is
    IManagerV2,
    DerivativeNFTMultiState,
    MockManagerV2Storage,
    PriceManager,
    VersionedInitializable
{
    // using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable128 for uint128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint256 internal constant REVISION = 1;

    using Counters for Counters.Counter;
    address internal  _RECEIVER;
    address internal  _DNFT_IMPL;

    


    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }


    //-- external -- //


    function setAdditionalValue(uint256 newValue) external {
        _additionalValue = newValue;
    }

    function getAdditionalValue() external view returns (uint256) {
        return _additionalValue;
    }


    function getReceiver() external view returns (address) {
        return _RECEIVER;
    }


    function mintNDPTValue(uint256 tokenId, uint256 value) external whenNotPaused onlyGov {
        INFTDerivativeProtocolTokenV1(NDPT).mintValue(tokenId, value);
    }

    function burnNDPT(uint256 tokenId) external whenNotPaused onlyGov {
        INFTDerivativeProtocolTokenV1(NDPT).burn(tokenId);
    }

    function burnNDPTValue(uint256 tokenId, uint256 value) external whenNotPaused onlyGov {
        INFTDerivativeProtocolTokenV1(NDPT).burnValue(tokenId, value);
    }

    function createProfile(
        DataTypes.CreateProfileData calldata vars
    ) external returns (uint256) {
        if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistProfileCreator(vars.to)) revert Errors.ProfileCreatorNotWhitelisted();
        uint256 soulBoundTokenId = INFTDerivativeProtocolTokenV1(NDPT).createProfile(vars);
        return soulBoundTokenId;
    }

    function createHub(
        DataTypes.HubData memory hub
    ) external whenNotPaused onlyGov {
        uint256 hubId = _generateNextHubId();
        _hubBySoulBoundTokenId[hub.soulBoundTokenId] = hubId;
        InteractionLogic.createHub(
             hubId, 
             hub, 
             _hubInfos
        );
    } 

    function createProject(
        DataTypes.ProjectData memory project
    ) external whenNotPaused  returns (uint256) {
        if (_hubBySoulBoundTokenId[project.soulBoundTokenId] != project.hubId) revert Errors.NotHubOwner();
        if (_projectNameHashByEventId[keccak256(bytes(project.name))] > 0) {
            revert Errors.ProjectExisted();
        }

        uint256 projectId = _generateNextProjectId();
        _projectNameHashByEventId[keccak256(bytes(project.name))] = projectId;
        address derivativeNFT = InteractionLogic.createProject(
            _DNFT_IMPL,
            NDPT,
            TREASURY,
            projectId,
            project,
            _RECEIVER,
            _derivativeNFTByProjectId
        );
        

        _projectInfoByProjectId[projectId] = DataTypes.ProjectData({
            hubId: project.hubId,
            soulBoundTokenId: project.soulBoundTokenId,
            name: project.name,
            description: project.description,
            image: project.image,
            metadataURI: project.metadataURI,
            descriptor: project.descriptor,
            defaultRoyaltyPoints: project.defaultRoyaltyPoints,
            feeShareType: project.feeShareType
        });
        return projectId;
    }

    function getProjectInfo(uint256 projectId_) external view returns (DataTypes.ProjectData memory) {

        return _projectInfoByProjectId[projectId_];
    }

    function publish(
        uint256  publishId,
        DataTypes.Publication memory publication
    ) external whenNotPaused returns (uint256) {
        // bool isHubOwner;
        // address derivatveNFT = _derivativeNFTByProjectId[publication.projectId];
        // if (derivatveNFT == address(0)) revert Errors.InvalidParameter();
        // if ( _hubBySoulBoundTokenId[publication.soulBoundTokenId] == publication.hubId) {
        //     isHubOwner = true;
        // }
        // return PublishLogic.publish(projectId, publication, derivatveNFT, soulBoundTokenId, amount, publishModule, publishModuleInitData, isHubOwner);
    }

    function collect(
        uint256 projectId,
        address collector,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata collectModuledata
    ) external whenNotPaused {
        // address derivatveNFT = _derivativeNFTByProjectId[projectId];
        // if (derivatveNFT == address(0)) revert Errors.InvalidParameter();

        // return
        //     PublishLogic.collectDerivativeNFT(
        //         projectId,
        //         derivatveNFT,
        //         collector,
        //         fromSoulBoundTokenId,
        //         toSoulBoundTokenId,
        //         tokenId,
        //         value,
        //         collectModuledata,
        //         _pubByIdByProfile
            // );
    }

    function airdrop(
        uint256 hubId,
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256[] memory toSoulBoundTokenIds,
        uint256 tokenId,
        uint256[] memory values
    ) external whenNotPaused {
         
    }

    function transferDerivativeNFT(
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        bytes calldata transferModuledata
    ) external whenNotPaused {

       
    }

    function transferValueDerivativeNFT(
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata transferValueModuledata
    ) external whenNotPaused {
    
    }

    function publishFixedPrice(DataTypes.Sale memory sale) external whenNotPaused onlyGov {
        uint24 saleId = _generateNextSaleId();
        _derivativeNFTSales[sale.derivativeNFT].add(saleId);
        PriceManager.setFixedPrice(saleId, sale.price);
        InteractionLogic.publishFixedPrice(sale, markets, sales);
    }

    function removeSale(uint24 saleId_) external whenNotPaused onlyGov {
        InteractionLogic.removeSale(saleId_, sales);
    }

    function addMarket(
        address derivativeNFT_,
        uint64 precision_,
        uint8 feePayType_,
        uint8 feeType_,
        uint128 feeAmount_,
        uint16 feeRate_
    ) external whenNotPaused onlyGov {
        InteractionLogic.addMarket(derivativeNFT_, precision_, feePayType_, feeType_, feeAmount_, feeRate_, markets);
    }

    function removeMarket(address derivativeNFT_) external whenNotPaused onlyGov {
        InteractionLogic.removeMarket(derivativeNFT_, markets);
    }

    function buyUnits(
        uint256 soulBoundTokenId,
        address buyer,
        uint24 saleId,
        uint128 units
    ) external payable whenNotPaused returns (uint256 amount, uint128 fee) {
        if (sales[saleId].max > 0) {
            require(saleRecords[sales[saleId].saleId][buyer].add(units) <= sales[saleId].max, "exceeds purchase limit");
            saleRecords[sales[saleId].saleId][buyer] = saleRecords[sales[saleId].saleId][buyer].add(units);
        }

        if (sales[saleId].useAllowList) {
            require(_allowAddresses[sales[saleId].derivativeNFT].contains(buyer), "not in allow list");
        }
        return
            InteractionLogic.buyByUnits(
                _generateNextTradeId(),
                buyer,
                saleId,
                PriceManager.price(DataTypes.PriceType.FIXED, saleId),
                units,
                markets,
                sales
            );
    }

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    function setEmergencyAdmin(address newEmergencyAdmin) external override onlyGov {
        address prevEmergencyAdmin = _emergencyAdmin;
        _emergencyAdmin = newEmergencyAdmin;
        emit Events.EmergencyAdminSet(msg.sender, prevEmergencyAdmin, newEmergencyAdmin, block.timestamp);
    }

    function setState(DataTypes.ProtocolState newState) external override {
        if (msg.sender == _emergencyAdmin) {
            if (newState == DataTypes.ProtocolState.Unpaused) revert Errors.EmergencyAdminCannotUnpause();
            _validateNotPaused();
        } else if (msg.sender != _governance) {
            revert Errors.NotGovernanceOrEmergencyAdmin();
        }
        _setState(newState);
    }

    function getGovernance() external view returns(address) {
        return _governance;
    }
    
    //--- internal  ---//
    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }


    function _generateNextSaleId() internal returns (uint24) {
        _nextSaleId.increment();
        return uint24(_nextSaleId.current());
    }

    function _generateNextTradeId() internal returns (uint24) {
        _nextTradeId.increment();
        return uint24(_nextTradeId.current());
    }

    function _generateNextHubId() internal returns (uint256) {
        _nextHubId.increment();
        return uint24(_nextHubId.current());
    }

    function _generateNextProjectId() internal returns (uint256) {
        _nextProjectId.increment();
        return uint24(_nextProjectId.current());
    }

    function version() public pure returns(uint256) {
        return REVISION;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
