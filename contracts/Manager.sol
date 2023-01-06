// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
import {IDerivativeNFTV1} from "./interfaces/IDerivativeNFTV1.sol";
import "./interfaces/INFTDerivativeProtocolTokenV1.sol";
import "./interfaces/IManager.sol";
import "./base/DerivativeNFTMultiState.sol";
import {Constants} from './libraries/Constants.sol';
import {DataTypes} from './libraries/DataTypes.sol';
import {Events} from"./libraries/Events.sol";
import {InteractionLogic} from './libraries/InteractionLogic.sol';
import {PublishLogic} from './libraries/PublishLogic.sol';
import {PriceManager} from './libraries/PriceManager.sol';
import {ManagerStorage} from  "./storage/ManagerStorage.sol";
import "./libraries/SafeMathUpgradeable128.sol";
import {IBankTreasury} from "./interfaces/IBankTreasury.sol";
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {VersionedInitializable} from './upgradeability/VersionedInitializable.sol';
import {IModuleGlobals} from "./interfaces/IModuleGlobals.sol";

contract Manager is 
    IManager,
    DerivativeNFTMultiState,
    ManagerStorage,
    PriceManager,
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

    function mintNDPTValue(uint256 tokenId, uint256 value) external whenNotPaused onlyGov {
        address _ndpt = IModuleGlobals(MODULE_GLOBALS).getNDPT();
        INFTDerivativeProtocolTokenV1(_ndpt).mintValue(tokenId, value);
    }

    function burnNDPT(uint256 tokenId) external whenNotPaused onlyGov {
        address _ndpt = IModuleGlobals(MODULE_GLOBALS).getNDPT();
        INFTDerivativeProtocolTokenV1(_ndpt).burn(tokenId);
    }

    function burnNDPTValue(uint256 tokenId, uint256 value) external whenNotPaused onlyGov {
         address _ndpt = IModuleGlobals(MODULE_GLOBALS).getNDPT();
        INFTDerivativeProtocolTokenV1(_ndpt).burnValue(tokenId, value);
    }

    function createProfile(
        DataTypes.CreateProfileData calldata vars
    ) external whenNotPaused returns (uint256) {
        address _ndpt = IModuleGlobals(MODULE_GLOBALS).getNDPT();
        if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistProfileCreator(vars.wallet)) revert Errors.ProfileCreatorNotWhitelisted();
        if (_ndpt == address(0)) revert Errors.NDPTNotSet();

        uint256 soulBoundTokenId = INFTDerivativeProtocolTokenV1(_ndpt).createProfile(msg.sender, vars);

        _walletBySoulBoundTokenId[soulBoundTokenId] = vars.wallet;

        return soulBoundTokenId;
    }

    function createHub(
        DataTypes.HubData memory hub
    ) external whenNotPaused returns(uint256){
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(hub.soulBoundTokenId);

        if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistHubCreator(hub.soulBoundTokenId)) revert Errors.HubCreatorNotWhitelisted();
       
        uint256 hubId = _generateNextHubId();
        _hubBySoulBoundTokenId[hub.soulBoundTokenId] = hubId;

        InteractionLogic.createHub(
            msg.sender,
            hubId,
            hub, 
            _hubInfos
        );

        return hubId; 
    }
 
    function createProject(
        DataTypes.ProjectData memory project
    ) external whenNotPaused returns (uint256) {
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(project.soulBoundTokenId);
        
        if (_hubBySoulBoundTokenId[project.soulBoundTokenId] != project.hubId) revert Errors.NotHubOwner();
        if (_projectNameHashByEventId[keccak256(bytes(project.name))] > 0) {
            revert Errors.ProjectExisted();
        }
        uint256 projectId = _generateNextProjectId();
        _projectNameHashByEventId[keccak256(bytes(project.name))] = projectId;
        InteractionLogic.createProject(
            _DNFT_IMPL,
            IModuleGlobals(MODULE_GLOBALS).getNDPT(),
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
        uint256 projectid = _publishIdByProjectData[publishId].publication.projectId;
        uint256 previousPublishId = _publishIdByProjectData[publishId].previousPublishId;
        (, uint16 treasuryFee ) = IModuleGlobals(MODULE_GLOBALS).getTreasuryData();

        // fraction = community treasuryFee + genesisFee + previous dNDT fee
        uint96 fraction = 
            uint96(treasuryFee) + 
            uint96(_publishIdByProjectData[_genesisPublishIdByProjectId[projectid]].publication.royaltyBasisPoints) +
            uint96(_publishIdByProjectData[previousPublishId].publication.royaltyBasisPoints);

        return fraction;
    }
 
    //prepare publish
    function prePublish(
        DataTypes.Publication memory publication
    ) external override whenNotPaused returns (uint256) { 
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(publication.soulBoundTokenId);

        _validateSameHub(publication.hubId, publication.projectId);

        if (publication.amount == 0) revert Errors.InvalidParameter();

        //user combo 
        if (_hubBySoulBoundTokenId[publication.soulBoundTokenId] != publication.hubId && 
                publication.fromTokenIds.length == 0)  {
            revert Errors.InsufficientDerivativeNFT();
        }

        if (_derivativeNFTByProjectId[publication.projectId] == address(0)) revert Errors.InvalidParameter();

        uint256 previousPublishId;
        uint256 publishId = _generateNextPublishId();
        if (publication.fromTokenIds.length == 0){
            previousPublishId = 0;
            //save genesisPublishId for this projectId 
            _genesisPublishIdByProjectId[publication.projectId] = publishId;

        } else{
            previousPublishId = _tokenIdByPublishId[publication.fromTokenIds[0]];
        }
        
        if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistPublishModule(publication.publishModule))
            revert Errors.PublishModuleNotWhitelisted();

        uint256 treasuryOfSoulBoundTokenId = IBankTreasury(IModuleGlobals(MODULE_GLOBALS).getTreasury()).getSoulBoundTokenId();
        PublishLogic.prePublish(
            publication,
            publishId,
            previousPublishId,
            treasuryOfSoulBoundTokenId,
            _publishIdByProjectData
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
    ) external override whenNotPaused {  
        if (publishId == 0) revert Errors.InvalidParameter();
        if (amount == 0) revert Errors.InvalidParameter();
        if (_publishIdByProjectData[publishId].publication.amount < amount) revert Errors.AmountOnlyIncrease();

        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(_publishIdByProjectData[publishId].publication.soulBoundTokenId);

        if (_publishIdByProjectData[publishId].isMinted) revert Errors.CannotUpdateAfterMinted();
        
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
            _publishIdByProjectData
        );
    }

    function getPublishInfo(uint256 publishId_) external view returns (DataTypes.PublishData memory) {
        return _publishIdByProjectData[publishId_];
    }
 
    function getDerivativeNFT(uint256 projectId) external view returns (address) {
        return _derivativeNFTByProjectId[projectId];
    }

    function getPublicationByTokenId(uint256 tokenId_) external view returns (DataTypes.Publication memory) {
       uint256 publishId = _tokenIdByPublishId[tokenId_];
       return _publishIdByProjectData[publishId].publication;
    }

    function publish(
        uint256 publishId
    ) external whenNotPaused returns (uint256) { 
        if (publishId == 0) {
            revert Errors.InitParamsInvalid();
        } else {

            _validateCallerIsSoulBoundTokenOwnerOrDispathcher(_publishIdByProjectData[publishId].publication.soulBoundTokenId);
            address publisher = _walletBySoulBoundTokenId[_publishIdByProjectData[publishId].publication.soulBoundTokenId];
            address derivativeNFT = _derivativeNFTByProjectId[_publishIdByProjectData[publishId].publication.projectId];
            if (_publishIdByProjectData[publishId].publication.amount == 0) revert Errors.InitParamsInvalid();
            
            if (!IModuleGlobals(MODULE_GLOBALS).isWhitelistCollectModule(_publishIdByProjectData[publishId].publication.collectModule))
                revert Errors.CollectModuleNotWhitelisted();
        
            uint256 newTokenId = PublishLogic.createPublish(
                _publishIdByProjectData[publishId].publication,
                publishId,
                publisher,
                derivativeNFT,
                _pubByIdByProfile
            );

            //Avoids stack too deep
            {
                _publishIdByProjectData[publishId].isMinted = true;
                _publishIdByProjectData[publishId].tokenId = newTokenId;
                _tokenIdByPublishId[newTokenId] = publishId;
            }

            return newTokenId;
        }
    }

    function collect(
        DataTypes.CollectData memory collectData
    ) external whenNotPaused returns(uint256){

         _validateCallerIsSoulBoundTokenOwnerOrDispathcher(collectData.collectorSoulBoundTokenId);

        address derivativeNFT =  _derivativeNFTByProjectId[_publishIdByProjectData[collectData.publishId].publication.projectId];

        uint256 newTokenId = IDerivativeNFTV1(derivativeNFT).split(
            collectData.publishId, 
            _publishIdByProjectData[collectData.publishId].tokenId, 
            _walletBySoulBoundTokenId[collectData.collectorSoulBoundTokenId],
            collectData.collectValue
        );

        PublishLogic.collectDerivativeNFT(
            collectData,
            _publishIdByProjectData[collectData.publishId].tokenId,
            newTokenId,
            _derivativeNFTByProjectId[_publishIdByProjectData[collectData.publishId].publication.projectId],
            _pubByIdByProfile,
            _publishIdByProjectData
        );

        return newTokenId;    
    }

    function airdrop(
        DataTypes.AirdropData memory airdropData
    ) external override whenNotPaused{
         _validateCallerIsSoulBoundTokenOwnerOrDispathcher(airdropData.ownershipSoulBoundTokenId);
        
        address derivativeNFT = _derivativeNFTByProjectId[_publishIdByProjectData[airdropData.publishId].publication.projectId];

        PublishLogic.airdrop(
            derivativeNFT, 
            airdropData,
            _walletBySoulBoundTokenId,
            _tokenIdByPublishId,
            _publishIdByProjectData
        );
    }

    function transferDerivativeNFT(
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId
    ) external whenNotPaused  {
         _validateCallerIsSoulBoundTokenOwnerOrDispathcher(fromSoulBoundTokenId);
        address derivativeNFT = _derivativeNFTByProjectId[projectId];
        if (derivativeNFT == address(0)) revert Errors.InvalidParameter();

        address fromWallet = _walletBySoulBoundTokenId[fromSoulBoundTokenId];
        if (fromWallet == address(0)) revert Errors.InvalidParameter();

        address toWallet = _walletBySoulBoundTokenId[toSoulBoundTokenId];
        if (toWallet == address(0)) revert Errors.InvalidParameter();

        //must approve manager before
        IERC3525(derivativeNFT).transferFrom(fromWallet, toWallet, tokenId);

        emit Events.TransferDerivativeNFT(
            fromSoulBoundTokenId,
            toSoulBoundTokenId,
            projectId,
            tokenId,
            block.timestamp
        );
    } 

    function transferValueDerivativeNFT(
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value
    ) external whenNotPaused {
         _validateCallerIsSoulBoundTokenOwnerOrDispathcher(fromSoulBoundTokenId);
        address derivativeNFT = _derivativeNFTByProjectId[projectId];
        if (derivativeNFT == address(0)) revert Errors.InvalidParameter();

        address toWallet = _walletBySoulBoundTokenId[toSoulBoundTokenId];
        if (toWallet == address(0)) revert Errors.InvalidParameter();

        //must approve manager before
        uint256 newTokenId = IERC3525(derivativeNFT).transferFrom(tokenId, toWallet, value);

        emit Events.TransferValueDerivativeNFT(
            fromSoulBoundTokenId,
            toSoulBoundTokenId,
            projectId,
            tokenId,
            value,
            newTokenId,
            block.timestamp
        );
    }

    function setProfileImageURI(uint256 soulBoundTokenId, string calldata imageURI)
        external
        whenNotPaused
    {
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(soulBoundTokenId);
        INFTDerivativeProtocolTokenV1(IModuleGlobals(MODULE_GLOBALS).getNDPT()).setProfileImageURI(soulBoundTokenId, imageURI);
    }

//market

    function publishFixedPrice(DataTypes.Sale memory sale) external whenNotPaused onlyGov {
        uint24 saleId = _generateNextSaleId();
        _derivativeNFTSales[sale.derivativeNFT].add(saleId);
        //TODO
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
         _validateCallerIsSoulBoundTokenOwnerOrDispathcher(soulBoundTokenId);
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

    function getGenesisSoulBoundTokenIdByPublishId(uint256 publishId) external view returns(uint256) {
       return _genesisPublishIdByProjectId[publishId];   
    }

    function getHubInfo(uint256 hubId) external view returns(DataTypes.HubData memory) {
        return _hubInfos[hubId];
    }

    function getWalletBySoulBoundTokenId(uint256 soulBoundTokenId) external view returns(address) {
        return _walletBySoulBoundTokenId[soulBoundTokenId];
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

    function setGovernance(address newGovernance) external onlyGov {
        _setGovernance(newGovernance);
    }

    function getGovernance() external view returns(address) {
        return _governance;
    }

    function setGlobalModule(address moduleGlobals) external onlyGov {
        if (moduleGlobals == address(0)) revert Errors.InitParamsInvalid();
        MODULE_GLOBALS = moduleGlobals;
        _walletBySoulBoundTokenId[1] = IModuleGlobals(MODULE_GLOBALS).getTreasury();
    }

    function getGlobalModule() external view returns(address) {
        return MODULE_GLOBALS;
    }

    function getDispatcher(uint256 soulBoundToken) external view override returns (address) {
        return _dispatcherByProfile[soulBoundToken];
    }

    function setDispatcherWithSig(DataTypes.SetDispatcherWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        address _ndpt = IModuleGlobals(MODULE_GLOBALS).getNDPT();
        address owner = IERC3525(_ndpt).ownerOf(vars.soulBoundTokenId);
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
         address _ndpt = IModuleGlobals(MODULE_GLOBALS).getNDPT();
         if (IERC3525(_ndpt).ownerOf(soulBoundTokenId_) == msg.sender || _dispatcherByProfile[soulBoundTokenId_] == msg.sender) {
            return;
         }
         revert Errors.NotProfileOwnerOrDispatcher();
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
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

}
