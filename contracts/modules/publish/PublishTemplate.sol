// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// import {PublishTemplateBase} from "../PublishTemplateBase.sol";
import {ITemplate} from "../../interfaces/ITemplate.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import {StringConvertor} from "../../utils/StringConvertor.sol";

struct CanvasStruct {
   uint256 width;
   uint256 height;
}

struct Position {
   uint256 x;
   uint256 y;
}

contract PublishTemplate is ITemplate {
    using StringConvertor for uint256;
    using StringConvertor for bytes;    

    uint256 private _templateNum;
    string private _name;
    string private _descript;
    string private _image;
    CanvasStruct private _canvas; 
    CanvasStruct private _watermark; 
    Position private _position;

    constructor(
        uint256 templateNum,
        string memory name,
        string memory descript,
        string memory image,
        CanvasStruct memory canvas,
        CanvasStruct memory watermark,
        Position memory position
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