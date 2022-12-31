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
     * @notice Initializes the Manager, setting the initial governance address and receiver address
     *
     * @param governance_ The address of Governance.
     */
    function initialize(    
       address governance_
    ) external;
   
  /**
   * @notice Sets the privileged governance role. This function can only be called by the current governance
   * address.
   *
   * @param newGovernance The new governance address to set.
   */
  function setGovernance(address newGovernance) external;
    
  function setNDPT(address ndpt) external;

  function setTreasury(address treasury) external;

  function setGlobalModule(address moduleGlobals) external;

  function getGovernance() external returns(address);

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
 
    function mintNDPTValue(
        uint256 tokenId, 
        uint256 value
    ) external;

   function burnNDPT(
        uint256 tokenId
   )external;

    function burnNDPTValue(
        uint256 tokenId,
        uint256 value
    ) external;
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

    
    function setProfileImageURI(uint256 soulBoundTokenId, string calldata imageURI) external;

    /**
     * @notice Returns the address of the SoulBundToken contract
     *
     * @return address The address of the SoulBundToken contract.
     */
    function getSoulBoundToken() external view returns (address);


    /**
     * @notice Returns True if in whitelist, otherwise false
     *
     * @param profileCreator The user wallet address.
     * 
     * @return bool where is in whitelist
     */
    function isWhitelistProfileCreator(address profileCreator) external view returns(bool);

    /**
     * @notice Returns the genesis soulBoundTokenId by publishId
     *
     * @param publishId The publish Id
     * 
     * @return uin256 The tokenId of the SoulBundToken.
     */
    function getGenesisSoulBoundTokenIdByPublishId(uint256 publishId) external view returns(uint256);

    function getReceiver() external view returns (address);


    /**
     * @notice Adds or removes a profile creator from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param profileCreator The profile creator address to add or remove from the whitelist.
     * @param whitelist Whether or not the profile creator should be whitelisted.
     */
    function whitelistProfileCreator(address profileCreator, bool whitelist) external;

    function createHub(
        DataTypes.HubData memory hub
    ) external returns(uint256);

    function createProject(
        DataTypes.ProjectData memory project
    ) external returns (uint256);

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

    function getPublicationByTokenId(uint256 tokenId_) external view returns (DataTypes.Publication memory);
    
    function getWalletBySoulBoundTokenId(uint256 soulBoundTokenId) external view returns(address);

    function prePublish(
        DataTypes.Publication memory publication
    ) external  returns (uint256);

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
     * @notice Transfer a dNFT to a address.
     *
     * @param projectId Event Id  
     * @param fromSoulBoundTokenId From SBT Id  
     * @param toSoulBoundTokenId  to
     * @param tokenId The tokenId of dNFT.
     *
     */
    function transferDerivativeNFT(
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId
    ) external;

    function transferValueDerivativeNFT(
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value
    ) external;

    function calculateRoyalty(uint256 publishId) external view returns(uint96);

    function publishFixedPrice(
        DataTypes.Sale memory sale
    ) external;

    function removeSale(
        uint24 saleId_
    ) external;

    function addMarket(
        address derivativeNFT_,
        uint64 precision_,
        uint8 feePayType_,
        uint8 feeType_,
        uint128 feeAmount_,
        uint16 feeRate_
    ) external;

    function removeMarket(
        address derivativeNFT_
    ) external;

    function buyUnits(
        uint256 soulBoundTokenId,
        address buyer,
        uint24 saleId, 
        uint128 units
    )  external payable returns (uint256 amount, uint128 fee);

    /**
     * @notice Adds or removes a collect module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param collectModule The collect module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the collect module should be whitelisted.
     */
    function whitelistCollectModule(address collectModule, bool whitelist) external;

    /**
     * @notice Adds or removes a publish module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param publishModule The publish module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the publish module should be whitelisted.
     */
    function whitelistPublishModule(address publishModule, bool whitelist) external;

}