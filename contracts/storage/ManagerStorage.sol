// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title ManagerStorage
 * @author Bitsoul Protocol
 *
 * @notice This is an abstract contract that *only* contains storage for the Manager contract. This
 * *must* be inherited last (bar interfaces) in order to preserve the Manager storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract ManagerStorage {
    bytes32 internal constant EIP712_REVISION_HASH = keccak256('1');
    bytes32 internal constant SET_DISPATCHER_WITH_SIG_TYPEHASH =
        keccak256(
            'SetDispatcherWithSig(uint256 soulBoundTokenId,address dispatcher,uint256 nonce,uint256 deadline)'
        );

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        );

    
    // hubId => HubData
    mapping(uint256 => DataTypes.HubInfoData) internal _hubInfos;

    //soulBoundTokenId => hub
    mapping(uint256 => uint256) internal _hubIdBySoulBoundTokenId;

    //check project name is duplicate
    mapping(bytes32 => uint256) internal _projectNameHashByEventId; 

    //derivariveNFT address  => SoulBoundTokenId
    mapping(address => uint256) internal _derivariveNFTToSoulBoundTokenId;

    //projectId => projectInfo
    mapping(uint256 => DataTypes.ProjectData) internal _projectInfoByProjectId;

    mapping(uint256 => bool) internal _isHubOwnerPermitBypublishId;

    //projectId => derivativeNFT
    mapping(uint256 => address) internal _derivativeNFTByProjectId;

    //soulBoundTokenId => wallet
    mapping(uint256 => address) internal _soulBoundTokenIdToWallet;
    
    // wallet address => soulBoundTokenId
    mapping(address => uint256) internal _walletToSoulBoundTokenId;

    //derivativeNFT => projectId
    mapping(address => uint256) internal _projectIdToderivativeNFT;

    mapping(uint256 => address) internal _dispatcherByProfile;

    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) internal _pubByIdByProfile;

    //publication Name is exists
    mapping(bytes32 => bool) internal _publicationNameHashExists;


    //projectId => publishId
    mapping(uint256 => uint256) internal _genesisPublishIdByProjectId;

    //publishId => publishData
    mapping(uint256 => DataTypes.PublishData) internal _projectDataByPublishId;

    address internal MODULE_GLOBALS;
    address internal _governance;
    address internal _timeLock; //TimeLock address

    uint256 internal _profileCounter;
    address internal _soulBoundToken;
    address internal _emergencyAdmin;
    address internal _owner;

    Counters.Counter internal _nextHubId;
    Counters.Counter internal _nextProjectId;
    Counters.Counter internal _nextPublishId;
    
    string internal _svgLogo;

}
