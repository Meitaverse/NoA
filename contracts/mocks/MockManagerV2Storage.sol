// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title MockManagerV2Storage
 * @author Bitsoul Protocol
 *
 * @notice This is an abstract contract that *only* contains storage for the Manager contract. This
 * *must* be inherited last (bar interfaces) in order to preserve the Manager storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract MockManagerV2Storage {
    bytes32 internal constant EIP712_REVISION_HASH = keccak256('1');
    bytes32 internal constant SET_DISPATCHER_WITH_SIG_TYPEHASH =
        keccak256(
            'SetDispatcherWithSig(uint256 profileId,address dispatcher,uint256 nonce,uint256 deadline)'
        );

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        );

    mapping(uint256 => DataTypes.HubInfoData) internal _hubInfos;
    mapping(uint256 => uint256) internal _hubIdBySoulBoundTokenId;
    mapping(bytes32 => uint256) internal _projectNameHashByEventId; //用于判断project name是否重复
    mapping(uint256 => DataTypes.ProjectData) internal _projectInfoByProjectId;
    mapping(uint256 => address) internal _derivativeNFTByProjectId;
    mapping(uint256 => address) internal _soulBoundTokenIdToWallet;
    mapping(uint256 => address) internal _dispatcherByProfile;
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) internal _pubByIdByProfile;
    mapping(uint256 => uint256) internal _genesisPublishIdByProjectId;

    //publishId => publishData
    mapping(uint256 => DataTypes.PublishData) internal _projectDataByPublishId;
    
    //tokenId => publishId
    mapping(uint256 => uint256) internal _tokenIdByPublishId;

    address public  SBT;
    address public  TREASURY;
    address public MODULE_GLOBALS;

    uint256 internal _profileCounter;
    address internal _soulBoundToken;
    address internal _emergencyAdmin;
    address internal _governance;

    
    Counters.Counter internal _nextTradeId;
    Counters.Counter internal _nextHubId;
    Counters.Counter internal _nextProjectId;
    Counters.Counter internal _nextPublishId;
    
    string internal _svgLogo;

    // --- market place --- //

    // derivativeNFT => Market
    mapping(address => DataTypes.Market) internal markets;

    //MultiRecipient

    uint256 internal _additionalValue;
  
}
