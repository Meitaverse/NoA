//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "hardhat/console.sol";

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import {IERC3525MetadataDescriptor} from "@solvprotocol/erc-3525/contracts/periphery/interface/IERC3525MetadataDescriptor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {StringConvertor} from "../utils/StringConvertor.sol";
import "../interface/ISoulBoundTokenV1.sol";

// interface IERC20 {
//   function decimals() external view returns (uint8);
// }

contract SBTMetadataDescriptor is IERC3525MetadataDescriptor {
  using StringConvertor for uint256;
  using StringConvertor for bytes;
 

  function constructContractURI() external view override returns (string memory) {
    ISoulBoundTokenV1 sbt = ISoulBoundTokenV1(msg.sender);
    return 
      string(
        abi.encodePacked(
          /* solhint-disable */
          'data:application/json;base64,',
          Base64Upgradeable.encode(
            abi.encodePacked(
              '{"name":"', 
              sbt.name(),
              '","description":"',
              _contractDescription(),
              '","image":"',
              _contractImage(),
              '","valueDecimals":"', 
              uint256(sbt.valueDecimals()).toString(),
              '"}'
            )
          )
          /* solhint-enable */
        )
      );
  }

  // for slotURI
  function constructSlotURI(uint256 slot_) external pure override returns (string memory) {
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
   ISoulBoundTokenV1 sbt = ISoulBoundTokenV1(msg.sender);
  //  TokenURIParams memory params =  sbt.tokenURIParams(tokenId_);

   string memory svg = Base64.encode(
      bytes(
        abi.encodePacked(
          "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 1200 1600' width='1200' height='1600' style='background-color:white'>",
          _svgLogo(),
          "<text style='font: bold 100px sans-serif;' text-anchor='middle' alignment-baseline='central' x='600' y='1250'>",
          // sbt.nickNameOf(tokenId_),
          "nameOf",
          "</text>",
          "<text style='font: bold 100px sans-serif;' text-anchor='middle' alignment-baseline='central' x='600' y='1350'>",
          // sbt.roleOf(tokenId_),
          "roleOf",
          "</text>",
          "<text style='font: bold 100px sans-serif;' text-anchor='middle' alignment-baseline='central' x='600' y='1450'>",
          "ShowDao",
          "</text>",
          "</svg>"
        )
      )
    );


    // prettier-ignore
    /* solhint-disable */
    string memory json = string(abi.encodePacked(
          '{ "id": ',
          Strings.toString(tokenId_),
          ', "nickName": "',
          // sbt.nickNameOf(tokenId_),
          'nicknameOf',
          '", "role": "',
          // sbt.roleOf(tokenId_),
         'roleOf',
          '", "organization": "',
          'ShowDao',
          '", "tokenName": "',
          sbt.name(),
          '", "image": "data:image/svg+xml;base64,',
          svg,
          '" }'
        ));

    // prettier-ignore
    return string(abi.encodePacked('data:application/json;utf8,', json));
    /* solhint-enable */
  }

  function _svgLogo() internal view returns (string memory) {
    ISoulBoundTokenV1 sbt = ISoulBoundTokenV1(msg.sender);
    return sbt.svgLogo();
  }
  

  function _slotName(uint256 slot_) internal pure returns (string memory) {
    if (slot_ == 1) {
      return "User";
    } else {
      return "Organizer";
    }
 
  }

  function _slotDescription(uint256 slot_) internal pure returns (string memory) {
    slot_;
     return "";
  }

   /**
     * @dev Generate the content of the `properties` field of `slotURI`.
     */

  function _slotProperties(uint256 slot_) internal pure returns (string memory) {
    slot_;
    return "";
            
  }

  function _contractDescription() internal pure returns (string memory) {
    return "http://showdao.io";
  }

  function _contractImage() internal pure returns (bytes memory) {
    return "http://showdao.io/logo.png";
  }


}
