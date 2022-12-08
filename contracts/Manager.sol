// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IDerivativeNFTV1.sol";
import "./interfaces/INFTDerivativeProtocolTokenV1.sol";
import "./interfaces/IManager.sol";
import "./interfaces/ISoulBoundTokenV1.sol";
import "./base/NoAMultiState.sol";
import {DataTypes} from './libraries/DataTypes.sol';
import {Events} from"./libraries/Events.sol";
import {InteractionLogic} from './libraries/InteractionLogic.sol';
import {ManagerStorage} from  "./storage/ManagerStorage.sol";

contract Manager is
    Initializable,
    IManager,
    ContextUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    NoAMultiState,
    ManagerStorage,
    UUPSUpgradeable
{
    uint256 internal constant REVISION = 1;
    address internal immutable INCUBATOR_IMPL;
    address internal immutable DNFT_IMPL;
    address public immutable NDPT;
    address public immutable SOULBOUNDTOKEN;

    bytes32 internal constant _PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 internal constant _UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    bytes32 private constant _MINT_SBT_TYPEHASH =
        keccak256("MintSBT(string nickName,string role,address to,uint256 value)");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address ndptV1_, 
        address soulBoundTokenV1_, //ISoulBoundTokenV1
        address noAV1_, //IDerivativeNFTV1
        address incubator_
    ) initializer {
        NDPT = ndptV1_;
        SOULBOUNDTOKEN = soulBoundTokenV1_;
        INCUBATOR_IMPL = incubator_;
        DNFT_IMPL = noAV1_;
    }

    function initialize() public initializer {
        __Context_init();
        __Ownable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(_UPGRADER_ROLE, _msgSender());
        _grantRole(_PAUSER_ROLE, _msgSender());

        _setState(DataTypes.ProtocolState.Unpaused);
    }

    //-- external -- //
    function mintNDPTBySig(
        address mintTo, uint256 tokenId, uint256 slot, uint256 value,
        uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused returns(uint256) {
        //TODO
    }

    function mintNDPTValueBySig(
        uint256 tokenId, uint256 value,
        uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused {
        //TODO
    }

    function burnNDPTBySig(
        uint256 tokenId,
         uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused {
        //TODO
    }

    function burnNDPTValueBySig(
        uint256 tokenId,
        uint256 value,
         uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused {
        //TODO
    }

    function createSoulBoundTokenBySig(
        DataTypes.CreateProfileData calldata vars,
        string memory nickName,
        uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused returns (uint256) {
        //TODO
        return ISoulBoundTokenV1(SOULBOUNDTOKEN).mint(vars, nickName);
    }

    function createSoulBoundToken(DataTypes.CreateProfileData calldata vars, string memory nickName) external whenNotPaused returns (uint256) {
        return ISoulBoundTokenV1(SOULBOUNDTOKEN).mint(vars, nickName);
    }

    function createEvent(
        uint256 soulBoundTokenId,
        string memory name,
        string memory description,
        bytes calldata derivativeNFTModuleData,
        bytes calldata collectModuleData
    ) external whenNotPaused returns (uint256) {
      return  InteractionLogic.createEvent(
           soulBoundTokenId, name, description,
           derivativeNFTModuleData, collectModuleData,
           _derivativeNFTBySoulBoundTokenId
        );
    }

    //-- orverride -- //
    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        require(hasRole(_UPGRADER_ROLE, _msgSender()), "ERR: Unauthorized");
    }

    /// ***************************************
    /// *****PROFILE INTERACTION FUNCTIONS*****
    /// ***************************************

    function follow(
        uint256[] calldata soulBoundTokenIds,
        bytes[] calldata datas
    ) external override whenNotPaused  {
        InteractionLogic.follow(msg.sender, soulBoundTokenIds, datas, _profileById, _profileIdByHandleHash);
    }

    function getFollowModule(uint256 soulBoundTokenId) external view override returns (address) {
        return _profileById[soulBoundTokenId].followModule;
    }

    function getSoulBoundToken() external view returns (address) {
        return SOULBOUNDTOKEN;
    }

    function getIncubatorOfSoulBoundTokenId(uint256 soulBoundTokenId) external view override returns (address) {
        return _incubatorBySoulBoundTokenId[soulBoundTokenId];
    }

    function getIncubatorImpl() external view override returns (address) {
        return INCUBATOR_IMPL;
    }

    function getDNFTImpl() external view override returns (address) {
        return DNFT_IMPL;
    }


}