//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import {IERC3525Metadata} from "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import {IERC3525MetadataDescriptor} from "@solvprotocol/erc-3525/contracts/periphery/interface/IERC3525MetadataDescriptor.sol";
import {StringConvertor} from "../utils/StringConvertor.sol";
import {INFTDerivativeProtocolTokenV1} from "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import {DataTypes} from '../libraries/DataTypes.sol';
// import {IModuleGlobals} from "../interfaces/IModuleGlobals.sol";
import {IManager} from "../interfaces/IManager.sol";

interface IERC20 {
  function decimals() external view returns (uint8);
}

contract SBTMetadataDescriptor is IERC3525MetadataDescriptor {
  using StringConvertor for uint256;
  using StringConvertor for bytes;
  address public immutable Manager;

  constructor(address manager) {
    Manager = manager;
  }

  //contractURI()
  function constructContractURI() external view override returns (string memory) {
        IERC3525MetadataUpgradeable erc3525 = IERC3525MetadataUpgradeable(msg.sender);
        return 
            string(
                abi.encodePacked(
                    /* solhint-disable */
                    'data:application/json;base64,',
                    Base64Upgradeable.encode(
                        abi.encodePacked(
                            '{"name":"', 
                            erc3525.name(),
                            '","description":"',
                            _contractDescription(),
                            '","image":"',
                            _contractImage(),
                            '","valueDecimals":"', 
                            uint256(erc3525.valueDecimals()).toString(),
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
                            _slotName(slot_),
                            '","description":"',
                            _slotDescription(slot_),
                            '","image":"',
                            _slotImage(slot_),
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
        IERC3525MetadataUpgradeable erc3525 = IERC3525MetadataUpgradeable(msg.sender);
        return 
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64Upgradeable.encode(
                        abi.encodePacked(
                            /* solhint-disable */
                            '{"name":"',
                            _tokenName("SBT", tokenId_),
                            '","description":"',
                            _tokenDescription(tokenId_),
                            '","image":"',
                            _tokenImage(tokenId_),
                            '","balance":"',
                            erc3525.balanceOf(tokenId_).toString(),
                            '","slot":"',
                            erc3525.slotOf(tokenId_).toString(),
                            '","properties":',
                            _tokenProperties(tokenId_),
                            "}"
                            /* solhint-enable */
                        )
                    )
                )
            );
    }


    function _contractDescription() internal view virtual returns (string memory) {
        //TODO default contract description 
        return "Soul Bound Token copyright by Bitsoul.me";
    }

    function _contractImage() internal view virtual returns (bytes memory) {
       //TODO default contract image 
        return "";
    }

    function _slotName(uint256 slot_) internal view virtual returns (string memory) {
        slot_;
        return "";
    }

    function _slotDescription(uint256 slot_) internal view virtual returns (string memory) {
        slot_;
        return "";
    }

    function _slotImage(uint256 slot_) internal view virtual returns (bytes memory) {
        slot_;
        return "";
    }

   /**
     * @dev Generate the content of the `properties` field of `slotURI`.
     */

  function _slotProperties(uint256 slot_) internal pure returns (string memory) {
    // IDerivativeNFT dao = IDerivativeNFT(msg.sender);
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


  function _tokenDescription(uint256 tokenId_) internal view virtual returns (string memory) {
      tokenId_;
      return "";
  }


  function _tokenImage(uint256 tokenId_) internal view virtual returns (bytes memory) {
      tokenId_;
      //default image uri
      return "";
  }

  function _tokenProperties(uint256 tokenId_) internal view returns (string memory) {
    DataTypes.SoulBoundTokenDetail memory detail = _profileDetail(tokenId_);
    return 
      string(
        abi.encodePacked(
          /* solhint-disable */
          '{',
            '"nickName":"',
              detail.nickName, 
            '"imageURI":"',
              detail.imageURI, 
            '"locked":"',
              'true',
          '"}'
          /* solhint-enable */
        )
      );
  }

  function _profileDetail(uint256 soulBoundTokenId_) internal view returns (DataTypes.SoulBoundTokenDetail memory) {
    DataTypes.SoulBoundTokenDetail memory detail = INFTDerivativeProtocolTokenV1(msg.sender).getProfileDetail(soulBoundTokenId_);
    return detail;
  }

}
