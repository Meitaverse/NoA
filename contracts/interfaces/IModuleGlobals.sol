// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title IModuleGlobals
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the ModuleGlobals contract, a data providing contract to be queried by modules
 * for the most up-to-date parameters.
 */
interface IModuleGlobals {
    /**
     * @notice Sets the governance address. This function can only be called by governance.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external;
    
    function setManager(address newManager) external;
    
    function setSBT(address newSBT) external;

    /**
     * @notice Sets the treasury address. This function can only be called by governance.
     *
     * @param newTreasury The new treasury address to set.
     */
    function setTreasury(address newTreasury) external;

    function setMarketPlace(address newMarketPlace) external;

    function setVoucher(address newVoucher) external;

    /**
     * @notice Sets the treasury fee. This function can only be called by governance.
     *
     * @param newTreasuryFee The new treasury fee to set.
     */
    function setTreasuryFee(uint16 newTreasuryFee) external;

    /**
     * @notice Adds or removes a currency from the whitelist. This function can only be called by governance.
     *
     * @param currency The currency to add or remove from the whitelist.
     * @param toWhitelist Whether to add or remove the currency from the whitelist.
     */
    // function whitelistCurrency(address currency, bool toWhitelist) external;

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************

    /**
     * @notice Returns the manager address.
     *
     * @return address The manager address.
     */
     function getManager() external view returns (address);

    /**
     * @notice Returns the governance address.
     *
     * @return address The governance address.
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Returns the treasury address.
     *
     * @return address The treasury address.
     */
    function getTreasury() external view returns (address);

    function getVoucher() external view  returns (address);

    /**
     * @notice Returns the SBT address.
     *
     * @return address The treasury address.
     */
    function getSBT() external view returns (address);
    
    function getMarketPlace() external view returns (address);
    
    /**
     * @notice Returns the treasury fee.
     *
     * @return uint16 The treasury fee.
     */
    function getTreasuryFee() external view returns (uint16);

    /**
     * @notice Returns the treasury address and treasury fee in a single call.
     *
     * @return tuplee First, the treasury address, second, the treasury fee.
     */
    function getTreasuryData() external view returns (address, uint16);
    
    function getWallet(uint256 soulBoundTokenId) external view returns (address);
    
    function getPublishCurrencyTax() external returns(uint256) ;

    function setPublishRoyalty(uint256 publishRoyalty) external;

    /**
     * @notice Adds or removes a profile creator from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param profileCreator The profile creator address to add or remove from the whitelist.
     * @param whitelist Whether or not the profile creator should be whitelisted.
     */
    function whitelistProfileCreator(address profileCreator, bool whitelist) external;


    function isWhitelistProfileCreator(address profileCreator) external view returns (bool);

     /**
     * @notice Adds or removes a collect module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param collectModule The collect module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the collect module should be whitelisted.
     */
    function whitelistCollectModule(address collectModule, bool whitelist) external;

    function isWhitelistCollectModule(address collectModule) external view returns (bool);

    /**
     * @notice Adds or removes a template from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param template The collect module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the collect module should be whitelisted.
     */
    function whitelistTemplate(address template, bool whitelist) external;

    function isWhitelistTemplate(address template) external view returns (bool);

    function whitelistHubCreator(uint256 soulBoundTokenId, bool whitelist) external;

    function isWhitelistHubCreator(uint256 soulBoundTokenId) external view returns (bool);


    /**
     * @notice Adds or removes a publish module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param publishModule The publish module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the publish module should be whitelisted.
     */
    function whitelistPublishModule(address publishModule, bool whitelist) external;

    function isWhitelistPublishModule(address publishModule) external view returns (bool);

}
