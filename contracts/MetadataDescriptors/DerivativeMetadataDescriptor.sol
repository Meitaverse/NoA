//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import {IERC3525MetadataDescriptor} from "@solvprotocol/erc-3525/contracts/periphery/interface/IERC3525MetadataDescriptor.sol";
import {StringConvertor} from "../utils/StringConvertor.sol";
import "../interfaces/IDerivativeNFTV1.sol";
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
              IERC3525Metadata(msg.sender).name(),
              '","description":"',
              projectData_.description,
              '","image":"',
              projectData_.image,
              '","valueDecimals":"', 
              uint256(IERC3525Metadata(msg.sender).valueDecimals()).toString(),
              '"}'
            )
          )
          /* solhint-enable */
        )
      );
  }

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
              '","soulBoundTokenId":',
              slotDetail.publication.soulBoundTokenId.toString(),
              '","projectId":',
              slotDetail.publication.projectId.toString(),
              '","salePrice":',
              slotDetail.publication.salePrice.toString(),
              '","royaltyBasisPoints":',
              slotDetail.publication.royaltyBasisPoints.toString(),
              '","amount":',
              slotDetail.publication.amount.toString(),
              '}'
            )
          )
          /* solhint-enable */
        )
      );
  }

  function constructTokenURI(uint256 tokenId_) external view override returns (string memory) {
    DataTypes.ProjectData memory projectData_ = _projectData();
    
    return 
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64Upgradeable.encode(
            abi.encodePacked(
              /* solhint-disable */
              '{"name":"',
              _tokenName(projectData_.name, tokenId_),
              '","description":"',
              projectData_.description,
             '","image":"',
              projectData_.image, 
              '","balance":"',
              IERC3525(msg.sender).balanceOf(tokenId_).toString(),
              '","slot":"',
              IERC3525(msg.sender).slotOf(tokenId_).toString(),
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
    DataTypes.SlotDetail memory slotDetail = IDerivativeNFTV1(msg.sender).getSlotDetail(slot_);
    return slotDetail;
  }

  function _slotDescription(uint256 slot_) internal view returns (string memory) {
    DataTypes.SlotDetail memory slotDetail = IDerivativeNFTV1(msg.sender).getSlotDetail(slot_);
    return slotDetail.publication.description;
  }

  function _sloteventMetadataURI(uint256 slot_) internal view returns (string[] memory) {
    DataTypes.SlotDetail memory slotDetail = IDerivativeNFTV1(msg.sender).getSlotDetail(slot_);

    return slotDetail.publication.materialURIs;
  }

   /**
     * @dev Generate the content of the `properties` field of `slotURI`.
     */

  function _slotProperties(uint256 slot_) internal pure returns (string memory) {
    // IDerivativeNFTV1 dao = IDerivativeNFTV1(msg.sender);
    // DataTypes.SlotDetail memory slotDetail = dao.getSlotDetail(slot_);
    slot_;
    return "";
            
  }

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
    
    uint256 value = IERC3525(msg.sender).balanceOf(tokenId_);
    return 
      string(
        abi.encodePacked(
          /* solhint-disable */
          '{"value":"',
              value.toString(), 
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

}
