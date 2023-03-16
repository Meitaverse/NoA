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
    DataTypes.CanvasData private _canvas; 
    DataTypes.CanvasData private _watermark; 
    DataTypes.Position private _position;

    constructor(
        uint256 templateNum,
        string memory name,
        string memory descript,
        string memory image,
        DataTypes.CanvasData memory canvas,
        DataTypes.CanvasData memory watermark,
        DataTypes.Position memory position
    ) {
        _templateNum = templateNum;
        _name = name;
        _descript = descript;
        _image = image;
        _canvas = canvas;
        _watermark = watermark;
        _position = position;
    }

    function template() external override view returns(bytes memory) {
        string memory meta = string(abi.encodePacked(
            '"name": "Official Template #', _templateNum.toString(), '",',
            '"description": "Bitsoul protocol watermark template",',
            '"image": "', _image, '"',
            '"main_canvas": {',
                '"width": "', _canvas.width.toString(), '"',
                '"height": "', _canvas.height.toString(), '"',
            '}'
        ));
        
       return abi.encodePacked(
            '{',
                meta,
                '"watermark_canvas": {',
                    '"width": "', _watermark.width.toString(), '"',
                    '"height": "', _watermark.height.toString(), '"',
                '}',
                '"watermark_position": {',
                    '"x": "', _position.x.toString(), '"',
                    '"y": "', _position.y.toString(), '"',
                '}',
            '}'
        );
    }
}