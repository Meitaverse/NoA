// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IBankTreasury} from "../../interfaces/IBankTreasury.sol";
import {IPublishModule} from "../../interfaces/IPublishModule.sol";
import {Errors} from "../../libraries/Errors.sol";
import {FeeModuleBase} from "../FeeModuleBase.sol";
import {DataTypes} from '../../libraries/DataTypes.sol';
import {ModuleBase} from "../ModuleBase.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {IDerivativeNFTV1} from "../../interfaces/IDerivativeNFTV1.sol";

struct PublishData {
    DataTypes.Publication publication;
    bool isMinted;
    uint256 newTokenId;
}

/**
 * @title FeeCollectModule
 * @author Bitsoul Protocol
 *
 * @notice This is a simple dNFT CollectModule implementation, inheriting from the ICollectModule interface and
 * the FeeCollectModuleBase abstract contract.
 *
 * This module works by allowing unlimited collects for a publication at a given price.
 */
contract PublishModule is FeeModuleBase, IPublishModule, ModuleBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    //publishId =>PublishData
    mapping(uint256 => PublishData) internal _dataPublishdNFTByProject;

    constructor(address manager, address moduleGlobals) FeeModuleBase(moduleGlobals) ModuleBase(manager) {}

    // constructor(address moduleGlobals) override(FeeModuleBase, ModuleBase) {}


    /**
     * @notice Initializes data for a given publication being published. This can only be called by the manager.
     *
     * @param publishId The order ID of the the publication.
     * @param publication The Publication .
     *
     */
    function initializePublishModule(
        uint256 publishId,
        DataTypes.Publication calldata publication
    ) external override onlyManager {

        address treasury = _treasury();

        uint256 toSoulBoundTokenId = IBankTreasury(treasury).getSoulBoundTokenId();

        uint256 publishTaxes = (publication.amount - 1) * _PublishCurrencyTax(_ndpt());
       
        if ( publishTaxes > 0){
            IERC3525(_ndpt()).transferFrom(publication.soulBoundTokenId, toSoulBoundTokenId, publishTaxes);
        }
        _dataPublishdNFTByProject[publishId].publication = publication;

    }

    /**
     * @dev Processes a publish by publishId
     */
    function processPublish(
        uint256 publishId
    ) external virtual override onlyManager {
        // TODO
        _processPublish( publishId );
       
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param publishId The publishId to query.
     *
     * @return PublishData The PublishData struct mapped to that publication.
     */
    function getPublicationData(
        uint256 publishId
    ) external view returns (PublishData memory) {
        return _dataPublishdNFTByProject[publishId];
    }

    function _processPublish(uint256 publishId) internal returns(bytes memory) {
        //TODO return SVG template 
       return new bytes(0);
    }

}
