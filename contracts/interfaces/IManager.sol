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
     * @param ndptV1_ The address of NDPT contract.
     * @param treasury_ The address of Treasury contract.
     */
    function initialize(    
       address governance_,
       address ndptV1_,
       address treasury_
    ) external;
   
  /**
   * @notice Sets the privileged governance role. This function can only be called by the current governance
   * address.
   *
   * @param newGovernance The new governance address to set.
   */
  function setGovernance(address newGovernance) external;

  function getGovernance() external returns(address);

    /**
     * @notice Sets a soulBoundTokenId's dispatcher, giving that dispatcher rights to publish to that profile.
     *
     * @param soulBoundTokenId The token ID of the profile of the profile to set the dispatcher for.
     * @param dispatcher The dispatcher address to set for the given profile ID.
     */
    function setDispatcher(uint256 soulBoundTokenId, address dispatcher) external;

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
   function setStateDerivative(address derivativeNFT, DataTypes.ProtocolState newState) external;

    function mintNDPT(
        address mintTo, 
        uint256 value
    ) external returns(uint256);

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
     *      handle: The handle to set for the profile, must be unique and non-empty.
     *      imageURI: The URI to set for the profile image.
     *      followModule: The follow module to use, can be the zero address.
     *      followModuleInitData: The follow module initialization data, if any.
     */
    function createProfile(DataTypes.CreateProfileData calldata vars, string memory nickName) external returns (uint256);

    /**
     * @notice Returns the follow module associated with a given soulBoundTokenId, if any.
     *
     * @param soulBoundTokenId The token ID of the SoulBoundToken to query the follow module for.
     *
     * @return address The address of the follow module associated with the given profile.
     */
    function getFollowModule(uint256 soulBoundTokenId) external view returns (address);

    /**
     * @notice Returns the address of the SoulBundToken contract
     *
     * @return address The address of the SoulBundToken contract.
     */
    function getSoulBoundToken() external view returns (address);

    /**
     * @notice Returns the address of the Incubator contract
     *
     * @param soulBoundTokenId The token ID of the SoulBoundToken to query the incubator for.
     * 
     * @return address The address of the SoulBundToken contract.
     */
    function getIncubatorOfSoulBoundTokenId(uint256 soulBoundTokenId) external view returns (address);
    
    /**
     * @notice Returns the tokenId of the Incubator contract by soulBoundTokenId
     *
     * @param soulBoundTokenId The token ID of the SoulBoundToken to query the incubator for.
     * 
     * @return uin256 The tokenId for the SoulBundToken contract.
     */
    function getTokenIdIncubatorOfSoulBoundTokenId(uint256 soulBoundTokenId) external view returns (uint256);
   
    /**
     * @notice Returns the soulBoundTokenId by registered wallet
     *
     * @param wallet The user wallet address.
     * 
     * @return uint256 The SoulBundToken id.
     */
    function getWalletBySoulBoundTokenId(address wallet) external view returns (uint256);
   
     
    /**
     * @notice Returns the genesis soulBoundTokenId by publishId
     *
     * @param publishId The publish Id
     * 
     * @return uin256 The tokenId of the SoulBundToken.
     */
    function getGenesisSoulBoundTokenIdByPublishId(uint256 publishId) external view returns(uint256);

    /**
     * @notice Returns the address of the Incubator contract implementation
     *
     * 
     * @return address The address of the implementation.
     */
    
    /**
     * @notice Returns the address of the Incubator NFT contract implementation
     *
     * 
     * @return address The address of the implementation.
     */
    function getIncubatorImpl() external view returns (address);
    
    /**
     * @notice Returns the address of the Derivative NFT contract implementation
     *
     * 
     * @return address The address of the implementation.
     */
    function getDNFTImpl() external view returns (address);

    function getReceiver() external view returns (address);


    /**
     * @notice Adds or removes a profile creator from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param profileCreator The profile creator address to add or remove from the whitelist.
     * @param whitelist Whether or not the profile creator should be whitelisted.
     */
    function whitelistProfileCreator(address profileCreator, bool whitelist) external;

    /**
     * @notice Follows the given project id, executing each SBT Id's follow module logic (if any).
     *
     * @param projectId The project Id 
     * @param soulBoundTokenId The soulBoundTokenId  of sender
     * @param data The arbitrary data  to pass to the follow module
     *
     */
    function follow(
        uint256 projectId,
        uint256 soulBoundTokenId,
        bytes calldata data
    ) external;

     function createHub(
        address creater, 
        uint256 soulBoundTokenId,
        DataTypes.Hub memory hub,
        bytes calldata createHubModuleData
    ) external;

    function createProject(
        uint256 hubId,
        uint256 soulBoundTokenId,
        DataTypes.Project memory project,
        address metadataDescriptor,
        bytes calldata projectModuleData
    ) external returns (uint256);

    /**
     * @notice get project infomation.
     * @param projectId_ The project Id
     * @return Project struct data.
     */
    function getProjectInfo(uint256 projectId_) external view returns (DataTypes.Project memory);
    
    function prePublish(
        DataTypes.Publication memory publication
    ) external  returns (uint256);

    function updatePublish(
        uint256 publishId,
        uint256 price,
        address currency,
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
     * @notice collect a dNFT to a address from incubator.
     *
     * @param collectData collect Data
     *
     * @return The new token id of dNFT
     */
    function collect(
        DataTypes.CollectData memory collectData
    ) external returns(uint256);

    function airdrop(
        DataTypes.AirdropData memory airdropData
    ) external ;

    /**
     * @notice Transfer a dNFT to a address from incubator.
     *
     * @param projectId Event Id  
     * @param fromSoulBoundTokenId From SBT Id  
     * @param toSoulBoundTokenId  to
     * @param tokenId The tokenId of dNFT.
     * @param transferModuledata The arbitrary data  to pass.
     *
     */
    function transferDerivativeNFT(
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        bytes calldata transferModuledata
    ) external;

    function transferValueDerivativeNFT(
        uint256 projectId,
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 tokenId,
        uint256 value,
        bytes calldata transferValueModuledata
    ) external;

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