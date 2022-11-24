//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import {IERC3525MetadataDescriptor} from "@solvprotocol/erc-3525/contracts/periphery/interface/IERC3525MetadataDescriptor.sol";
import {StringConvertor} from "./utils/StringConvertor.sol";
import {INoAV1} from "./interfaces/INoAV1.sol";

interface IERC20 {
  function decimals() external view returns (uint8);
}

contract MetadataDescriptor is IERC3525MetadataDescriptor {
  using StringConvertor for uint256;
  using StringConvertor for bytes;

  function constructContractURI() external view override returns (string memory) {
    INoAV1 dao = INoAV1(msg.sender);
    return 
      string(
        abi.encodePacked(
          /* solhint-disable */
          'data:application/json;base64,',
          Base64Upgradeable.encode(
            abi.encodePacked(
              '{"name":"', 
              dao.name(),
              '","description":"',
              _contractDescription(),
              '","image":"',
              _contractImage(),
              '","valueDecimals":"', 
              uint256(dao.valueDecimals()).toString(),
              '"}'
            )
          )
          /* solhint-enable */
        )
      );
  }

  function constructSlotURI(uint256 slot_) external view override returns (string memory) {
    return
      string(
        abi.encodePacked(
          /* solhint-disable */
          'data:application/json;base64,',
          Base64Upgradeable.encode(
            abi.encodePacked(
              '{"name":"', 
              _slotName(slot_),
              '","description":"',
              _slotDescription(slot_),
              '","image":"',
              _slotImage(slot_),
              '","event_id":',
              slot_.toString(),
              '","event_metadata_uri":',
              _sloteventMetadataURI(slot_),
              '","properties":',
              _slotProperties(slot_),
              '}'
            )
          )
          /* solhint-enable */
        )
      );
  }

  function constructTokenURI(uint256 tokenId_) external view override returns (string memory) {
    INoAV1 dao = INoAV1(msg.sender);
    return 
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64Upgradeable.encode(
            abi.encodePacked(
              /* solhint-disable */
              '{"name":"',
              _tokenName(tokenId_),
              '","description":"',
              _tokenDescription(tokenId_),
             '","image":"',
              _tokenImage(tokenId_),
              '","balance":"',
              dao.balanceOf(tokenId_).toString(),
              '","slot":"',
              dao.slotOf(tokenId_).toString(),
              '","properties":',
              _tokenProperties(tokenId_),
              "}"
              /* solhint-enable */
            )
          )
        )
      );
  }

  function _slotName(uint256 slot_) internal view returns (string memory) {
    INoAV1 dao = INoAV1(msg.sender);
    INoAV1.SlotDetail memory slotDetail = dao.getSlotDetail(slot_);
    return slotDetail.name;
  }

  function _slotDescription(uint256 slot_) internal view returns (string memory) {
    INoAV1 dao = INoAV1(msg.sender);
    INoAV1.SlotDetail memory slotDetail = dao.getSlotDetail(slot_);
    return slotDetail.description;
  }

  function _slotImage(uint256 slot_) internal view returns (string memory) {
    INoAV1 dao = INoAV1(msg.sender);
    INoAV1.SlotDetail memory slotDetail = dao.getSlotDetail(slot_);

    return string(slotDetail.image);
  }

  function _sloteventMetadataURI(uint256 slot_) internal view returns (string memory) {
    INoAV1 dao = INoAV1(msg.sender);
    INoAV1.SlotDetail memory slotDetail = dao.getSlotDetail(slot_);

    return string(slotDetail.eventMetadataURI);
  }

   /**
     * @dev Generate the content of the `properties` field of `slotURI`.
     */

  function _slotProperties(uint256 slot_) internal pure returns (string memory) {
    // INoAV1 dao = INoAV1(msg.sender);
    // INoAV1.SlotDetail memory slotDetail = dao.getSlotDetail(slot_);
    slot_;
    return "";
            
  }

  function _tokenName(uint256 tokenId_) internal view returns (string memory) {
    INoAV1 dao = INoAV1(msg.sender);
    uint256 slot = dao.slotOf(tokenId_);
    // solhint-disable-next-line
    return 
      string(
        abi.encodePacked(
          _slotName(slot), 
          " #", tokenId_.toString()
        )
      );
  }

  function _tokenDescription(uint256 tokenId_) internal view returns (string memory) {
    INoAV1 dao = INoAV1(msg.sender);
    uint256 slot = dao.slotOf(tokenId_);
    INoAV1.SlotDetail memory sd = dao.getSlotDetail(slot);
    return sd.description;
  }

  function _tokenImage(uint256 tokenId_) internal view returns (string memory) {
     INoAV1 dao = INoAV1(msg.sender);
    uint256 slot = dao.slotOf(tokenId_);
    INoAV1.SlotDetail memory sd = dao.getSlotDetail(slot);
    return sd.image;
  }

  function _tokenProperties(uint256 tokenId_) internal view returns (string memory) {
    INoAV1 dao = INoAV1(msg.sender);
    uint256 slot = dao.slotOf(tokenId_);
    INoAV1.SlotDetail memory slotDetail = dao.getSlotDetail(slot);
    INoAV1.Event memory event_ = dao.getEventInfo(slotDetail.eventId);

    return 
      string(
        abi.encodePacked(
          /* solhint-disable */
          '{"eventName":"',
             event_.eventName,
             '","eventDescription":"',
             event_.eventDescription,
             '","eventImage":"',
             event_.eventImage,
             '","mintMax":"',
              event_.mintMax.toString(),
          '"}'
          /* solhint-enable */
        )
      );
  }

  function _contractDescription() internal pure returns (string memory) {
    return "http://showdao.io";
  }

  function _contractImage() internal pure returns (bytes memory) {
    return "http://showdao.io/logo.png";
  }

}
