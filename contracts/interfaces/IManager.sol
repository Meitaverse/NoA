// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';

/**
 * @title IManager
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the Manager contract
 */
interface IManager {
    /**
     * @notice Initializes the Manager, setting the initial governance address
     *
     * @param governance_ The address of Governance.
     */
    function initialize(    
       address governance_
    ) external;
    
    function getGlobalModule() external returns(address);

    function setGovernance(address newGovernance) external;

    function setTimeLock(address timeLock) external;

    function getGovernance() external returns(address);
    
    function getTimeLock() external returns(address);

    /**
     * @notice Sets a soulBoundTokenId's dispatcher via signature with the specified parameters.
     *
     * @param vars A SetDispatcherWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setDispatcherWithSig(DataTypes.SetDispatcherWithSigData calldata vars) external;

    /**
     * @notice Returns the dispatcher associated with a soulBoundToken.
     *         usually get  approve
     *
     * @param soulBoundToken The token ID of the profile to query the dispatcher for.
     *
     * @return address The dispatcher address associated with the profile.
     */
    function getDispatcher(uint256 soulBoundToken) external view returns (address);

    /**
     * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state. This function
     * can only be called by the governance address.
     *
     * @param newEmergencyAdmin The new emergency admin address to set.
     */
    function setEmergencyAdmin(address newEmergencyAdmin) external;

    /**
     * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state. This function
     * can only be called by the governance address or the emergency admin address.
     *
     * Note that this reverts if the emergency admin calls it if:
     *      1. The emergency admin is attempting to unpause.
     *      2. The emergency admin is calling while the protocol is already paused.
     *
     * @param newState The state to set, as a member of the ProtocolState enum.
    */
    function setState(DataTypes.ProtocolState newState) external;
    
    /**
     * @notice Sets the derivativeNFT state to either a global pause, a publishing pause or an unpaused state. This function
     * can only be called by the governance address
     *
     * @param projectId The project Id of derivativeNFT contract
     * @param newState The state to set, as a member of the DerivativeNFTState enum.
    */    
    function setDerivativeNFTState(
        uint256 projectId,
        DataTypes.DerivativeNFTState newState
    ) external;
    
    /**
     * @notice Sets the metadata descriptor of derivativeNFT contract. This function
     * can only be called by the governance address
     *
     * @param projectId The project Id of derivativeNFT contract
     * @param metadataDescriptor The state to set, as a member of the DerivativeNFTState enum.
    */   
    function setDerivativeNFTMetadataDescriptor(
       uint256 projectId, 
       address metadataDescriptor
    ) external;

    function mintSBTValue(
        uint256 soulBoundTokenId, 
        uint256 value
    ) external;

    function burnSBT(
        uint256 soulBoundTokenId
    )external;

    /**
     * @notice Creates a profile with the specified parameters, minting a profile NFT to the given recipient. This
     * function must be called by a whitelisted profile creator.
     *
     * @param vars A CreateProfileData struct containing the following params:
     *      to: The address receiving the profile.
     *      nickName: The nickName to set for the profile, must be unique and non-empty.
     *      imageURI: The URI to set for the profile image.
     */
    function createProfile(
        DataTypes.CreateProfileData calldata vars
    ) external returns (uint256);

    /**
     * @notice Returns the genesis publishId by projectId
     *
     * @param projectId The project Id
     * 
     * @return uin256 The tokenId of the SoulBundToken.
     */
    function getGenesisPublishIdByProjectId(uint256 projectId) external view returns(uint256);

    function getReceiver() external view returns (address);

    function getProjectIdByContract(address contract_) external view returns (uint256);

    /**
     * @notice get project infomation.
     * @param projectId_ The project Id
     * @return Project struct data.
     */
    function getProjectInfo(uint256 projectId_) external view returns (DataTypes.ProjectData memory);
    
    /**
     * @notice get publication infomation.
     * @param publishId_ The publish Id
     * @return Publish Data 
     */
    function getPublishInfo(uint256 publishId_) external view returns (DataTypes.PublishData memory);

    function getDerivativeNFT(uint256 projectId) external view returns (address);

    function getPublicationByTokenId(uint256 projectId_, uint256 tokenId_) external view returns (uint256, DataTypes.Publication memory);
    
    function getWalletBySoulBoundTokenId(uint256 soulBoundTokenId) external view returns(address);

    function getSoulBoundTokenIdByWallet(address wallet) external view returns(uint256);

    /**
     * @notice Sets a profile's dispatcher, giving that dispatcher rights to publish to that profile.
     *
     * @param profileId The token ID of the profile of the profile to set the dispatcher for.
     * @param dispatcher The dispatcher address to set for the given profile ID.
     */
    function setDispatcher(uint256 profileId, address dispatcher) external;


    function createHub(
        DataTypes.HubData memory hub
    ) external returns(uint256);

    function updateHub(
        uint256 soulBoundTokenId,
        string memory name,
        string memory description,
        string memory imageURI
    ) external;

    function createProject(
        DataTypes.ProjectData memory project
    ) external returns (uint256);

    /**
     * @notice Prepare publish a Publication
     *
     * @param publication  Data of Publication
     *
     * @return The new publish id
     */
    function prePublish(
        DataTypes.Publication memory publication
    ) external  returns (uint256);

    /**
     * @notice Hub owner set permit to publish
     *
     * @param publishId  The publish id
     * @param isPermit  True is permit, false not permit
     *
     */
    function hubOwnerPermitPublishId(
        uint256 publishId, 
        bool isPermit
    ) external; 

    
    /**
     * @notice Update a prepare pubish 
     *
     * @param publishId  The prepare publish id
     * @param salePrice  The new  sale price if need to update
     * @param royaltyBasisPoints  The proyalty basis points
     * @param amount  The new amount
     * @param name  The new name
     * @param description  The new description
     * @param materialURIs  The new materialURIs
     * @param fromTokenIds  The new fromTokenIds
     *
     */
    function updatePublish(
        uint256 publishId,
        uint256 salePrice,
        uint256 royaltyBasisPoints,        
        uint256 amount,
        string memory name,
        string memory description,
        string[] memory materialURIs,
        uint256[] memory fromTokenIds
    ) external;

    /**
     * @notice Publish some amount of dNFTs
     *
     * @param publishId publication id
     *
     */
    function publish(
        uint256 publishId
    ) external returns(uint256);

    /**
     * @notice collect a dNFT to a address.
     *
     * @param collectData collect Data
     *
     * @return The new token id of dNFT
     */
    function collect(
        DataTypes.CollectData memory collectData
    ) external returns(uint256);

    /**
     * @notice Airdrop array of values to many SBT Ids.
     * 
     * @param airdropData The airdrop data, only call by hub owner
     *     -- publishId : publish id
     *     -- ownershipSoulBoundTokenId: ownership of soulBoundTokenId
     *     -- toSoulBoundTokenIds: array SoulBoundTokenIds of to 
     *     -- tokenId: tokenId of dNFT
     *     -- values: array values 
     */ 
    function airdrop(
        DataTypes.AirdropData memory airdropData
    ) external;


    /**
     * @notice calculate royalty for ERC2981 market place
     *
     * @param publishId The publish Id
     *
     * @return The royalty taxes
     */
    function calculateRoyalty(uint256 publishId) external view returns(uint96);

}