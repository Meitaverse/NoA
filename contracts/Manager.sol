// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
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
    // using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    using SafeMathUpgradeable128 for uint128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using Counters for Counters.Counter;

    uint256 internal constant REVISION = 1;

    mapping(address => uint256) public sigNonces;
    address internal immutable  _DNFT_IMPL;
    address internal immutable  _RECEIVER;

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
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

    function initialize(
        address governance_
    ) external override initializer {
        //default Paused
        _setState(DataTypes.ProtocolState.Paused);
        _setGovernance(governance_);
    }

    //-- external -- //
    function getReceiver() external view returns (address) {
        return _RECEIVER;
    }

    function whitelistProfileCreator(address profileCreator, bool whitelist) external override onlyGov {
        _profileCreatorWhitelisted[profileCreator] = whitelist;
        emit Events.ProfileCreatorWhitelisted(profileCreator, whitelist, block.timestamp);
    }

    function isWhitelistProfileCreator(address profileCreator) external view returns(bool) {
       return  _profileCreatorWhitelisted[profileCreator];
    }

    function setStateDerivative(address derivativeNFT, DataTypes.ProtocolState newState) external override onlyGov {
        IDerivativeNFTV1(derivativeNFT).setState(newState);
    }

    function mintNDPTValue(uint256 tokenId, uint256 value) external whenNotPaused onlyGov {
        INFTDerivativeProtocolTokenV1(NDPT).mintValue(tokenId, value);
    }

    function burnNDPT(uint256 tokenId) external whenNotPaused onlyGov {
        INFTDerivativeProtocolTokenV1(NDPT).burn(tokenId);
    }

    function burnNDPTValue(uint256 tokenId, uint256 value) external whenNotPaused onlyGov {
        INFTDerivativeProtocolTokenV1(NDPT).burnValue(tokenId, value);
    }

    function createProfile(
        DataTypes.CreateProfileData calldata vars
    ) external whenNotPaused returns (uint256) {
        if (!_profileCreatorWhitelisted[msg.sender]) revert Errors.ProfileCreatorNotWhitelisted();
        if (NDPT == address(0)) revert Errors.NDPTNotSet();

        uint256 soulBoundTokenId = INFTDerivativeProtocolTokenV1(NDPT).createProfile(vars);

        _walletBySoulBoundTokenId[soulBoundTokenId] = msg.sender;

        return soulBoundTokenId;
    }

    function createHub(
        DataTypes.HubData memory hub
    ) external whenNotPaused returns(uint256){
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(hub.soulBoundTokenId);
       
        uint256 hubId = _generateNextHubId();
        _hubBySoulBoundTokenId[hub.soulBoundTokenId] = hubId;

        InteractionLogic.createHub(
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
        address derivativeNFT = InteractionLogic.createProject(
            _DNFT_IMPL,
            NDPT,
            TREASURY,
            projectId,
            project,
            _RECEIVER,
            _derivativeNFTByProjectId 
        );

        // set default royalty to 50/10000
        IDerivativeNFTV1(derivativeNFT).setDefaultRoyalty(TREASURY, 50); 

        _projectInfoByProjectId[projectId] = DataTypes.ProjectData({
            hubId: project.hubId,
            soulBoundTokenId: project.soulBoundTokenId,
            name: project.name,
            description: project.description,
            image: project.image,
            metadataURI: project.metadataURI,
            descriptor: project.descriptor
        });

        return projectId;
    }

    function getProjectInfo(uint256 projectId_) external view returns (DataTypes.ProjectData memory) {
        return _projectInfoByProjectId[projectId_];
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

        uint256 previousPublishId ;
        uint256 publishId =  _generateNextPublishId();
        if (publication.fromTokenIds.length == 0){
            previousPublishId = 0;
            //记录projectId的创世者
            _genesisPublishIdByProjectId[publication.projectId] = publishId;

        } else{
            previousPublishId = _tokenIdByPublishId[publication.fromTokenIds[0]];
        }
        
        uint256 treasuryOfSoulBoundTokenId = IBankTreasury(TREASURY).getSoulBoundTokenId();
        PublishLogic.prePublish(
            publication,
            publishId,
            previousPublishId,
            treasuryOfSoulBoundTokenId,
            _publishModuleWhitelisted,
            _publishIdByProjectData
        );

       

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

        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(_publishIdByProjectData[publishId].publication.soulBoundTokenId);

        if (_publishIdByProjectData[publishId].isMinted) revert Errors.CannotUpdateAfterMinted();

        _publishIdByProjectData[publishId].publication.salePrice = salePrice;
        _publishIdByProjectData[publishId].publication.royaltyBasisPoints = royaltyBasisPoints;
        _publishIdByProjectData[publishId].publication.amount = amount;
        _publishIdByProjectData[publishId].publication.name = name;
        _publishIdByProjectData[publishId].publication.description = description;
        _publishIdByProjectData[publishId].publication.materialURIs = materialURIs;
        _publishIdByProjectData[publishId].publication.fromTokenIds = fromTokenIds;

    }

    function getPublishInfo(uint256 publishId_) external view returns (DataTypes.PublishData memory) {
        return _publishIdByProjectData[publishId_];
    }
 
    function getDerivativeNFT(uint256 publishId_) external view returns (address) {
        return _derivativeNFTByProjectId[publishId_];
    }
    

    function getPublicationByTokenId(uint256 tokenId_) external view returns (DataTypes.Publication memory) {
       uint256 publishId = _tokenIdByPublishId[tokenId_];
       return _publishIdByProjectData[publishId].publication;
    }

    function getPreviousByTokenId(uint256 tokenId_) external view returns (uint256, uint256) {
       uint256 publishId = _tokenIdByPublishId[tokenId_];
       uint256 previousPublishId = _publishIdByProjectData[publishId].previousPublishId;
       uint256 prevoidTokenId =  _publishIdByProjectData[previousPublishId].tokenId;
       return (previousPublishId, prevoidTokenId);
    }
 
    function publish(
        uint256 publishId
    ) external whenNotPaused returns (uint256) { 
        if (publishId == 0) revert Errors.InitParamsInvalid();
        
        _validateCallerIsSoulBoundTokenOwnerOrDispathcher(_publishIdByProjectData[publishId].publication.soulBoundTokenId);
        address publisher = _walletBySoulBoundTokenId[_publishIdByProjectData[publishId].publication.soulBoundTokenId];
       
        if (publisher == address(0)) revert Errors.PublisherIsZero();

        address derivativeNFT = _derivativeNFTByProjectId[_publishIdByProjectData[publishId].publication.projectId];
        if (derivativeNFT == address(0)) revert Errors.DerivativeNFTIsZero();
        
        if (_publishIdByProjectData[publishId].publication.amount == 0) revert Errors.InitParamsInvalid();
        
        uint256 tokenId = PublishLogic.createPublish(
            _publishIdByProjectData[publishId].publication,
            publishId,
            publisher,
            derivativeNFT,
            _pubByIdByProfile,
            _collectModuleWhitelisted 
        );

        //TODO
        uint256 projectid = _publishIdByProjectData[publishId].publication.projectId;
        uint256 previousPublishId = _publishIdByProjectData[publishId].previousPublishId;
        (, uint16 treasuryFee ) = IModuleGlobals(MODULE_GLOBALS).getTreasuryData();

        // treasuryFee = community fee + genesis fee + previous dNDT fee
        uint96 fraction = 
            uint96(treasuryFee) + 
            uint96(_publishIdByProjectData[_genesisPublishIdByProjectId[projectid]].publication.royaltyBasisPoints) +
            uint96(_publishIdByProjectData[previousPublishId].publication.royaltyBasisPoints);


        IDerivativeNFTV1(derivativeNFT).setTokenRoyalty(
            tokenId,
            TREASURY,
            fraction
        );

        _publishIdByProjectData[publishId].isMinted = true;
        _publishIdByProjectData[publishId].tokenId = tokenId;

        _tokenIdByPublishId[tokenId] = publishId;

        return tokenId;

    }

    function collect(
        DataTypes.CollectData memory collectData
    ) external whenNotPaused returns(uint256){
        if (collectData.publishId == 0) revert Errors.InitParamsInvalid();
        if (collectData.collectorSoulBoundTokenId == 0) revert Errors.InitParamsInvalid();
        if (collectData.collectValue == 0) revert Errors.InitParamsInvalid();

         _validateCallerIsSoulBoundTokenOwnerOrDispathcher(collectData.collectorSoulBoundTokenId);

        address derivativeNFT =  _derivativeNFTByProjectId[_publishIdByProjectData[collectData.publishId].publication.projectId];

        if ( derivativeNFT== address(0)) 
            revert Errors.DerivativeNFTIsZero();
        
        uint256 newTokenId = IDerivativeNFTV1(derivativeNFT).split(
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
        if (derivativeNFT == address(0)) revert Errors.InvalidParameter();
       
        address from_ = _walletBySoulBoundTokenId[airdropData.ownershipSoulBoundTokenId];

        if (IERC3525(derivativeNFT).ownerOf(airdropData.tokenId) != from_) {
            revert Errors.NotOwerOFTokenId();
        }

        uint256[] memory newTokenIds = new uint256[](airdropData.toSoulBoundTokenIds.length);
        uint256 total;
        for (uint256 i = 0; i < airdropData.toSoulBoundTokenIds.length; ) {
            address toWallet = _walletBySoulBoundTokenId[airdropData.toSoulBoundTokenIds[i]];
            if (toWallet == address(0)) revert Errors.ToWalletIsZero();
            uint256 newTokenId = IDerivativeNFTV1(derivativeNFT).split(
                airdropData.tokenId, 
                toWallet,
                airdropData.values[i]
            );
           
            newTokenIds[i] = newTokenId;
            total = total +  airdropData.values[i];

            unchecked {
                ++i;
            }
        }

        emit Events.AirdropDerivativeNFT(
            _publishIdByProjectData[airdropData.publishId].publication.projectId,
            derivativeNFT,
            airdropData.ownershipSoulBoundTokenId,
            msg.sender,
            airdropData.tokenId,
            airdropData.values,
            newTokenIds,
            block.timestamp
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
        INFTDerivativeProtocolTokenV1(NDPT).setProfileImageURI(soulBoundTokenId, imageURI);
    }

//market
    function publishFixedPrice(DataTypes.Sale memory sale) external whenNotPaused onlyGov {
        uint24 saleId = _generateNextSaleId();
        _derivativeNFTSales[sale.derivativeNFT].add(saleId);
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


    function getSoulBoundToken() external view returns (address) {
        return NDPT;
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

    function setNDPT(address ndpt) external override onlyGov {
        if (ndpt == address(0)) revert Errors.InitParamsInvalid();
         NDPT = ndpt;
         _walletBySoulBoundTokenId[1] = ndpt;
    }
     
    function setTreasury(address treasury) external override onlyGov {
        if (treasury == address(0)) revert Errors.InitParamsInvalid();
        TREASURY = treasury;
    }

    function setGlobalModule(address moduleGlobals) external override onlyGov {
        if (moduleGlobals == address(0)) revert Errors.InitParamsInvalid();
        MODULE_GLOBALS = moduleGlobals;
    }

    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    function getGovernance() external view returns(address) {
        return _governance;
    }

    function getDispatcher(uint256 soulBoundToken) external view override returns (address) {
        return _dispatcherByProfile[soulBoundToken];
    }


    // function setDispatcher(uint256 soulBoundTokenId, address dispatcher) external override whenNotPaused {
    //     _validateCallerIsSoulBoundTokenOwnerOrDispathcher(soulBoundTokenId);
    //     _setDispatcher(soulBoundTokenId, dispatcher);
    // }

    function setDispatcherWithSig(DataTypes.SetDispatcherWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
        address owner = IERC3525(NDPT).ownerOf(vars.soulBoundTokenId);
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

    function whitelistCollectModule(address collectModule, bool whitelist)
        external
        override
        onlyGov
    {
        _collectModuleWhitelisted[collectModule] = whitelist;
        emit Events.CollectModuleWhitelisted(collectModule, whitelist, block.timestamp);
    }

    function whitelistPublishModule(address publishModule, bool whitelist)
        external
        override
        onlyGov
    {
        _publishModuleWhitelisted[publishModule] = whitelist;
        emit Events.PublishModuleWhitelisted(publishModule, whitelist, block.timestamp);
    }

    //--- internal  ---//
    function  _validateCallerIsSoulBoundTokenOwnerOrDispathcher(uint256 soulBoundTokenId_) internal view {
         if (IERC3525(NDPT).ownerOf(soulBoundTokenId_) == msg.sender || _dispatcherByProfile[soulBoundTokenId_] == msg.sender) {
            return;
         }
         revert Errors.NotProfileOwnerOrDispatcher();
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
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
                    keccak256(bytes(IERC3525Metadata(NDPT).name())),
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
