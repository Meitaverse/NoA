// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "./interfaces/IDerivativeNFTV1.sol";
import "./interfaces/INFTDerivativeProtocolTokenV1.sol";
import "./interfaces/IManager.sol";
import "./interfaces/ISoulBoundTokenV1.sol";
import "./base/NoAMultiState.sol";
import {DataTypes} from './libraries/DataTypes.sol';
import {Events} from"./libraries/Events.sol";
import {InteractionLogic} from './libraries/InteractionLogic.sol';
import {PublishLogic} from './libraries/PublishLogic.sol';
import {MarketLogic} from './libraries/MarketLogic.sol';
import {PriceManager} from './libraries/PriceManager.sol';
import {ManagerStorage} from  "./storage/ManagerStorage.sol";
import "./libraries/SafeMathUpgradeable128.sol";

// import {VersionedInitializable} from './upgradeability/VersionedInitializable.sol';

contract Manager is
    Initializable,
    IManager,
    ContextUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    NoAMultiState,
    ManagerStorage,
    PriceManager,
    // VersionedInitializable,
    UUPSUpgradeable
{
    // using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable128 for uint128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint256 internal constant _REVISION = 1;
    // solhint-disable-next-line var-name-mixedcase
    address internal immutable _INCUBATOR_IMPL;
    // solhint-disable-next-line var-name-mixedcase
    address internal immutable _DNFT_IMPL;
    // solhint-disable-next-line var-name-mixedcase
    address public immutable NDPT;

    address internal _governance;
    address internal _receiver;
    
    bytes32 internal constant _PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 internal constant _UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    bytes32 private constant _MINT_SBT_TYPEHASH =
        keccak256("MintSBT(string nickName,string role,address to,uint256 value)");

    using Counters for Counters.Counter;

    Counters.Counter private _nextSaleId;
    Counters.Counter private _nextTradeId;
    Counters.Counter private _nextHubId;
    Counters.Counter private _nextProjectId;

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }
    modifier onlySoulBoundTokenOwner(uint256 soulBoundTokenId) {
       _validateCallerIsSoulBoundTokenOwner(soulBoundTokenId);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address ndptV1_, 
        address noAV1_, 
        address incubator_
    ) initializer {
        NDPT = ndptV1_;
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

        //default Paused
        _setState(DataTypes.ProtocolState.Paused);

        _setGovernance(governance_);

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

    function whitelistProfileCreator(address profileCreator, bool whitelist)
        external
        override
        onlyGov
    {
        _profileCreatorWhitelisted[profileCreator] = whitelist;
        emit Events.ProfileCreatorWhitelisted(profileCreator, whitelist, block.timestamp);
    }

    function setStateDerivative(address derivativeNFT, DataTypes.ProtocolState newState) external override onlyGov{
        IDerivativeNFTV1(derivativeNFT).setState(newState);
    }

    function mintNDPT(
        uint256 tokenId, 
        uint256 slot, 
        uint256 value
    ) external whenNotPaused onlyGov {
        INFTDerivativeProtocolTokenV1(NDPT).mint(tokenId, slot, value);
    }

    function mintNDPTValue(
        uint256 tokenId, 
        uint256 value
    ) external whenNotPaused onlyGov {
        INFTDerivativeProtocolTokenV1(NDPT).mintValue(tokenId, value);
    }

    function transferValueNDPT(
        uint256 tokenId, 
        uint256 toSoulBoundTokenId,
        uint256 value
    ) external whenNotPaused onlyGov returns (uint256) {
        address toIncubator =  InteractionLogic.deployIncubatorContract(toSoulBoundTokenId);
        return IERC3525(NDPT).transferFrom(tokenId, toIncubator, value);
    }

    function burnNDPT(
        uint256 tokenId
    ) external whenNotPaused onlyGov {
         INFTDerivativeProtocolTokenV1(NDPT).burn(tokenId);
    }

    function burnNDPTValue(
        uint256 tokenId,
        uint256 value
    ) external whenNotPaused onlyGov {
        INFTDerivativeProtocolTokenV1(NDPT).burnValue(tokenId, value);
    }

    function createProfile(
        DataTypes.CreateProfileData calldata vars, 
        string memory nickName
    ) external returns (uint256) {
        if (!_profileCreatorWhitelisted[msg.sender]) revert Errors.ProfileCreatorNotWhitelisted();
        
        uint256 soulBoundTokenId = INFTDerivativeProtocolTokenV1(NDPT).createProfile(vars, nickName);

        address toIncubator = InteractionLogic.deployIncubatorContract(soulBoundTokenId);
        _incubatorBySoulBoundTokenId[soulBoundTokenId] = toIncubator;
    
        return soulBoundTokenId;
    }

    function createHub(
        address creater, 
        uint256 soulBoundTokenId,
        DataTypes.Hub memory hub,
        bytes calldata createHubModuleData
    ) external whenNotPaused onlyGov{
        uint256 hubId = _generateNextHubId();
        _hubBySoulBoundTokenId[soulBoundTokenId] = hubId; 
        InteractionLogic.createHub(
            creater,
            soulBoundTokenId,
            hubId,
            hub,
            createHubModuleData,
            _hubInfos
        );
   }

    function createProject(
        uint256 hubId,
        uint256 soulBoundTokenId,
        DataTypes.Project memory project,
        address metadataDescriptor,
        bytes calldata createProjectModuleData
    ) 
        external 
        whenNotPaused 
        onlySoulBoundTokenOwner(soulBoundTokenId)
        returns (uint256) 
    {
       if (_hubBySoulBoundTokenId[soulBoundTokenId] != hubId) revert Errors.NotHubOwner();
       if (_projectNameHashByEventId[keccak256(bytes(project.name))]  > 0) {
            revert Errors.ProjectExisted();
       }

       uint256 projectId = _generateNextProjectId();
       _projectNameHashByEventId[keccak256(bytes(project.name))] = projectId;
       InteractionLogic.createProject(
            hubId,
            projectId,
            soulBoundTokenId,
            project, 
            metadataDescriptor,
            createProjectModuleData,
            _derivativeNFTByProjectId
        );
    
        _projectInfoByProjectId[projectId] = DataTypes.Project({
            hubId: hubId,
            organizer: project.organizer,
            name: project.name,
            description: project.description,
            image: project.image,
            metadataURI: project.metadataURI
        });
        return projectId;
    }

    function getProjectInfo(uint256 projectId_) external view returns (DataTypes.Project memory) {
        if (_projectInfoByProjectId[projectId_].organizer == address(0x0)) {
            revert Errors.EventIdNotExists();
        }
        return _projectInfoByProjectId[projectId_];
    }

    function publish(
        uint256 projectId,
        DataTypes.Publication memory publication,
        uint256 soulBoundTokenId, 
        uint256 amount,
        bytes calldata publishModuleData
    ) 
        external 
        whenNotPaused 
        onlySoulBoundTokenOwner(soulBoundTokenId) 
        returns(uint256)
    {
        address derivatveNFT = _derivativeNFTByProjectId[projectId];
        if (derivatveNFT == address(0)) revert Errors.InvalidParameter();

        return PublishLogic.publish(
            projectId,
            publication,
            derivatveNFT,
            soulBoundTokenId, 
            amount,
            publishModuleData
        );
    }


    function split(
        uint256 projectId, 
        uint256 fromSoulBoundTokenId, 
        uint256 toSoulBoundTokenId, 
        uint256 tokenId, 
        uint256 amount, 
        bytes calldata splitModuleData
    ) 
        external 
        override 
        whenNotPaused 
        onlySoulBoundTokenOwner(fromSoulBoundTokenId)
        returns(uint256) 
    {
        address derivatveNFT = _derivativeNFTByProjectId[projectId];
        if (derivatveNFT== address(0)) revert Errors.InvalidParameter();
        return PublishLogic.split(
            derivatveNFT,
            fromSoulBoundTokenId,
            toSoulBoundTokenId,
            tokenId,
            amount,
            splitModuleData
        );
    }

    function collect(
        uint256 projectId, 
        address collector,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata collectModuledata
    ) 
        external
        whenNotPaused 
        onlySoulBoundTokenOwner(fromSoulBoundTokenId)
    {
        address derivatveNFT = _derivativeNFTByProjectId[projectId];
        if (derivatveNFT== address(0)) revert Errors.InvalidParameter();

        return  InteractionLogic.collectDerivativeNFT(
           projectId, 
           derivatveNFT, 
           collector, 
           fromSoulBoundTokenId, 
           toSoulBoundTokenId, 
           tokenId,
           value,
           collectModuledata, 
           _pubByIdByProfile
        );
    }

    function airdrop(
        uint256 hubId, 
        uint256 projectId, 
        uint256 fromSoulBoundTokenId,
        uint256[] memory toSoulBoundTokenIds,
        uint256 tokenId,
        uint256[] memory values,
        bytes[] calldata airdropModuledatas
    ) 
        external
        whenNotPaused 
        onlySoulBoundTokenOwner(fromSoulBoundTokenId)
    {
        if (_hubBySoulBoundTokenId[fromSoulBoundTokenId] != hubId) revert Errors.NotHubOwner();
        address derivatveNFT = _derivativeNFTByProjectId[projectId];
        if (derivatveNFT== address(0)) revert Errors.InvalidParameter();

        return InteractionLogic.airdropDerivativeNFT(
            projectId, 
            derivatveNFT, 
            msg.sender,
            fromSoulBoundTokenId, 
            toSoulBoundTokenIds, 
            tokenId,
            values,
            airdropModuledatas, 
            _pubByIdByProfile
        );
    }

    function transferDerivativeNFT(
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        bytes calldata transferModuledata
    ) 
        external 
        whenNotPaused 
        onlySoulBoundTokenOwner(fromSoulBoundTokenId)
    {
        address derivatveNFT = _derivativeNFTByProjectId[projectId];
        if (derivatveNFT == address(0)) revert Errors.InvalidParameter();
        
        address fromIncubator = _incubatorBySoulBoundTokenId[fromSoulBoundTokenId];
        if (fromIncubator== address(0)) revert Errors.InvalidParameter();
        
        address toIncubator = _incubatorBySoulBoundTokenId[toSoulBoundTokenId];
        if (toIncubator== address(0)) revert Errors.InvalidParameter();
        
        InteractionLogic.transferDerivativeNFT(
            fromSoulBoundTokenId,
            toSoulBoundTokenId,
            projectId,
            derivatveNFT,
            fromIncubator,
            toIncubator,
            tokenId, 
            transferModuledata
        );
    }

    function transferValueDerivativeNFT(
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata transferValueModuledata
    ) 
        external 
        whenNotPaused 
        onlySoulBoundTokenOwner(fromSoulBoundTokenId)
    {
        address derivatveNFT = _derivativeNFTByProjectId[projectId];
        if (derivatveNFT == address(0)) revert Errors.InvalidParameter();
        
        address fromIncubator = _incubatorBySoulBoundTokenId[fromSoulBoundTokenId];
        if (fromIncubator== address(0)) revert Errors.InvalidParameter();
        
        address toIncubator = _incubatorBySoulBoundTokenId[toSoulBoundTokenId];
        if (toIncubator== address(0)) revert Errors.InvalidParameter();
        
        InteractionLogic.transferValueDerivativeNFT(
            fromSoulBoundTokenId,
            toSoulBoundTokenId,
            projectId,
            derivatveNFT,
            toIncubator,
            tokenId, 
            value,
            transferValueModuledata
        );
    }

    function publishFixedPrice(
        DataTypes.Sale memory sale
    ) external whenNotPaused onlyGov{
       uint24  saleId = _generateNextSaleId();
       _derivativeNFTSales[sale.derivativeNFT].add(saleId);
       PriceManager.setFixedPrice(saleId, sale.price);
       MarketLogic.publishFixedPrice(
            sale,
            markets,
            sales
       );
    }

    function removeSale(
        uint24 saleId_
    ) external whenNotPaused onlyGov{
        MarketLogic.removeSale(
            saleId_,
            sales
        );
    }

    function addMarket(
        address derivativeNFT_,
        uint64 precision_,
        uint8 feePayType_,
        uint8 feeType_,
        uint128 feeAmount_,
        uint16 feeRate_
    ) external whenNotPaused onlyGov{
        MarketLogic.addMarket(
            derivativeNFT_,
            precision_,
            feePayType_,
            feeType_,
            feeAmount_,
            feeRate_,
            markets
        );
    }

    function removeMarket(
        address derivativeNFT_
    ) external whenNotPaused onlyGov{
        MarketLogic.removeMarket(
            derivativeNFT_,
            markets
        );
    }
    
    function buyUnits(
        uint256 soulBoundTokenId,
        address buyer,
        uint24 saleId, 
        uint128 units
    ) 
        external 
        payable 
        whenNotPaused 
        onlySoulBoundTokenOwner(soulBoundTokenId)
        returns (uint256 amount, uint128 fee)
    {
        if (sales[saleId].max > 0) {
            require( saleRecords[sales[saleId].saleId][buyer].add(units) <= sales[saleId].max, "exceeds purchase limit");
            saleRecords[sales[saleId].saleId][buyer] =  saleRecords[sales[saleId].saleId][buyer].add(units);
        }

        if (sales[saleId].useAllowList) {
            require(
                _allowAddresses[sales[saleId].derivativeNFT].contains(buyer),
                "not in allow list"
            );
        }
        return MarketLogic.buyByUnits(
            _generateNextTradeId(),
            buyer,
            saleId,
            PriceManager.price(DataTypes.PriceType.FIXED, saleId),
            units,
            markets,
            sales
        );
    }

    function follow(
        uint256 projectId,
        uint256 soulBoundTokenId,
        bytes calldata data
    ) 
        external 
        override 
        whenNotPaused  
        onlySoulBoundTokenOwner(soulBoundTokenId)
    {
        InteractionLogic.follow(projectId, msg.sender, soulBoundTokenId, data, _profileById, _profileIdByHandleHash);
    }


    function getFollowModule(uint256 soulBoundTokenId) external view override returns (address) {
        return _profileById[soulBoundTokenId].followModule;
    }

    function getSoulBoundToken() external view returns (address) {
        return NDPT;
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

    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    //--- internal  ---//
    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }
    
    function _validateCallerIsSoulBoundTokenOwner(uint256 soulBoundTokenId) internal view {
        if (msg.sender != _profileOwners[soulBoundTokenId]) revert Errors.NotSoulBoundTokenOwner();
    }
    
    function _setGovernance(address newGovernance) internal {
        address prevGovernance = _governance;
        _governance = newGovernance;

        emit Events.GovernanceSet(msg.sender, prevGovernance, newGovernance, block.timestamp);
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

    // function _getRevision() internal pure virtual override returns (uint256) {
    //     return _REVISION;
    // }
}