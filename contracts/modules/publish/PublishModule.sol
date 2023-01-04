// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


import {IPublishModule} from "../../interfaces/IPublishModule.sol";
import {Errors} from "../../libraries/Errors.sol";
import {Events} from '../../libraries/Events.sol';
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
import {INFTDerivativeProtocolTokenV1} from "../../interfaces/INFTDerivativeProtocolTokenV1.sol";


struct PublishData {
    DataTypes.Publication publication;
    uint256 previousPublishId;
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

    address internal _NDPT;

    //publishId => PublishData
    mapping(uint256 => PublishData) internal _dataPublishdNFTByProject;

    constructor(address manager, address moduleGlobals, address ndpt) FeeModuleBase(moduleGlobals) ModuleBase(manager) {
        _NDPT = ndpt;
    }

    /**
     * @notice Initializes data for a given publication being published. This can only be called by the manager.
     *
     * @param publishId The order ID of the the publication.
     * @param previousPublishId The previousPublishId .
     * @param publication The Publication .
     *
     * @return tax
     */
    function initializePublishModule(
        uint256 publishId,
        uint256 previousPublishId,
        uint256 treasuryOfSoulBoundTokenId,
        DataTypes.Publication calldata publication
    ) external override onlyManager returns(uint256){ 
        
        if (publishId == 0 || 
            treasuryOfSoulBoundTokenId == 0)
            revert Errors.InitParamsInvalid();

        (address publishTemplate,) = abi.decode(publication.publishModuleInitData, (address, uint256));

        if (!_isWhitelistTemplate(publishTemplate)) {
           revert Errors.TemplateNotWhitelisted();

        } else {

            uint256 publishTaxes;
            if (publication.amount >1) publishTaxes = (publication.amount - 1) * _publishCurrencyTax();
            
            if ( publishTaxes > 0){
                INFTDerivativeProtocolTokenV1(_NDPT).transferValue(publication.soulBoundTokenId, treasuryOfSoulBoundTokenId, publishTaxes);
            } 
            
            _dataPublishdNFTByProject[publishId].publication = publication;
            _dataPublishdNFTByProject[publishId].previousPublishId = previousPublishId;

            return publishTaxes;

        }

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
    
        (address publishTemplate, uint256 publishNum) = abi.decode(_dataPublishdNFTByProject[publishId].publication.publishModuleInitData, (address, uint256));

        if (!_isWhitelistTemplate(publishTemplate)) 
           revert Errors.TemplateNotWhitelisted();
        
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

    function getTemplate(
         uint256 publishId
    ) external view returns (address) {
         (address publishTemplate, ) = abi.decode(_dataPublishdNFTByProject[publishId].publication.publishModuleInitData, (address, uint256));
        return publishTemplate;
    }

}
