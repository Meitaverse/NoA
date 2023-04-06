//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import {IERC3525MetadataDescriptor} from "@solvprotocol/erc-3525/contracts/periphery/interface/IERC3525MetadataDescriptor.sol";
import {StringConvertor} from "../utils/StringConvertor.sol";

interface IERC20 {
  function decimals() external view returns (uint8);
}

contract ProjectFounderDescriptor is IERC3525MetadataDescriptor {
  using StringConvertor for uint256;
  using StringConvertor for bytes;

  constructor() {
  }

  //contractURI()
  function constructContractURI() external view override returns (string memory) {
    return 
      string(
        abi.encodePacked(
          /* solhint-disable */
          'data:application/json;base64,',
          Base64Upgradeable.encode(
            abi.encodePacked(
              '{"name":"', 
              "ProjectFounder",
              '","description":"',
              "Contract of project founder",
              '","image":"',
              "TODO",
              '","valueDecimals":"', 
              '0',
              '"}'
            )
          )
          /* solhint-enable */
        )
      );
  }

  //slotURI(uint)
  function constructSlotURI(uint256 slot_) external view override returns (string memory) {
    return
      string(
        abi.encodePacked(
          /* solhint-disable */
          'data:application/json;base64,',
          Base64Upgradeable.encode(
            abi.encodePacked(
                '{"name":"', 
                "TODO",
                '","description":"',
                "TODO",
                '","image":"',
                "TODO",
      
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

    return 
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64Upgradeable.encode(
            abi.encodePacked(
              /* solhint-disable */
              '{"name":"',
              "TODO",
              '","description":"',
              "TODO",
             '","image":"',
              "TODO", 
              '","balance":"',
              IERC3525(msg.sender).balanceOf(tokenId_).toString(),
              '","slot":"',
              slot_.toString(),
              
              "}"
              /* solhint-enable */
            )
          )
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


}
