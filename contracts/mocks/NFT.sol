// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract NFT is ERC721, ERC721URIStorage, Ownable {
    using Strings for uint256;

    constructor() ERC721("Bored Ape Yacht Club", "BAYC") {}

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    ///@notice set token uri, _tokenURI : http://app.bitsoul.net/images/nft/1.png
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }


    //== override ==//
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "BAYC #', tokenId.toString(), '",',
                '"description": "Bored Ape Yacht Club by Yuga Labs",',
                '"image": "', super.tokenURI(tokenId), '"',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,", 
                Base64.encode(dataURI)
            )
        );

        // return super.tokenURI(tokenId);

    }


}

