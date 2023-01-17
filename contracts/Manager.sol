// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
import {IDerivativeNFTV1} from "./interfaces/IDerivativeNFTV1.sol";
import "./interfaces/INFTDerivativeProtocolTokenV1.sol";
import "./interfaces/IManager.sol";
import "./base/NFTDerivativeProtocolMultiState.sol";
import {Constants} from './libraries/Constants.sol';
import {DataTypes} from './libraries/DataTypes.sol';
import {Events} from"./libraries/Events.sol";
import {InteractionLogic} from './libraries/InteractionLogic.sol';
import {PublishLogic} from './libraries/PublishLogic.sol';
import {ManagerStorage} from  "./storage/ManagerStorage.sol";
import "./libraries/SafeMathUpgradeable128.sol";
import {IBankTreasury} from "./interfaces/IBankTreasury.sol";
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {VersionedInitializable} from './upgradeability/VersionedInitializable.sol';
import {IModuleGlobals} from "./interfaces/IModuleGlobals.sol";
import "hardhat/console.sol";

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
    address internal immutable  _DNFT_IMPL;
    address internal immutable  _RECEIVER;

    string public name;

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    modifier onlyOwner() {
        _validateCallerIsOwner();
        _;
    }

    constructor(
        address dNftV1_, 
        address receiver_
    )  {
        if (dNftV1_ == address(0)) revert Errors.InitParamsInvalid();
        if (receiver_ == address(0)) revert Errors.InitParamsInvalid();
        
        _DNFT_IMPL = dNftV1_;
        _RECEIVER = receiver_;
    }

    function initialize(address governance) external override initializer {
        //default Paused
        _setState(DataTypes.ProtocolState.Paused);
        _owner = msg.sender;
        name = "Manager";
        if (governance == address(0)) revert Errors.InitParamsInvalid();
         _setGovernance(governance);
    }

    //-- external -- //
    function getReceiver() external view returns (address) {
        return _RECEIVER;
    }

    function mintSBTValue(uint256 soulBoundTokenId, uint256 value) 
        external 
        whenNotPaused 
        nonReentrant
        onlyGov 
    {
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        
        INFTDerivativeProtocolTokenV1(_sbt).mintValue(soulBoundTokenId, value);
    }

    function burnSBT(uint256 tokenId) 
        external 
        whenNotPaused 
        nonReentrant
        onlyGov 
    {
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        INFTDerivativeProtocolTokenV1(_sbt).burn(tokenId);
    }


    function createProfile(
        DataTypes.CreateProfileData calldata vars
    ) 
        external 
        whenNotPaused 
        nonReentrant
        returns (uint256) 
    {
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistProfileCreator(vars.wallet)) revert Errors.ProfileCreatorNotWhitelisted();
        if (_sbt == address(0)) revert Errors.SBTNotSet();
        _validateNickName(vars.nickName);

        uint256 soulBoundTokenId = INFTDerivativeProtocolTokenV1(_sbt).createProfile(msg.sender, vars);

        _soulBoundTokenIdToWallet[soulBoundTokenId] = vars.wallet;
        _walletToSoulBoundTokenId[vars.wallet] = soulBoundTokenId;

        return soulBoundTokenId;
    }

    function createHub(
        DataTypes.HubData memory hub
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
        uint256 soulBoundTokenId,
        string memory name,
        string memory description,
        string memory imageURI
    ) 
        external 
        nonReentrant
        whenNotPaused 
    {
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(soulBoundTokenId);

        if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistHubCreator(soulBoundTokenId)) revert Errors.HubCreatorNotWhitelisted();
       
        uint256 hubId = _hubIdBySoulBoundTokenId[soulBoundTokenId];
        if (hubId == 0) revert Errors.HubNotExists();

        InteractionLogic.updateHub(
            hubId,
            name, 
            description, 
            imageURI, 
            _hubInfos
        );
    }
 
    function createProject(
        DataTypes.ProjectData memory project
    ) 
        external 
        whenNotPaused 
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
        InteractionLogic.createProject(
            _DNFT_IMPL,
            IModuleGlobals(MODULE_GLOBALS).getSBT(),
            IModuleGlobals(MODULE_GLOBALS).getTreasury(),
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

    function calculateRoyalty(uint256 publishId) external view returns(uint96) {
        return _calculateRoyalty(publishId);
    }
 
    function _calculateRoyalty(uint256 publishId) internal view returns(uint96) {
        uint256 projectid = _projectDataByPublishId[publishId].publication.projectId;
        uint256 previousPublishId = _projectDataByPublishId[publishId].previousPublishId;
        (, uint16 treasuryFee ) = IModuleGlobals(MODULE_GLOBALS).getTreasuryData();

        // fraction = community treasuryFee + genesisFee + previous dNDT fee
        uint96 fraction = 
            uint96(treasuryFee) + 
            uint96(_projectDataByPublishId[_genesisPublishIdByProjectId[projectid]].publication.royaltyBasisPoints) +
            uint96(_projectDataByPublishId[previousPublishId].publication.royaltyBasisPoints);

        return fraction;
    }
 
    //prepare publish, and transfer from SBT value to bank treasury while amount >1
    function prePublish(
        DataTypes.Publication memory publication
    ) 
        external 
        whenNotPaused 
        nonReentrant
        returns (uint256) 
    { 
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(publication.soulBoundTokenId);

        _validateSameHub(publication.hubId, publication.projectId);

        if (publication.amount == 0) revert Errors.InvalidParameter();

        if (_hubIdBySoulBoundTokenId[publication.soulBoundTokenId] != publication.hubId && 
                publication.fromTokenIds.length == 0)  {
            revert Errors.InsufficientDerivativeNFT();
        }

        if (_derivativeNFTByProjectId[publication.projectId] == address(0)) 
            revert Errors.InvalidParameter();

        //valid publication's name is exists?
        if (_publicationNameHashExists[keccak256(bytes(publication.name))]) 
            revert Errors.PublicationIsExisted();    
        
        _publicationNameHashExists[keccak256(bytes(publication.name))] = true;

        uint256 previousPublishId;
        uint256 publishId = _generateNextPublishId();
        if (publication.fromTokenIds.length == 0){
            previousPublishId = 0;
            //save genesisPublishId for this projectId 
            _genesisPublishIdByProjectId[publication.projectId] = publishId;

        } else{
            //TODO
            address derivativeNFT =  _derivativeNFTByProjectId[publication.projectId];
            previousPublishId = IDerivativeNFTV1(derivativeNFT).getPublishIdByTokenId(publication.fromTokenIds[0]);
        }
        
        if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistPublishModule(publication.publishModule))
            revert Errors.PublishModuleNotWhitelisted();

        uint256 treasuryOfSoulBoundTokenId = IBankTreasury(IModuleGlobals(MODULE_GLOBALS).getTreasury()).getSoulBoundTokenId();
        PublishLogic.prePublish(
            publication,
            publishId,
            previousPublishId,
            treasuryOfSoulBoundTokenId,
            _projectDataByPublishId
        );

        //calculate royalties
        if (_calculateRoyalty(publishId) > uint96(Constants._BASIS_POINTS)) {
           revert Errors.InvalidRoyaltyBasisPoints();   
        }
        return publishId;
    }

    function updatePublish(
        uint256 publishId,
        uint256 salePrice,
        uint256 royaltyBasisPoints,
        uint256 amount,
        string memory name,
        string memory description,
        string[] memory materialURIs,
        uint256[] memory fromTokenIds
    ) 
        external 
        whenNotPaused 
        nonReentrant
    {  
        if (publishId == 0) revert Errors.InvalidParameter();
        if (amount == 0) revert Errors.InvalidParameter();
        if (_projectDataByPublishId[publishId].publication.amount < amount) revert Errors.AmountOnlyIncrease();

        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(_projectDataByPublishId[publishId].publication.soulBoundTokenId);

        if (_projectDataByPublishId[publishId].isMinted) revert Errors.CannotUpdateAfterMinted();
        
        //calculate royalties
        if (_calculateRoyalty(publishId) > uint96(Constants._BASIS_POINTS)) {
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
        whenNotPaused 
        nonReentrant
        returns (uint256) 
    { 
        if (publishId == 0) {
            revert Errors.InitParamsInvalid();
        } else {

            _validateCallerIsSoulBoundTokenOwnerOrDispathcher(_projectDataByPublishId[publishId].publication.soulBoundTokenId);
            address publisher = _soulBoundTokenIdToWallet[_projectDataByPublishId[publishId].publication.soulBoundTokenId];
            address derivativeNFT = _derivativeNFTByProjectId[_projectDataByPublishId[publishId].publication.projectId];
            if (_projectDataByPublishId[publishId].publication.amount == 0) revert Errors.InitParamsInvalid();
            
            if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistCollectModule(_projectDataByPublishId[publishId].publication.collectModule))
                revert Errors.CollectModuleNotWhitelisted();
        
            uint256 newTokenId = PublishLogic.createPublish(
                _projectDataByPublishId[publishId].publication,
                publishId,
                publisher,
                derivativeNFT,
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

    function collect(
        DataTypes.CollectData memory collectData
    ) 
        external 
        whenNotPaused 
        nonReentrant
        returns(uint256)
    {
         _validateCallerIsSoulBoundTokenOwnerOrDispathcher(collectData.collectorSoulBoundTokenId);

        address derivativeNFT =  _derivativeNFTByProjectId[_projectDataByPublishId[collectData.publishId].publication.projectId];

        uint256 newTokenId = IDerivativeNFTV1(derivativeNFT).split(
            collectData.publishId, 
            _projectDataByPublishId[collectData.publishId].tokenId, 
            _soulBoundTokenIdToWallet[collectData.collectorSoulBoundTokenId],
            collectData.collectValue
        );

        PublishLogic.collectDerivativeNFT(
            collectData,
            _projectDataByPublishId[collectData.publishId].tokenId,
            newTokenId,
            _derivativeNFTByProjectId[_projectDataByPublishId[collectData.publishId].publication.projectId],
            _pubByIdByProfile,
            _projectDataByPublishId
        );

        return newTokenId;    
    }

    function airdrop(
        DataTypes.AirdropData memory airdropData
    ) 
        external
        whenNotPaused
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
 
    function getDerivativeNFT(uint256 projectId) external view returns (address) {
        return _derivativeNFTByProjectId[projectId];
    }

    function getPublicationByTokenId(uint256 projectId_, uint256 tokenId_) external view returns (uint256, DataTypes.Publication memory) {
      address derivativeNFT =  _derivativeNFTByProjectId[projectId_];
      uint256 publishId = IDerivativeNFTV1(derivativeNFT).getPublishIdByTokenId(tokenId_);
       return (publishId, _projectDataByPublishId[publishId].publication);
    } 

    function getProjectIdByContract(address contract_) external view returns (uint256) {
        return _projectIdToderivativeNFT[contract_];
    }

    function getGenesisPublishIdByProjectId(uint256 projectId) external view returns(uint256) {
       return _genesisPublishIdByProjectId[projectId];   
    }

    function getHubInfo(uint256 hubId) external view returns(DataTypes.HubData memory) {
        return _hubInfos[hubId];
    }

    function getWalletBySoulBoundTokenId(uint256 soulBoundTokenId) external view returns(address) {
        return _soulBoundTokenIdToWallet[soulBoundTokenId];
    }

    function getSoulBoundTokenIdByWallet(address wallet) external view returns(uint256) {
        return _walletToSoulBoundTokenId[wallet];
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
        IDerivativeNFTV1(derivativeNFT).setState(newState);
    }

    function setGovernance(address newGovernance) external nonReentrant onlyGov {
        _setGovernance(newGovernance);
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

    function setGlobalModule(address moduleGlobals) external nonReentrant onlyGov {
        if (moduleGlobals == address(0)) revert Errors.InitParamsInvalid();
        MODULE_GLOBALS = moduleGlobals;
        _soulBoundTokenIdToWallet[1] = IModuleGlobals(MODULE_GLOBALS).getTreasury();
    }

    function getGlobalModule() external view returns(address) {
        return MODULE_GLOBALS;
    }

    function getDispatcher(uint256 soulBoundToken) external view override returns (address) {
        return _dispatcherByProfile[soulBoundToken];
    }

    function setDispatcherWithSig(DataTypes.SetDispatcherWithSigData calldata vars)
        external
        nonReentrant
        whenNotPaused
    {
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
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
         address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
         if (IERC3525(_sbt).ownerOf(soulBoundTokenId_) == msg.sender || _dispatcherByProfile[soulBoundTokenId_] == msg.sender) {
            return;
         }
         revert Errors.NotProfileOwnerOrDispatcher();
    }

    function _validateCallerIsGovernance() internal view {
        if (!(msg.sender == _governance || msg.sender == _timeLock)) revert Errors.NotGovernance();
    }
    
    function _validateCallerIsOwner() internal view {
        if (msg.sender != _owner) revert Errors.NotOwner();
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
        if (byteNickName.length == 0 || byteNickName.length > Constants.MAX_NICKNAME_LENGTH)
            revert Errors.NickNameLengthInvalid();
    }


    //Box
  uint256 private _value;


  // Stores a new value in the contract
  // owner可以为合约地址，由合约来调用
  function store(uint256 newValue) public onlyGov {
    console.log('_timeLock: ', _timeLock);
    console.log('manager store tx.origin: ', tx.origin);
    console.log('manager store caller: ', msg.sender);
    if (msg.sender == _governance || msg.sender == _timeLock)  {
        console.log('store: caller is governance or governanor');
    } else {
        revert Errors.NotGovernance();
    }

    _value = newValue;
    emit Events.ValueChanged(newValue, msg.sender);
  }

  // Reads the last stored value
  function retrieve() public view returns (uint256) {
    return _value;
  }
}
