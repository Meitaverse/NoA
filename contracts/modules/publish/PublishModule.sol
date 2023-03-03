// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


import {IPublishModule} from "../../interfaces/IPublishModule.sol";
import {Errors} from "../../libraries/Errors.sol";
import '../../libraries/Constants.sol';
import {Events} from "../../libraries/Events.sol";
import {FeeModuleBase} from "../FeeModuleBase.sol";
import {DataTypes} from '../../libraries/DataTypes.sol';
import {ModuleBase} from "../ModuleBase.sol";
import {IBankTreasury} from '../../interfaces/IBankTreasury.sol';
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {IDerivativeNFT} from "../../interfaces/IDerivativeNFT.sol";
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

    //publishId => PublishData
    mapping(uint256 => PublishData) internal _dataPublishdNFTByProject;

    constructor(address manager, address market, address moduleGlobals) FeeModuleBase(moduleGlobals) ModuleBase(manager, market) {}

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
            
            if (publication.amount >1) 
                publishTaxes = (publication.amount - 1) * _publishCurrencyTax();
            
            if ( publishTaxes > 0) {

                INFTDerivativeProtocolTokenV1(_sbt()).transferValue(
                    publication.soulBoundTokenId, 
                    treasuryOfSoulBoundTokenId, 
                    publishTaxes
                );
            }
            
            _dataPublishdNFTByProject[publishId].publication = publication;
            _dataPublishdNFTByProject[publishId].previousPublishId = previousPublishId;

            return publishTaxes;
        }
    }

    function updatePublish(
        uint256 publishId,
        uint256 salePrice,
        uint16 royaltyBasisPoints,
        uint256 amount,
        string memory name,
        string memory description,
        string[] memory materialURIs,
        uint256[] memory fromTokenIds
    ) external override onlyManager returns(uint256) {
        if (publishId == 0) revert Errors.InitParamsInvalid();
        if (amount < _dataPublishdNFTByProject[publishId].publication.amount) revert Errors.AmountOnlyIncrease();
        
        if (amount > _dataPublishdNFTByProject[publishId].publication.amount) {
            uint256 addedPublishTaxes = (amount - _dataPublishdNFTByProject[publishId].publication.amount) * _publishCurrencyTax();
            
            if ( addedPublishTaxes > 0){
                INFTDerivativeProtocolTokenV1(_sbt()).transferValue(_dataPublishdNFTByProject[publishId].publication.soulBoundTokenId, BANK_TREASURY_SOUL_BOUND_TOKENID, addedPublishTaxes);
            } 

            _dataPublishdNFTByProject[publishId].publication.salePrice = salePrice;
            _dataPublishdNFTByProject[publishId].publication.royaltyBasisPoints = royaltyBasisPoints;
            _dataPublishdNFTByProject[publishId].publication.amount = amount;
            _dataPublishdNFTByProject[publishId].publication.name = name;
            _dataPublishdNFTByProject[publishId].publication.description = description;
            _dataPublishdNFTByProject[publishId].publication.materialURIs = materialURIs;
            _dataPublishdNFTByProject[publishId].publication.fromTokenIds = fromTokenIds;

            return addedPublishTaxes;
        } else {
            return 0;
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
