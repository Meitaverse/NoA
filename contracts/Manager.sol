// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
import {IDerivativeNFT} from "./interfaces/IDerivativeNFT.sol";
import "./interfaces/INFTDerivativeProtocolTokenV1.sol";
import "./interfaces/IManager.sol";
import "./base/NFTDerivativeProtocolMultiState.sol";
import './libraries/Constants.sol';
import {DataTypes} from './libraries/DataTypes.sol';
import {Events} from"./libraries/Events.sol";
import {InteractionLogic} from './libraries/InteractionLogic.sol';
import {PublishLogic} from './libraries/PublishLogic.sol';
import {ManagerStorage} from  "./storage/ManagerStorage.sol";
import "./libraries/SafeMathUpgradeable128.sol";
import {IBankTreasury} from "./interfaces/IBankTreasury.sol";
import {VersionedInitializable} from './upgradeability/VersionedInitializable.sol';
import {IModuleGlobals} from "./interfaces/IModuleGlobals.sol";

contract Manager is 
    ReentrancyGuard,
    IManager,
    NFTDerivativeProtocolMultiState,
    ManagerStorage,
    VersionedInitializable
{
    using SafeMathUpgradeable128 for uint128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using Counters for Counters.Counter;

    uint256 internal constant REVISION = 1;

    mapping(address => uint256) public sigNonces;

    address internal  _DNFT_IMPL; //immutable
    address internal  _RECEIVER;  //immutable

    string private constant name = "Manager";

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    constructor() {}

    function initialize(
        address dNftV1_, 
        address receiver_,
        address governance
    ) external initializer {
        if (dNftV1_ == address(0)) revert Errors.InitParamsInvalid();
        if (receiver_ == address(0)) revert Errors.InitParamsInvalid();
        
        _DNFT_IMPL = dNftV1_;
        _RECEIVER = receiver_;        
        //default Paused
        _setState(DataTypes.ProtocolState.Paused);
        _owner = msg.sender;
        if (governance == address(0)) revert Errors.InitParamsInvalid();
         _setGovernance(governance);
    }

    //-- external -- //
    function getReceiver() external view returns (address) {
        return _RECEIVER;
    }

    function createProfile(
        DataTypes.CreateProfileData calldata vars
    ) 
        external 
        whenNotPaused 
        nonReentrant
        returns (uint256) 
    {
        if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistProfileCreator(vars.wallet)) 
           revert Errors.ProfileCreatorNotWhitelisted();
        if (_sbt == address(0)) revert Errors.SBTNotSet();
        _validateNickName(vars.nickName);

        uint256 soulBoundTokenId = INFTDerivativeProtocolTokenV1(_sbt).createProfile(
            _voucher,
            vars 
        );

        _soulBoundTokenIdToWallet[soulBoundTokenId] = vars.wallet;
        _walletToSoulBoundTokenId[vars.wallet] = soulBoundTokenId;

        return soulBoundTokenId;
    }

    function createHub(
        DataTypes.HubData calldata hub
    ) 
        external 
        nonReentrant
        whenNotPaused 
        returns(uint256)
    {
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(hub.soulBoundTokenId);

        if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistHubCreator(hub.soulBoundTokenId)) 
            revert Errors.HubCreatorNotWhitelisted();
       
        //only can create one hub
        if (_hubIdBySoulBoundTokenId[hub.soulBoundTokenId] > 0)
            revert Errors.HubOnlyCreateOne();

        uint256 hubId = _generateNextHubId();
        _hubIdBySoulBoundTokenId[hub.soulBoundTokenId] = hubId;

        InteractionLogic.createHub(
            msg.sender,
            hubId,
            hub, 
            _hubInfos
        );

        return hubId; 
    }

    function updateHub(
        uint256 hubId,
        string calldata hubName,
        string calldata description,
        string calldata imageURI
    ) 
        external 
        nonReentrant
        whenNotPaused 
    {
        DataTypes.HubInfoData storage hub = _hubInfos[hubId];

        if (!( hub.hubOwner == msg.sender || _dispatcherByProfile[hub.soulBoundTokenId] == msg.sender)) 
            revert Errors.NotHubOwner();

        if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistHubCreator(hub.soulBoundTokenId)) 
            revert Errors.HubCreatorNotWhitelisted();
       
        if (hubId == 0) revert Errors.HubNotExists();

        InteractionLogic.updateHub(
            hubId,
            hubName, 
            description, 
            imageURI, 
            _hubInfos
        );
    }

    /// @notice Only hub owner can creat projects
    function createProject(
        DataTypes.ProjectData calldata project
    ) 
        external 
        whenPublishingEnabled 
        nonReentrant
        returns (uint256) 
    {
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(project.soulBoundTokenId);
        
        if (_hubIdBySoulBoundTokenId[project.soulBoundTokenId] != project.hubId) revert Errors.NotHubOwner();
        if (_projectNameHashByEventId[keccak256(bytes(project.name))] > 0) {
            revert Errors.ProjectExisted();
        }
        uint256 projectId = _generateNextProjectId();
        _projectNameHashByEventId[keccak256(bytes(project.name))] = projectId;

        address creator = IERC3525(_sbt).ownerOf(project.soulBoundTokenId);

        address derivativeNFT = InteractionLogic.createProject(
            creator,
            _DNFT_IMPL,
            _sbt,
            _treasury,
            _market,
            projectId,
            project,
            _RECEIVER,
            _derivativeNFTByProjectId,
            _projectInfoByProjectId
        );

        _projectIdToderivativeNFT[derivativeNFT] = projectId;

        return projectId;
    }

    function getProjectInfo(uint256 projectId_) external view returns (DataTypes.ProjectData memory) {
        return _projectInfoByProjectId[projectId_];
    }

    function calculateRoyalty(uint256 publishId) external view returns(uint16) {
        return _calculateRoyalty(publishId);
    }
 
    function _calculateRoyalty(uint256 publishId) internal view returns(uint16) {
        uint256 projectid = _projectDataByPublishId[publishId].publication.projectId;
        uint256 previousPublishId = _projectDataByPublishId[publishId].previousPublishId;
        (, uint16 treasuryFee ) = IModuleGlobals(MODULE_GLOBALS).getTreasuryData();

        uint16 fraction = 
            uint16(treasuryFee) + 
            uint16(_projectDataByPublishId[_genesisPublishIdByProjectId[projectid]].publication.royaltyBasisPoints) +
            uint16(_projectDataByPublishId[previousPublishId].publication.royaltyBasisPoints);

        return fraction;
    }
 
    function getGenesisAndPreviousPublishId(uint256 publishId) external view returns(uint256 genesisPublishId, uint256 previousPublishId) {
        uint256 projectid = _projectDataByPublishId[publishId].publication.projectId;
        return (
            _genesisPublishIdByProjectId[projectid],
            _projectDataByPublishId[publishId].previousPublishId
        );
    }

    /// @notice prepare publish, and transfer from SBT value to bank treasury while amount >1
    function prePublish(
        DataTypes.Publication calldata publication
    ) 
        external 
        whenPublishingEnabled 
        nonReentrant
        returns (uint256) 
    { 
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(publication.soulBoundTokenId);

        _validateSameHub(publication.hubId, publication.projectId);

        if (_hubIdBySoulBoundTokenId[publication.soulBoundTokenId] != publication.hubId && 
                publication.fromTokenIds.length == 0)  {
            revert Errors.InsufficientDerivativeNFT();
        }

        if (_derivativeNFTByProjectId[publication.projectId] == address(0) || publication.amount == 0) 
            revert Errors.InvalidParameter();

        //valid publication's name is exists?
        if (_publicationNameHashExists[keccak256(bytes(publication.name))]) 
            revert Errors.PublicationIsExisted();    
        
        _publicationNameHashExists[keccak256(bytes(publication.name))] = true;

        uint256 previousPublishId;
        uint256 publishId = _generateNextPublishId();
        if (publication.fromTokenIds.length == 0){
            previousPublishId = 0;
            //save genesis publishId for this projectId 
            _genesisPublishIdByProjectId[publication.projectId] = publishId;

        } else{
            address derivativeNFT = _derivativeNFTByProjectId[publication.projectId];
            previousPublishId = IDerivativeNFT(derivativeNFT).getPublishIdByTokenId(publication.fromTokenIds[0]);
        }
        
        if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistPublishModule(publication.publishModule))
            revert Errors.PublishModuleNotWhitelisted();

        if (_projectInfoByProjectId[publication.projectId].permitByHubOwner) {
            //wait for hub owner to set permit to true
            _isHubOwnerPermitBypublishId[publishId] = false;
        }

        PublishLogic.prePublish(
            publication,
            publishId,
            previousPublishId,
            BANK_TREASURY_SOUL_BOUND_TOKENID,
            _projectDataByPublishId
        );

        //calculate royalties
        if (_calculateRoyalty(publishId) > uint96(BASIS_POINTS)) {
           revert Errors.InvalidRoyaltyBasisPoints();   
        }
        return publishId;
    }

    function hubOwnerPermitPublishId(
        uint256 publishId, 
        bool isPermit
    ) 
        external 
        whenPublishingEnabled 
        nonReentrant
    {
         DataTypes.PublishData storage publishData = _projectDataByPublishId[publishId];
         DataTypes.HubInfoData storage hub = _hubInfos[publishData.publication.hubId];

        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(hub.soulBoundTokenId);
        
        _isHubOwnerPermitBypublishId[publishId] = isPermit;
   
    }

    function publisherSetCanCollect(
        uint256 publishId, 
        bool canCollect
    ) 
        external 
        whenPublishingEnabled 
        nonReentrant
    {
        DataTypes.PublishData memory publishData = _projectDataByPublishId[publishId];
        
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(publishData.publication.soulBoundTokenId);
        
        publishData.publication.canCollect = canCollect;

    }

    function updatePublish(
        uint256 publishId,
        uint256 salePrice,
        uint16 royaltyBasisPoints,
        uint256 amount,
        string calldata name,
        string calldata description,
        string[] calldata materialURIs,
        uint256[] calldata fromTokenIds
    ) 
        external 
        whenPublishingEnabled 
        nonReentrant
    {  
        if (publishId == 0) revert Errors.InvalidParameter();
        if (amount == 0) revert Errors.InvalidParameter();
        if (_projectDataByPublishId[publishId].publication.amount < amount) revert Errors.AmountOnlyIncrease();

        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(_projectDataByPublishId[publishId].publication.soulBoundTokenId);

        if (_projectDataByPublishId[publishId].isMinted) revert Errors.CannotUpdateAfterMinted();
        
        //calculate royalties
        if (_calculateRoyalty(publishId) > uint96(BASIS_POINTS)) {
           revert Errors.InvalidRoyaltyBasisPoints();   
        }

        PublishLogic.updatePublish(
            publishId,
            salePrice,
            royaltyBasisPoints,
            amount,
            name,
            description,
            materialURIs,
            fromTokenIds,
            _projectDataByPublishId
        );
    }

    function publish(
        uint256 publishId
    ) 
        external 
        whenPublishingEnabled 
        nonReentrant
        returns (uint256) 
    { 
        if (publishId == 0) {
            revert Errors.InvalidProjectId();
        } else {

            _validateCallerIsSoulBoundTokenOwnerOrDispathcher(_projectDataByPublishId[publishId].publication.soulBoundTokenId);
            
            DataTypes.HubInfoData storage hub = _hubInfos[_projectDataByPublishId[publishId].publication.hubId];

            address publisher = _soulBoundTokenIdToWallet[_projectDataByPublishId[publishId].publication.soulBoundTokenId];

            if (publisher != hub.hubOwner ) {
                if (_projectInfoByProjectId[_projectDataByPublishId[publishId].publication.projectId].permitByHubOwner) {
                    //hub owner permit publish
                    if ( !_isHubOwnerPermitBypublishId[publishId]) {
                        revert Errors.HubOwnerNotPermitPublish();
                    }
                }
            }
            
            address derivativeNFT = _derivativeNFTByProjectId[_projectDataByPublishId[publishId].publication.projectId];
            if (_projectDataByPublishId[publishId].publication.amount == 0) 
            revert Errors.AmountIsZero();
            
            if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistCollectModule(_projectDataByPublishId[publishId].publication.collectModule))
                revert Errors.CollectModuleNotWhitelisted();
                
            uint16 _bps = _calculateRoyalty(publishId);

            uint256 newTokenId = PublishLogic.createPublish(
                _projectDataByPublishId[publishId].publication,
                publishId,
                publisher,
                derivativeNFT,
                _bps,
                _pubByIdByProfile
            );

            //Avoids stack too deep
            {
                _projectDataByPublishId[publishId].isMinted = true;
                _projectDataByPublishId[publishId].tokenId = newTokenId;
            }

            return newTokenId;
        }
    }

    function setTokenImageURI(uint256 projectId, uint256 tokenId, string memory imageURI)
        external
        onlyGov
        whenPublishingEnabled 
    {
        if (projectId == 0) 
            revert Errors.InvalidProjectId();

        address derivativeNFT =  _derivativeNFTByProjectId[projectId];
        IDerivativeNFT(derivativeNFT).setTokenImageURI(tokenId, imageURI);

    }

    function collect(
        DataTypes.CollectData calldata collectData
    ) 
        external 
        whenPublishingEnabled 
        nonReentrant
        returns(uint256)
    {
         _validateCallerIsSoulBoundTokenOwnerOrDispathcher(collectData.collectorSoulBoundTokenId);

        address derivativeNFT =  _derivativeNFTByProjectId[_projectDataByPublishId[collectData.publishId].publication.projectId];


        //check can collect?
        if (!_projectDataByPublishId[collectData.publishId].publication.canCollect) {
            revert Errors.PublisherSetCanNotCollect();
        }

        uint256 newTokenId = IDerivativeNFT(derivativeNFT).split(
            collectData.publishId, 
            _projectDataByPublishId[collectData.publishId].tokenId, 
            _soulBoundTokenIdToWallet[collectData.collectorSoulBoundTokenId],
            collectData.collectUnits
        );

        PublishLogic.collectDerivativeNFT(
            DataTypes.CollectDataParam(
              collectData.publishId,
              collectData.collectorSoulBoundTokenId,
              collectData.collectUnits,
              collectData.data,
              _projectDataByPublishId[collectData.publishId].tokenId,
              newTokenId,
              _derivativeNFTByProjectId[_projectDataByPublishId[collectData.publishId].publication.projectId],
              _sbt,
              _treasury
            ),
            _pubByIdByProfile,
            _projectDataByPublishId
        );

        return newTokenId;    
    }

    function airdrop(
        DataTypes.AirdropData calldata airdropData
    ) 
        external
        whenPublishingEnabled
        nonReentrant
    {
         _validateCallerIsSoulBoundTokenOwnerOrDispathcher(airdropData.ownershipSoulBoundTokenId);
        
        address derivativeNFT = _derivativeNFTByProjectId[_projectDataByPublishId[airdropData.publishId].publication.projectId];

        PublishLogic.airdrop(
            derivativeNFT, 
            airdropData,
            _soulBoundTokenIdToWallet,
            _projectDataByPublishId
        );
    }

    function getPublishInfo(uint256 publishId_) external view returns (DataTypes.PublishData memory) {
        return _projectDataByPublishId[publishId_];
    }

    function getPublication(uint256 publishId_) external view returns (DataTypes.Publication memory) {
        return _projectDataByPublishId[publishId_].publication;
    }

    function getDerivativeNFT(uint256 projectId) external view returns (address) {
        return _derivativeNFTByProjectId[projectId];
    }

    function calculateDerivativeNFTAddress(
        uint256 projectIdStart,
        uint256 projectIdEnd
    ) external view returns (address[] memory) {
        address[] memory deverivateNFTInstances = new address[](projectIdEnd - projectIdStart + 1);
        for (uint256 i = projectIdStart; i < projectIdEnd; i++) {
            bytes32 salt = keccak256(abi.encode(i));
            address deverivateNFTInstance = Clones.predictDeterministicAddress(_DNFT_IMPL, salt);
            deverivateNFTInstances[i] = deverivateNFTInstance;
        }
        return deverivateNFTInstances;
    }

    function getPublicationByProjectToken(uint256 projectId_, uint256 tokenId_) external view returns (uint256, DataTypes.Publication memory) {
        address derivativeNFT =  _derivativeNFTByProjectId[projectId_];
        uint256 publishId = IDerivativeNFT(derivativeNFT).getPublishIdByTokenId(tokenId_);
        return (publishId, _projectDataByPublishId[publishId].publication);
    } 

    function getProjectIdByContract(address contract_) external view returns (uint256) {
        return _projectIdToderivativeNFT[contract_];
    }

    function getGenesisPublishIdByProjectId(uint256 projectId) external view returns(uint256) {
       return _genesisPublishIdByProjectId[projectId];   
    }

    function getHubInfo(uint256 hubId) external view returns(DataTypes.HubInfoData memory) {
        return _hubInfos[hubId];
    }

    function getWalletBySoulBoundTokenId(uint256 soulBoundTokenId) external view returns(address) {
        return _soulBoundTokenIdToWallet[soulBoundTokenId];
    }
    
    function getSoulBoundTokenIdByWallet(address wallet) external view returns(uint256) {
        return _walletToSoulBoundTokenId[wallet];
    }
    
    function getGenesisAndPreviousInfo(uint256 projectId, uint256 tokenId) 
        external 
        view 
        returns(
            uint256,  //genesis SBT id
            uint16,  //genesis royaltyBasisPoints
            uint256,  //previous SBT id
            uint16   //previous royaltyBasisPoints
        ) 
    {
         //genesis
        uint256 genesisPublishId = _genesisPublishIdByProjectId[projectId];
   
        //previous 
        address derivativeNFT =  _derivativeNFTByProjectId[projectId];
        uint256 publishId = IDerivativeNFT(derivativeNFT).getPublishIdByTokenId(tokenId);
        
        return (
            _projectDataByPublishId[genesisPublishId].publication.soulBoundTokenId,
            _projectDataByPublishId[genesisPublishId].publication.royaltyBasisPoints,
            _projectDataByPublishId[_projectDataByPublishId[publishId].previousPublishId].publication.soulBoundTokenId,
            _projectDataByPublishId[_projectDataByPublishId[publishId].previousPublishId].publication.royaltyBasisPoints
        );
    }

    function getGenesisAndPreviousInfo(uint256 publishId) 
        external 
        view 
        returns(
            uint256,  //genesis SBT id
            uint16,  //genesis royaltyBasisPoints
            uint256,  //previous SBT id
            uint16   //previous royaltyBasisPoints
        ) 
    {
        
        uint256 projectid = _projectDataByPublishId[publishId].publication.projectId;

         //genesis
        uint256 genesisPublishId = _genesisPublishIdByProjectId[projectid];

        return (
            _projectDataByPublishId[genesisPublishId].publication.soulBoundTokenId,
            _projectDataByPublishId[genesisPublishId].publication.royaltyBasisPoints,
            _projectDataByPublishId[_projectDataByPublishId[publishId].previousPublishId].publication.soulBoundTokenId,
            _projectDataByPublishId[_projectDataByPublishId[publishId].previousPublishId].publication.royaltyBasisPoints
        );
    }

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    function setEmergencyAdmin(address newEmergencyAdmin) external nonReentrant onlyGov {
        address prevEmergencyAdmin = _emergencyAdmin;
        _emergencyAdmin = newEmergencyAdmin;
        emit Events.EmergencyAdminSet(msg.sender, prevEmergencyAdmin, newEmergencyAdmin, block.timestamp);
    }

    function setState(DataTypes.ProtocolState newState) external nonReentrant {
        if (msg.sender == _emergencyAdmin) {
            if (newState == DataTypes.ProtocolState.Unpaused) revert Errors.EmergencyAdminCannotUnpause();
            _validateNotPaused();
        } else if (msg.sender != _governance) {
            //onlyGov
            revert Errors.NotGovernanceOrEmergencyAdmin();
        }
        _setState(newState);
    }

    function setDerivativeNFTState(
        uint256 projectId,
        DataTypes.DerivativeNFTState newState
    ) 
        external 
        nonReentrant 
        onlyGov 
    {
        address derivativeNFT = _derivativeNFTByProjectId[projectId];
        IDerivativeNFT(derivativeNFT).setState(newState);
    }

    function setDerivativeNFTMetadataDescriptor(
        uint256 projectId, 
        address metadataDescriptor
    ) 
        external 
        onlyGov 
    {
        address derivativeNFT = _derivativeNFTByProjectId[projectId];
        IDerivativeNFT(derivativeNFT).setMetadataDescriptor(metadataDescriptor);
    }
    
    function setGovernance(address newGovernance) external nonReentrant onlyGov {
        _setGovernance(newGovernance);
    }

    function setSBT(address sbt) external nonReentrant onlyGov {
        _sbt = sbt;
    }

    function setVoucher(address voucher) external nonReentrant onlyGov {
        _voucher = voucher;
    }

    function setTreasury(address treasury) external nonReentrant onlyGov {
         _soulBoundTokenIdToWallet[1] = treasury; 
        _treasury = treasury;
    }

    function setMarket(address market) external nonReentrant onlyGov {
        _market = market;
    }

    function setTimeLock(address timeLock) external nonReentrant onlyGov {
        _timeLock = timeLock;
    }

    function getGovernance() external view returns(address) {
        return _governance;
    }

    function getTimeLock() external view returns(address) {
        return _timeLock;
    }

    function setGlobalModules(address moduleGlobals) external nonReentrant onlyGov {
        if (moduleGlobals == address(0)) revert Errors.InitParamsInvalid();
        MODULE_GLOBALS = moduleGlobals;
        emit Events.GlobalModulesSet(moduleGlobals);  
    }

    function getGlobalModule() external view returns(address) {
        return MODULE_GLOBALS;
    }

    function getDispatcher(uint256 soulBoundToken) external view returns (address) {
        return _dispatcherByProfile[soulBoundToken];
    }

    function setDispatcher(uint256 soulBoundTokenId, address dispatcher) external whenNotPaused {
        _validateCallerIsSoulBoundTokenOwner(soulBoundTokenId);
        _setDispatcher(soulBoundTokenId, dispatcher);
    }

    function setDispatcherWithSig(DataTypes.SetDispatcherWithSigData calldata vars)
        external
        nonReentrant
        whenNotPaused
    {
        address owner = IERC3525(_sbt).ownerOf(vars.soulBoundTokenId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_DISPATCHER_WITH_SIG_TYPEHASH,
                            vars.soulBoundTokenId,
                            vars.dispatcher,
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    )
                ),
                owner,
                vars.sig
            );
        }
        _setDispatcher(vars.soulBoundTokenId, vars.dispatcher);
    }

    //--- internal  ---//

    function  _validateCallerIsSoulBoundTokenOwnerOrDispathcher(uint256 soulBoundTokenId_) internal view {
         if (IERC3525(_sbt).ownerOf(soulBoundTokenId_) == msg.sender || _dispatcherByProfile[soulBoundTokenId_] == msg.sender) {
            return;
         }
         revert Errors.NotProfileOwnerOrDispatcher();
    }

    function _validateCallerIsGovernance() internal view {
        if (!(msg.sender == _governance || msg.sender == _timeLock)) revert Errors.NotGovernance();
    }
    
    function _validateCallerIsSoulBoundTokenOwner(uint256 soulBoundTokenId_) internal view {
        if (IERC3525(_sbt).ownerOf(soulBoundTokenId_) != msg.sender) revert Errors.NotProfileOwner();
    }
    
    function _setDispatcher(uint256 soulBoundTokenId, address dispatcher) internal {
        _dispatcherByProfile[soulBoundTokenId] = dispatcher;
        emit Events.DispatcherSet(soulBoundTokenId, dispatcher, block.timestamp);
    }

    function _setGovernance(address newGovernance) internal {
        address prevGovernance = _governance;
        _governance = newGovernance;

        emit Events.ManagerGovernanceSet(msg.sender, prevGovernance, newGovernance, block.timestamp);
    }


    function _generateNextHubId() internal returns (uint256) {
        _nextHubId.increment();
        return uint24(_nextHubId.current());
    }

    function _generateNextProjectId() internal returns (uint256) {
        _nextProjectId.increment();
        return uint24(_nextProjectId.current());
    }

    function _generateNextPublishId() internal returns (uint256) {
        _nextPublishId.increment();
        return uint24(_nextPublishId.current());
    }

    function version() public pure returns(uint256) {
        return REVISION;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }

    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(
        bytes32 digest,
        address expectedAddress,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        if (sig.deadline < block.timestamp) revert Errors.SignatureExpired();
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        if (recoveredAddress == address(0) || recoveredAddress != expectedAddress)
            revert Errors.SignatureInvalid();
    }

    /**
     * @dev Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
     *
     * @param hashedMessage The message hash from which the digest should be calculated.
     *
     * @return bytes32 A 32-byte output representing the EIP712 digest.
     */
    function _calculateDigest(bytes32 hashedMessage) internal view returns (bytes32) {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked('\x19\x01', _calculateDomainSeparator(), hashedMessage)
            );
        }
        return digest;
    }    

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    EIP712_REVISION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _validateSameHub(uint256 hubId, uint256 projectId) internal view {
        if ( _projectInfoByProjectId[projectId].hubId == hubId) {
            return;
        }
        revert Errors.NotSameHub(); 
    }

    function _validateNickName(string calldata nickName) private pure {
        bytes memory byteNickName = bytes(nickName);
        if (byteNickName.length == 0 || byteNickName.length > MAX_NICKNAME_LENGTH)
            revert Errors.NickNameLengthInvalid();
    }
}
