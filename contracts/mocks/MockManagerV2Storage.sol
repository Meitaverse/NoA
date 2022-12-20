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
abstract contract MockManagerV2Storage {
    mapping(uint256 => address) internal _profileOwners;
    mapping(address => bool) internal _profileCreatorWhitelisted;
    mapping(address => bool) internal _followModuleWhitelisted;
    mapping(address => bool) internal _collectModuleWhitelisted;
    mapping(address => bool) internal _referenceModuleWhitelisted;

    mapping(uint256 => DataTypes.Hub) internal _hubInfos;
    mapping(uint256 => uint256) internal _hubBySoulBoundTokenId;
    mapping(bytes32 => uint256) internal _projectNameHashByEventId;
    mapping(uint256 => DataTypes.Project) internal _projectInfoByProjectId;
    mapping(uint256 => address) internal _derivativeNFTByProjectId;
    mapping(uint256 => address) internal _incubatorBySoulBoundTokenId;
    
   
    mapping(bytes32 => uint256) internal _profileIdByHandleHash;
    mapping(uint256 => DataTypes.ProfileStruct) internal _profileById;

    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) internal _pubByIdByProfile;

    mapping(address => uint256) internal _defaultProfileByAddress;

    address internal  _INCUBATOR_IMPL;
    address internal  _DNFT_IMPL;
    address internal  _RECEIVER;

    uint256 internal _profileCounter;
    address internal _soulBoundToken;
    address internal _emergencyAdmin;
    address internal _governance;

    address public  NDPT;

    Counters.Counter internal _nextSaleId;
    Counters.Counter internal _nextTradeId;
    Counters.Counter internal _nextHubId;
    Counters.Counter internal _nextProjectId;
    
    string internal _svgLogo;

    // --- market place --- //

    // derivativeNFT => Market
    mapping(address => DataTypes.Market) internal markets;

    //saleId => struct Sale
    mapping(uint24 => DataTypes.Sale) internal sales;
    
    // records of user purchased units from an order
    mapping(uint24 => mapping(address => uint128)) internal saleRecords;

    //derivativeNFT => saleId
    mapping(address => EnumerableSetUpgradeable.UintSet) internal _derivativeNFTSales;
    mapping(address => EnumerableSetUpgradeable.AddressSet) internal _allowAddresses;

//V2
    uint256 internal _additionalValue;
}
