// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';
/**
 * @title IPublishModule
 * @author Bitsoul Protocol
 *
 * @notice This is the standard interface for all Bitsoul-compatible CommunityModules.
 */
interface IPublishModule {
    /**
     * @notice Initializes data for a given publication being published. This can only be called by the manager.
     *
     * @param publishId The publish ID.
     * @param previousPublishId The previous Publish Id
     * @param treasuryOfSoulBoundTokenId The SoulBoundTokenId of treasury
     * @param publication The publication
     *
     * @return tax
     */
    function initializePublishModule(
        uint256 publishId,
        uint256 previousPublishId,
        uint256 treasuryOfSoulBoundTokenId,
        DataTypes.Publication calldata publication
    ) external returns(uint256);
    

    /**
     * @notice update publish data. This can only be called by the manager.
     *         If amount is large than old amount, should tranfer value to bank treasury
     * @param publishId The publish ID.
     * @param salePrice The new sale price
     * @param royaltyBasisPoints The royalty basis points
     * @param amount The new amount, only increase
     * @param name The new name
     * @param description The new description
     * @param materialURIs The new materialURIs
     * @param fromTokenIds The new fromTokenIds
     *
     */ 
    function updatePublish(
        uint256 publishId,
        uint256 salePrice,
        uint16 royaltyBasisPoints,
        uint256 amount,
        string memory name,
        string memory description,
        string[] memory materialURIs,
        uint256[] memory fromTokenIds
    ) external returns(uint256);

    function getPublicationTemplate(
        uint256 publishId
    ) external view returns (uint256, string memory);

    // function getTreasuryOfSoulBoundTokenId() external view returns(uint256);

}


