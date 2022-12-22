// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import {Errors} from "./libraries/Errors.sol";
import {IVoucher} from './interfaces/IVoucher.sol';
import {Events} from "./libraries/Events.sol";
import {DataTypes} from './libraries/DataTypes.sol';
import "./libraries/EthAddressLib.sol";
import "./storage/VoucherStorage.sol";
 
/**
 *  @title Voucher
 *  @author bitsoul Protocol
 * 
 */
contract Voucher is
    Initializable,
    VoucherStorage,
    ERC1155Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    string public name;
    string public symbol;

    string private _uriBase; //"https://api.treasureland.market/v2/lazy_mint/"

    function initialize(
        string memory uriBase
    ) public initializer {
        __ERC1155_init(string(abi.encodePacked(uriBase, "{id}.json")));
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        _setURIPrefix(uriBase);
        name = "The Voucher of Bitsoul";
        symbol = "VOB";

    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable, ERC1155Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        external
        onlyOwner
    {
        _mint(account, id, amount, data);

        // Signals frozen metadata to OpenSea; emitted in minting functions
        emit Events.PermanentURI(string(abi.encodePacked(_uriBase, StringsUpgradeable.toString(id), ".json")), id);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        external
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
        
        for (uint256 i = 0; i < ids.length; i++) {
            // Signals frozen metadata to OpenSea; emitted in minting functions
            emit Events.PermanentURI(string(abi.encodePacked(_uriBase, StringsUpgradeable.toString(ids[i]), ".json")), ids[i]);
        }
    }
    
    function burn(
        address owner,
        uint256 id,
        uint256 value
    ) external onlyOwner {
        _burn(owner, id, value);
    }

    function burnBatch(
        address owner,
        uint256[] memory ids,
        uint256[] memory values
    ) external onlyOwner {
        _burnBatch(owner, ids, values);
    }

    //-- orverride -- //
    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        if (!hasRole(UPGRADER_ROLE, _msgSender())) revert Errors.Unauthorized();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /** @dev URI override for OpenSea traits compatibility. */
    function uri(uint tokenId) override public view returns (string memory) {
            
        if(bytes(_uris[tokenId]).length > 0){
            return _uris[tokenId];
        }

        return string(
            abi.encodePacked(
                _uriBase,      
                StringsUpgradeable.toString(tokenId),        
                ".json"
            )
        );
    }

    /** @dev Contract-level metadata for OpenSea. */
    // Update for collection-specific metadata.
    function contractURI() public view returns (string memory) {
        // return "ipfs://bafkreigpykz4r3z37nw7bfqh7wvly4ann7woll3eg5256d2i5huc5wrrdq"; // Contract-level metadata for Voucher contract
        return 
            string(
                abi.encodePacked(
                "data:application/json;base64,",
                Base64Upgradeable.encode(
                    abi.encodePacked(
                    '{"name":"',
                    name,
                    '","symbol":"',
                    symbol,              
                    '","description":"',
                    'Bitsoul protocol voucher NFT base ERC1155',
                    '"}'
                    )
                )
                )
            );
    }
    
    /**
    * @dev Will update the base URL of token's URI
    * @param _newBaseMetadataURI New base URL of token's URI
    */
    function setURIPrefix(string memory _newBaseMetadataURI) public onlyOwner{
        _setURIPrefix(_newBaseMetadataURI);
    }
    function _setURIPrefix(string memory _newBaseMetadataURI) internal {
        _uriBase = _newBaseMetadataURI;
    }

    function setTokenUri(uint tokenId_, string memory uri_) external onlyOwner {
        if(bytes(_uris[tokenId_]).length > 0)  revert Errors.UpdateURITwice();
        _uris[tokenId_] = uri_;
     }

}