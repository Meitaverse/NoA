// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from "../../libraries/DataTypes.sol";
import {ITemplate} from "../../interfaces/ITemplate.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import {StringConvertor} from "../../utils/StringConvertor.sol";


contract TemplateAI is ITemplate {
    using StringConvertor for uint256;
    using StringConvertor for bytes;    

    uint256 private _templateNum;
    string private _name;
    string private _descript;
    string private _image;

    string private _prompt;

    constructor(
        uint256 templateNum,
        string memory name,
        string memory descript,
        string memory image,
        string memory prompt
    ) {
        _templateNum = templateNum;
        _name = name;
        _descript = descript;
        _image = image;
        _prompt = prompt;
    }

    function template() external override view returns(bytes memory) {
        string memory meta = string(abi.encodePacked(
            '"name": "Official Template #', _templateNum.toString(), '",',
            '"description": "Bitsoul protocol watermark template",',
            '"image": "', _image, '"',
            '}'
        ));
        
       return abi.encodePacked(
            '{',
                meta,
                '"properties": {',
                '"prompt": "', _prompt, '"',
            '}'
        );
    }
}