// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
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
    using Counters for Counters.Counter;

    uint256 private constant EXPIRED_SECONDS= 5184000;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    string public name;
    string public symbol;

    string private _uriBase; //"https://api.bitsoul.xyz/v1/metadata/"

    // solhint-disable-next-line var-name-mixedcase
    address internal _BANKTREASURY;
    
    modifier onlyBankTreasury() {
        _validateCallerIsBankTreasury();
        _;
    }

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

    function generateVoucher(
        DataTypes.VoucherParValueType voucherType,
        address account
    ) 
        external
        onlyOwner
    {
        uint256 _tokenId = _generateNextVoucherId();
        uint256 etherValue;
        uint256 amount;

        if (voucherType == DataTypes.VoucherParValueType.ZEROPOINTONE){ //0
            etherValue = 0.1 ether;
            amount = 100;
        } 
        else if (voucherType == DataTypes.VoucherParValueType.ZEROPOINTTWO){ //1
            etherValue = 0.2 ether;
            amount = 200;
        } 
        else if (voucherType == DataTypes.VoucherParValueType.ZEROPOINTTHREE){//2
            etherValue = 0.3 ether;
            amount = 300;
        } 
        else if (voucherType == DataTypes.VoucherParValueType.ZEROPOINTFOUR){//3
            etherValue = 0.4 ether;
            amount = 400;
        } 
        else if (voucherType == DataTypes.VoucherParValueType.ZEROPOINTFIVE) {//4
            etherValue = 0.5 ether;
            amount = 500;
        } 

        if (amount == 0) revert Errors.InvidVoucherParValueType();

        _mint(account, _tokenId, amount, "");
        _vouchers[_tokenId] = DataTypes.VoucherData({
            vouchType: voucherType,
            tokenId: _tokenId,
            etherValue: etherValue,
            ndptValue: amount,
            generateTimestamp: block.timestamp,
            endTimestamp: block.timestamp + EXPIRED_SECONDS, 
            isUsed: false,
            soulBoundTokenId: 0,
            usedTimestamp: 0
        });
         
        emit Events.GenerateVoucher(
             voucherType,
             _tokenId,
             etherValue,
             amount,
             block.timestamp,
             block.timestamp + EXPIRED_SECONDS
        );

        // Signals frozen metadata to OpenSea; emitted in minting functions
        emit Events.PermanentURI(string(abi.encodePacked(_uriBase, StringsUpgradeable.toString(_tokenId), ".json")), _tokenId);

    }

    function generateVoucherBatch(
        DataTypes.VoucherParValueType[] memory voucherTypes,
        address account
    ) 
        external
        onlyOwner
    {
        uint256[] memory ids = new uint256[](voucherTypes.length);
        uint256[] memory amounts = new uint256[](voucherTypes.length);
        for (uint256 i = 0; i < voucherTypes.length; ) {
            ids[i] =  _generateNextVoucherId();
            unchecked {
                ++i;
            }
            emit Events.PermanentURI(string(abi.encodePacked(_uriBase, StringsUpgradeable.toString(ids[i]), ".json")), ids[i]);
        }

        for (uint256 i = 0; i < voucherTypes.length; ) {
            uint256 etherValue;
            uint256 amount;
            if (voucherTypes[i] == DataTypes.VoucherParValueType.ZEROPOINTONE){
                etherValue = 0.1 ether;
                amount = 100;
            } 
            else if (voucherTypes[i] == DataTypes.VoucherParValueType.ZEROPOINTTWO){
                etherValue = 0.2 ether;
                amount = 200;
            } 
            else if (voucherTypes[i] == DataTypes.VoucherParValueType.ZEROPOINTTHREE){
                etherValue = 0.3 ether;
                amount = 300;
            } 
            else if (voucherTypes[i] == DataTypes.VoucherParValueType.ZEROPOINTFOUR){
                etherValue = 0.4 ether;
                amount = 400;
            } 
            else if (voucherTypes[i] == DataTypes.VoucherParValueType.ZEROPOINTFIVE) {
                etherValue = 0.5 ether;
                amount = 500;
            } 

            if (amount == 0) revert Errors.InvidVoucherParValueType();

            unchecked {
                ++i;
            }
        }

        _mintBatch(account, ids, amounts, "");
    }

    function getVoucher(uint256 voucherId) external view returns(DataTypes.VoucherData memory) {
        return _vouchers[voucherId];
    }

    function useVoucher(address account, uint256 voucherId, uint256 soulBoundTokenId) 
        external onlyBankTreasury 
    {
        if (balanceOf(account, voucherId) == 0) {
            revert Errors.NotOwnerVoucher();
        }
         DataTypes.VoucherData storage voucherData = _vouchers[voucherId];
         if (voucherData.isUsed) revert Errors.VoucherIsUsed();
         voucherData.isUsed = true;
         voucherData.soulBoundTokenId = soulBoundTokenId;
         voucherData.usedTimestamp = block.timestamp;
    }
    
    function burn(
        address owner,
        uint256 id,
        uint256 value
    ) external onlyOwner {
        _burn(owner, id, value);
        _vouchers[id].isUsed = true;
    }

    function burnBatch(
        address owner,
        uint256[] memory ids,
        uint256[] memory values
    ) external onlyOwner {
        _burnBatch(owner, ids, values);
        for (uint256 i = 0; i < ids.length; i++) {
            _vouchers[ids[i]].isUsed = true;
        }
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

    function setBankTreasury(address bankTreasury) external  onlyOwner{
        _BANKTREASURY = bankTreasury;
    }

    function _setURIPrefix(string memory _newBaseMetadataURI) internal {
        _uriBase = _newBaseMetadataURI;
    }

    function setTokenUri(uint256 tokenId_, string memory uri_) external onlyOwner {
        if(bytes(_uris[tokenId_]).length > 0)  revert Errors.UpdateURITwice();
        _uris[tokenId_] = uri_;
     }

    function _generateNextVoucherId() internal returns (uint256) {
        _nextVoucherId.increment();
        return uint256(_nextVoucherId.current());
    }

    function _validateCallerIsBankTreasury() internal view {
        if (msg.sender != _BANKTREASURY) revert Errors.NotBankTreasury();
    }
}