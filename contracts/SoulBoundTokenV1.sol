// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./libraries/DataTypes.sol";
import "./libraries/Errors.sol";
import "./storage/SBTStorage.sol";
import "./interfaces/ISoulBoundTokenV1.sol";
import "./extensions/ERC3525Votes.sol";

contract SoulBoundTokenV1 is
    Initializable,
    SBTStorage,
    ERC3525Votes,
    ISoulBoundTokenV1,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 internal constant _UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 internal constant _MINTER_ROLE = keccak256("MINTER_ROLE");

    //===== Initializer =====//

    /// @custom:oz-upgrades-unsafe-allow constructor
    // `initializer` marks the contract as initialized to prevent third parties to
    // call the `initialize` method on the implementation (this contract)
    constructor() initializer {}

    function initialize(
        string memory name_,
        string memory symbol_,
        address metadataDescriptor_
    ) public virtual initializer {
        __ERC3525_init_unchained(name_, symbol_, 0);
        __ERC3525Permit_init(name_);
        __ERC3525Permit_init_unchained(name_);
        __AccessControl_init();

        _setMetadataDescriptor(metadataDescriptor_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(_UPGRADER_ROLE, msg.sender);
        // _grantRole(_MINTER_ROLE, msg.sender);
    }

    //===== Public Functions =====//

    function setMetadataDescriptor(address metadataDescriptor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMetadataDescriptor(metadataDescriptor_);
    }

    function svgLogo() public view returns (string memory) {
        return _svgLogo;
    }

    function setSvgLogo(string calldata svgLogo_) external onlyRole(_MINTER_ROLE) {
        _svgLogo = svgLogo_;
    }

    function tokenDataOf(uint256 tokenId) public view returns (DataTypes.TokenInfoData memory) {
        return
            DataTypes.TokenInfoData(
                tokenId,
                ownerOf(tokenId),
                _sbtDetails[tokenId].nickName,
                _sbtDetails[tokenId].handle,
                name()
            );
    }

    function mint(
        DataTypes.CreateProfileData calldata vars,
        string memory nickName
    ) external override returns (uint256) {
        require(hasRole(_MINTER_ROLE, msg.sender), "ERR: not allowed");
        require(balanceOf(vars.to) == 0, "ERR: minted");

        uint256 tokenId_ = _mint(vars.to, 1, 1);

        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: nickName,
            handle: vars.handle,
            locked: true,
            reputation: 0
        });

        return tokenId_;
    }

    function burn(uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "ERR: not owner nor approved");
        _burn(tokenId_);
    }

    function burnValue(uint256 tokenId_, uint256 burnValue_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "ERR: not owner nor approved");
        _burnValue(tokenId_, burnValue_);
    }

    //===== Modifiers =====//

    modifier isTransferAllowed(uint256 tokenId_) {
        require(!_sbtDetails[tokenId_].locked, "ERR: not allowed");
        _;
    }

    //-- orverride -- //
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override isTransferAllowed(tokenId_) {
        super.transferFrom(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override isTransferAllowed(tokenId_) {
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable, ERC3525Upgradeable) returns (bool) {
            return
        interfaceId == type(ERC3525Votes).interfaceId ||
        super.supportsInterface(interfaceId);
    }
    
    function _mint(
        address to_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525Votes) returns (uint256) {
        return super._mint(to_, slot_, value_);
    }

    function _burnValue(uint256 tokenId_, uint256 burnValue_) internal virtual override {
        super._burnValue(tokenId_, burnValue_);
    }

    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525Upgradeable) {
        super._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }

    function _afterValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525Votes) {
        super._afterValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }

    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        require(hasRole(_UPGRADER_ROLE, msg.sender), "ERR: Unauthorized");
    }


    //----internal functions----//

    // function _getSlot(string memory role_) internal pure returns(uint256) {
    //     if (keccak256(abi.encodePacked(role_)) == keccak256(abi.encodePacked("Contributor"))) {
    //         return 1;
    //     } else if (keccak256(abi.encodePacked(role_)) == keccak256(abi.encodePacked("Organizer"))) {
    //          return 2;
    //     } else if (keccak256(abi.encodePacked(role_)) == keccak256(abi.encodePacked("User"))) {
    //          return 3;
    //     } else {
    //         return 4;
    //     }
    // }



}
