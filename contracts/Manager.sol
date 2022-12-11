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
import {PublishLogic} from './libraries/PublishLogic.sol';
import {ManagerStorage} from  "./storage/ManagerStorage.sol";
// import {VersionedInitializable} from './upgradeability/VersionedInitializable.sol';

contract Manager is
    Initializable,
    IManager,
    ContextUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    NoAMultiState,
    ManagerStorage,
    // VersionedInitializable,
    UUPSUpgradeable
{
    uint256 internal constant _REVISION = 1;
    // solhint-disable-next-line var-name-mixedcase
    address internal immutable _INCUBATOR_IMPL;
    // solhint-disable-next-line var-name-mixedcase
    address internal immutable _DNFT_IMPL;
    // solhint-disable-next-line var-name-mixedcase
    address public immutable NDPT;
    // solhint-disable-next-line var-name-mixedcase
    address public immutable SOULBOUNDTOKEN;

    address internal _governance;
    address internal _receiver;
    

    bytes32 internal constant _PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 internal constant _UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    bytes32 private constant _MINT_SBT_TYPEHASH =
        keccak256("MintSBT(string nickName,string role,address to,uint256 value)");

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address ndptV1_, 
        address soulBoundTokenV1_, 
        address noAV1_, 
        address incubator_
    ) initializer {
        NDPT = ndptV1_;
        SOULBOUNDTOKEN = soulBoundTokenV1_;
        _INCUBATOR_IMPL = incubator_;
        _DNFT_IMPL = noAV1_;
    }

    function initialize(
        address governance_,
        address receiver_
    ) public initializer {
        __Context_init();
        __Ownable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(_UPGRADER_ROLE, _msgSender());
        _grantRole(_PAUSER_ROLE, _msgSender());

        _setState(DataTypes.ProtocolState.Unpaused);

        _governance = governance_;
        _receiver = receiver_;
    }

    //-- orverride -- //
    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        if(!hasRole(_UPGRADER_ROLE, _msgSender())) revert Errors.Unauthorized();
    }

    //-- external -- //
    function getReceiver() external view returns (address) {
        return _receiver;
    }

    function mintNDPT(
        address mintTo, uint256 tokenId, uint256 slot, uint256 value
    ) external whenNotPaused onlyGov {
        INFTDerivativeProtocolTokenV1(NDPT).mint(mintTo, tokenId, slot, value);
        emit Events.MintNDPTBySig(mintTo, tokenId, slot, value, block.timestamp);
    }

    function mintNDPTBySig(
        address mintTo, uint256 tokenId, uint256 slot, uint256 value,
        uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused {
        //TODO
        INFTDerivativeProtocolTokenV1(NDPT).mint(mintTo, tokenId, slot, value);
        emit Events.MintNDPTBySig(mintTo, tokenId, slot, value, block.timestamp);
    }

    function mintNDPTValue(
        uint256 tokenId, uint256 value
    ) external onlyGov {
        INFTDerivativeProtocolTokenV1(NDPT).mintValue(tokenId, value);
        emit Events.MintNDPTValueBySig(tokenId, value, block.timestamp);
    }

    function mintNDPTValueBySig(
        uint256 tokenId, uint256 value,
        uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused {
        //TODO
        INFTDerivativeProtocolTokenV1(NDPT).mintValue(tokenId, value);
        emit Events.MintNDPTValueBySig(tokenId, value, block.timestamp);
    }

    function burnNDPT(
        uint256 tokenId
    ) external onlyGov {
        //TODO
         INFTDerivativeProtocolTokenV1(NDPT).burn(tokenId);
    }

    function burnNDPTBySig(
        uint256 tokenId,
         uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused {
        //TODO
         INFTDerivativeProtocolTokenV1(NDPT).burn(tokenId);
         
    }

    function burnNDPTValue(
        uint256 tokenId,
        uint256 value
    ) external onlyGov{
        //TODO
        INFTDerivativeProtocolTokenV1(NDPT).burnValue(tokenId, value);
    }

    function burnNDPTValueBySig(
        uint256 tokenId,
        uint256 value,
        uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused {
        //TODO
        INFTDerivativeProtocolTokenV1(NDPT).burnValue(tokenId, value);
    }

    function createSoulBoundToken(
        DataTypes.CreateProfileData calldata vars, 
        string memory nickName
    ) external onlyGov returns (uint256) {
        return ISoulBoundTokenV1(SOULBOUNDTOKEN).mint(vars, nickName);
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

    function createEvent(
        uint256 soulBoundTokenId,
        DataTypes.Event memory event_,
        address metadataDescriptor_,
        bytes calldata collectModuleData
    ) external onlyGov returns (uint256) {
      return  InteractionLogic.createEvent(
            soulBoundTokenId,
            event_, 
            metadataDescriptor_,
            collectModuleData,
            _eventNameHashByEventId,
            _derivativeNFTByEventId
        );
    }

    function createEventBySig(
        uint256 soulBoundTokenId,
        DataTypes.Event memory event_,
        address metadataDescriptor_,
        bytes calldata collectModuleData,
        uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused returns (uint256) {
       //TODO
    }

    
    function publish(
        DataTypes.SlotDetail memory slotDetail_,
        uint256 soulBoundTokenId, 
        uint256 amount, 
        bytes[] calldata datas
    ) external onlyGov returns(uint256){
        //TODO
        if (slotDetail_.eventId == 0) revert Errors.InvalidParameter();
        address derivatveNFT = _derivativeNFTByEventId[slotDetail_.eventId];
        if (derivatveNFT== address(0)) revert Errors.InvalidParameter();

        address incubator = _incubatorBySoulBoundTokenId[soulBoundTokenId];
        if (incubator== address(0)) revert Errors.InvalidParameter();

        return PublishLogic.publish(
            slotDetail_,
            derivatveNFT,
            soulBoundTokenId,
            incubator,
            amount, 
            datas 
        );
    }

    function publishBySig(
        DataTypes.SlotDetail memory slotDetail_,
        uint256 soulBoundTokenId, 
        uint256 eventId, 
        uint256 amount, 
        bytes[] calldata datas,
        uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused  {
        //TODO
    }
    
    function combo(
        DataTypes.SlotDetail memory slotDetail_,
        uint256 soulBoundTokenId, 
        uint256[] memory fromTokenIds,
       bytes[] calldata datas
    )  external onlyGov returns(uint256){
        if (slotDetail_.eventId == 0) revert Errors.InvalidParameter();
        address derivatveNFT = _derivativeNFTByEventId[slotDetail_.eventId];
        if (derivatveNFT== address(0)) revert Errors.InvalidParameter();

        return PublishLogic.combo(
            slotDetail_,
            derivatveNFT,
            soulBoundTokenId,
            fromTokenIds,
            datas,
            _incubatorBySoulBoundTokenId
        );
    }
    
    function comboBySig(
        uint256[] memory fromTokenIds,
        string memory eventMetadataURI,
        address to,
        uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused {
        //TODO
    }
    
    function collect(
        uint256 eventId, 
        address collector,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        bytes calldata data
    ) external whenNotPaused onlyGov {
        address derivatveNFT = _derivativeNFTByEventId[eventId];
        if (derivatveNFT== address(0)) revert Errors.InvalidParameter();

        return  InteractionLogic.collectDerivativeNFT(
           derivatveNFT, collector, fromSoulBoundTokenId, toSoulBoundTokenId, tokenId,
           data, _pubByIdByProfile, _incubatorBySoulBoundTokenId
        );
    }

    function collectBySig(
        address collector,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata data,
        uint256 nonce,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused {


    }

    function follow(
        uint256[] calldata soulBoundTokenIds,
        bytes[] calldata datas
    ) external override whenNotPaused  onlyGov{
        InteractionLogic.follow(msg.sender, soulBoundTokenIds, datas, _profileById, _profileIdByHandleHash);
    }

    function split(
        uint256 eventId, 
        uint256 soulBoundTokenId, 
        uint256 tokenId, 
        uint256 amount, 
        bytes[] calldata datas
    ) external override whenNotPaused onlyGov returns(uint256) {
        address derivatveNFT = _derivativeNFTByEventId[eventId];
        if (derivatveNFT== address(0)) revert Errors.InvalidParameter();
        
        address incubator = _incubatorBySoulBoundTokenId[soulBoundTokenId];
        if (incubator== address(0)) revert Errors.InvalidParameter();

        return PublishLogic.split(
            derivatveNFT,
            incubator,
            soulBoundTokenId,
            tokenId,
            amount,
            datas
        );
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
        return _INCUBATOR_IMPL;
    }

    function getDNFTImpl() external view override returns (address) {
        return _DNFT_IMPL;
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


    function setGovernance(address newGovernance) external override onlyOwner {
        _setGovernance(newGovernance);
    }

    //--- internal  ---//
    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }
    
    function _setGovernance(address newGovernance) internal {
        address prevGovernance = _governance;
        _governance = newGovernance;

        emit Events.GovernanceSet(msg.sender, prevGovernance, newGovernance, block.timestamp);
    }

    // function _getRevision() internal pure virtual override returns (uint256) {
    //     return _REVISION;
    // }
}