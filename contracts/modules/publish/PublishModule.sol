// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IBankTreasury} from "../../interfaces/IBankTreasury.sol";
import {IPublishModule} from "../../interfaces/IPublishModule.sol";
import {Errors} from "../../libraries/Errors.sol";
import {FeeModuleBase} from "../FeeModuleBase.sol";
import {DataTypes} from '../../libraries/DataTypes.sol';
import {ModuleBase} from "../ModuleBase.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {IDerivativeNFTV1} from "../../interfaces/IDerivativeNFTV1.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import {StringConvertor} from "../../utils/StringConvertor.sol";
import {ITemplate} from "../../interfaces/ITemplate.sol";

struct PublishData {
    DataTypes.Publication publication;
}

/**
 * @title PublishModule
 * @author Bitsoul Protocol
 *
 * @notice This is a simple dNFT PublishModule implementation, inheriting from the IPublishModule interface and
 * the FeeModuleBase abstract contract.
 *
 * This module works by allowing unlimited Publishs for a publication at a given price.
 */
contract PublishModule is FeeModuleBase, IPublishModule, ModuleBase {
    // using SafeERC20Upgradeable for IERC20Upgradeable;
    using StringConvertor for uint256;
    using StringConvertor for bytes;

    //publishId => PublishData
    mapping(uint256 => PublishData) internal _dataPublishdNFTByProject;

    constructor(address manager, address moduleGlobals) FeeModuleBase(moduleGlobals) ModuleBase(manager) {}

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

        uint256 treasuryOfSoulBoundTokenId = IBankTreasury(treasury).getSoulBoundTokenId();

        uint256 publishTaxes = (publication.amount - 1) * _PublishCurrencyTax(_ndpt());
       
        if ( publishTaxes > 0){
            IERC3525(_ndpt()).transferFrom(publication.soulBoundTokenId, treasuryOfSoulBoundTokenId, publishTaxes);
        }
        _dataPublishdNFTByProject[publishId].publication = publication;

    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param publishId The publishId to query.
     *
     * @return The template number and a JSON metadata and encode it in Base64
     */
    function getPublicationTemplate(
        uint256 publishId
    ) external view returns (uint256, string memory) {
    
        (address publishTemplate, uint256 publishNum) = abi.decode(_dataPublishdNFTByProject[publishId].publication.publishModuleInitData , (address, uint256));
        
        bytes memory jsonTemplate = ITemplate(publishTemplate).template();

        return (
            publishNum,
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64Upgradeable.encode(jsonTemplate)
                )
            )
        );
    }


}
