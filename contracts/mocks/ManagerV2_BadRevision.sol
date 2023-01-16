// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "../interfaces/IDerivativeNFTV1.sol";
import "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import "../interfaces/IManagerV2.sol";
import "../base/NFTDerivativeProtocolMultiState.sol";
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
    NFTDerivativeProtocolMultiState,
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


    function mintSBTValue(uint256 soulBoundTokenId, uint256 value) external whenNotPaused onlyGov {
        INFTDerivativeProtocolTokenV1(SBT).mintValue(soulBoundTokenId, value);
    }

    function burnSBT(uint256 tokenId) external whenNotPaused onlyGov {
        INFTDerivativeProtocolTokenV1(SBT).burn(tokenId);
    }

    // function burnSBTValue(uint256 tokenId, uint256 value) external whenNotPaused onlyGov {
    //     INFTDerivativeProtocolTokenV1(SBT).burnValue(tokenId, value);
    // }

    function createProfile(
        DataTypes.CreateProfileData calldata vars
    ) external returns (uint256) {
        if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistProfileCreator(vars.wallet)) revert Errors.ProfileCreatorNotWhitelisted();
        uint256 soulBoundTokenId = INFTDerivativeProtocolTokenV1(SBT).createProfile(msg.sender, vars);
        return soulBoundTokenId;
    }


    function createHub(
        DataTypes.HubData memory hub
    ) external whenNotPaused onlyGov {
        uint256 hubId = _generateNextHubId();
        _hubIdBySoulBoundTokenId[hub.soulBoundTokenId] = hubId;
        InteractionLogic.createHub(
             msg.sender,
             hubId, 
             hub, 
             _hubInfos
        );
    } 

    function createProject(
        DataTypes.ProjectData memory project
    ) external whenNotPaused  returns (uint256) {
        if (_hubIdBySoulBoundTokenId[project.soulBoundTokenId] != project.hubId) revert Errors.NotHubOwner();
        if (_projectNameHashByEventId[keccak256(bytes(project.name))] > 0) {
            revert Errors.ProjectExisted();
        }

        uint256 projectId = _generateNextProjectId();
        _projectNameHashByEventId[keccak256(bytes(project.name))] = projectId;
        InteractionLogic.createProject(
            _DNFT_IMPL,
            SBT,
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
        // if ( _hubIdBySoulBoundTokenId[publication.soulBoundTokenId] == publication.hubId) {
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
