//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import {IERC3525MetadataDescriptor} from "@solvprotocol/erc-3525/contracts/periphery/interface/IERC3525MetadataDescriptor.sol";
import {StringConvertor} from "../utils/StringConvertor.sol";
import "../interfaces/IDerivativeNFT.sol";
import {DataTypes} from '../libraries/DataTypes.sol';
import {IModuleGlobals} from "../interfaces/IModuleGlobals.sol";
import {IManager} from "../interfaces/IManager.sol";

interface IERC20 {
  function decimals() external view returns (uint8);
}

contract DerivativeMetadataDescriptor is IERC3525MetadataDescriptor {
  using StringConvertor for uint256;
  using StringConvertor for bytes;
  address public immutable  MODULE_GLOBALS;

  constructor(address moduleGlobals) {
    MODULE_GLOBALS = moduleGlobals;
  }

  //contractURI()
  function constructContractURI() external view override returns (string memory) {
    DataTypes.ProjectData memory projectData_ = _projectData();
    return 
      string(
        abi.encodePacked(
          /* solhint-disable */
          'data:application/json;base64,',
          Base64Upgradeable.encode(
            abi.encodePacked(
              '{"name":"', 
              projectData_.name,
              '","description":"',
              projectData_.description,
              '","image":"',
              projectData_.image,
              '","valueDecimals":"', 
              '0',
              '","properties":',
              _contractProperties(projectData_),
              '"}'
            )
          )
          /* solhint-enable */
        )
      );
  }

  //slotURI(uint)
  function constructSlotURI(uint256 slot_) external view override returns (string memory) {
    DataTypes.SlotDetail memory slotDetail = _slotDetail(slot_);
    return
      string(
        abi.encodePacked(
          /* solhint-disable */
          'data:application/json;base64,',
          Base64Upgradeable.encode(
            abi.encodePacked(
                '{"name":"', 
                slotDetail.publication.name,
                '","description":"',
                slotDetail.publication.description,
                '","image":"',
                slotDetail.imageURI,
                '","properties":',
                _slotProperties(slot_),
                '}'
            )
          )
          /* solhint-enable */
        )
      );
  }

  //tokenURI(uint)
  function constructTokenURI(uint256 tokenId_) external view override returns (string memory) {
    uint256 slot_ = IERC3525(msg.sender).slotOf(tokenId_);
    DataTypes.SlotDetail memory slotDetail = _slotDetail(slot_);

    return 
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64Upgradeable.encode(
            abi.encodePacked(
              /* solhint-disable */
              '{"name":"',
              _tokenName(slotDetail.publication.name, tokenId_),
              '","description":"',
              slotDetail.publication.description,
             '","image":"',
              slotDetail.imageURI, 
              '","balance":"',
              IERC3525(msg.sender).balanceOf(tokenId_).toString(),
              '","slot":"',
              slot_.toString(),
              '","properties":',
              _tokenProperties(tokenId_),
              "}"
              /* solhint-enable */
            )
          )
        )
      );
  }

  function _slotDetail(uint256 slot_) internal view returns (DataTypes.SlotDetail memory) {
    DataTypes.SlotDetail memory slotDetail = IDerivativeNFT(msg.sender).getSlotDetail(slot_);
    return slotDetail;
  }

   /**
     * @dev Generate the content of the `properties` field of `slotURI`.
     */

  function _slotProperties(uint256 slot_) internal view returns (string memory) {
    string memory materialURIs = '[';
    for (uint256 i = 0; i < _slotDetail(slot_).publication.materialURIs.length; ++i) {
      materialURIs = string(abi.encodePacked(materialURIs, _slotDetail(slot_).publication.materialURIs[i], ','));
    }
    materialURIs = string(abi.encodePacked(materialURIs, ']'));

    string memory fromTokenIds = '[';
    for (uint256 i = 0; i < _slotDetail(slot_).publication.fromTokenIds.length; ++i) {
      fromTokenIds = string(abi.encodePacked(fromTokenIds, _slotDetail(slot_).publication.fromTokenIds[i], ','));
    }
    fromTokenIds = string(abi.encodePacked(fromTokenIds, ']'));
    string memory temp = string(
        abi.encodePacked(
          /* solhint-disable */
          '{',
            '"soulBoundTokenId":"',
              _slotDetail(slot_).publication.soulBoundTokenId.toString(),
            '"hubId":"',
              _slotDetail(slot_).publication.hubId.toString() 
        )
      );
    return 
      string(
        abi.encodePacked(
          /* solhint-disable */
            temp,
            '"projectId":"',
              _slotDetail(slot_).publication.projectId.toString(), 
            '"salePrice":"',
              _slotDetail(slot_).publication.salePrice.toString(), 
            '"royaltyBasisPoints":"',
              uint256(_slotDetail(slot_).publication.royaltyBasisPoints).toString(), 
            '"amount":"',
              _slotDetail(slot_).publication.amount.toString(), 
            '"materialURIs":"',
              materialURIs, 
            '"fromTokenIds":"',
              fromTokenIds, 
          '"}'
          /* solhint-enable */
        )
      );
  }

  //publication name
  function _tokenName(string memory name, uint256 tokenId_) internal pure returns (string memory) {
    // solhint-disable-next-line
    return 
      string(
        abi.encodePacked(
          name, 
          " #", tokenId_.toString()
        )
      );
  }

  function _tokenProperties(uint256 tokenId_) internal view returns (string memory) {
    address _manager = IModuleGlobals(MODULE_GLOBALS).getManager();
    uint256 projectId = IManager(_manager).getProjectIdByContract(msg.sender);
    
    (uint256 publishId, )  = IManager(_manager).getPublicationByProjectToken(projectId, tokenId_);

    //genesis publishId
    uint256 genesisPublishId = IManager(_manager).getGenesisPublishIdByProjectId(projectId);
  
    DataTypes.PublishData memory publishData = IManager(_manager).getPublishInfo(publishId);
    DataTypes.PublishData memory gengesisPublishData = IManager(_manager).getPublishInfo(genesisPublishId);
    DataTypes.PublishData memory previousPublishData = IManager(_manager).getPublishInfo(publishData.previousPublishId);

    string memory genesis_temp = string(
        abi.encodePacked(
          /* solhint-disable */
          '"genesis_sbt_id":"',
              gengesisPublishData.publication.soulBoundTokenId.toString(), 
          '"genesis_publish_id":"',
              genesisPublishId.toString(), 
          '"genesis_token_id":"',
              gengesisPublishData.tokenId.toString(), 
          '"genesis_sale_price":"',
              gengesisPublishData.publication.salePrice.toString(), 
          '"genesis_royalty_basis_points":"',
              uint256(gengesisPublishData.publication.royaltyBasisPoints).toString()
          /* solhint-enable */
        )
      );

    string memory previous_temp = string(
        abi.encodePacked(
          /* solhint-disable */
         '"previous_sbt_id":"',
              publishData.publication.soulBoundTokenId.toString(), 
         '"previous_publish_id":"',
              publishData.previousPublishId.toString(), 
          '"previous_token_id":"',
              previousPublishData.tokenId.toString(), 
          '"previous_sale_price":"',
              previousPublishData.publication.salePrice.toString(), 
          '"previous_royalty_basis_points":"',
              uint256(previousPublishData.publication.royaltyBasisPoints).toString()
          /* solhint-enable */
        )
      );

    return 
      string(
        abi.encodePacked(
          /* solhint-disable */
          '{',
            '"sbt_id":"',
              publishData.publication.soulBoundTokenId.toString(), 
            '"hub_id":"',
              publishData.publication.hubId.toString(), 
            '"project_id":"',
              projectId.toString(), 
            '"publish_id":"',
              publishId.toString(), 
            '"sale_price":"',
              publishData.publication.salePrice.toString(), 
            'royalty_basis_points":"',
              uint256(publishData.publication.royaltyBasisPoints).toString(),             
            genesis_temp, 
            previous_temp,              
          '"}'
          /* solhint-enable */
        )
      );
  }

  //return project image
  function _projectData() internal view returns (DataTypes.ProjectData memory) {

    address _manager = IModuleGlobals(MODULE_GLOBALS).getManager();

    uint256 projectId = IManager(_manager).getProjectIdByContract(msg.sender);
    
    DataTypes.ProjectData memory projectData_ = IManager(_manager).getProjectInfo(projectId);
  
    return projectData_; 

  }

  function _contractProperties(DataTypes.ProjectData memory projectData_) internal pure returns(string memory) {
    return string(
          abi.encodePacked(
            /* solhint-disable */
            '{',
            '"soulBoundTokenId":"',
                projectData_.soulBoundTokenId.toString(), 
            '"hubId":"',
                projectData_.hubId.toString(), 
            '"metadataURI":"',
                projectData_.metadataURI, 
            '"}'
            /* solhint-enable */
          )
        );
  }

}
