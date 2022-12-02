// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./interface/ISoulBoundTokenV1.sol";
import "./extensions/ERC3525Votes.sol";
import "./storage/SBTStorage.sol";

contract SoulBoundTokenV1 is 
    Initializable,
    ERC3525Votes, 
    SBTStorage,
    ISoulBoundTokenV1,
    AccessControlUpgradeable,
    UUPSUpgradeable
    // OwnableUpgradeable,
    // ERC3525Upgradeable
{
    // using ECDSAUpgradeable for bytes32;


    bytes32 private constant _MINT_TYPEHASH =
        keccak256("Delegation(string memory nickName,string memory role, address to,uint256 value)");

    // bytes32 internal constant _PAUSER_ROLE = keccak256("PAUSER_ROLE");
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
        //  __Ownable_init();

        _setMetadataDescriptor(metadataDescriptor_);
        
        _signerAddress =  msg.sender;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _grantRole(_UPGRADER_ROLE, msg.sender);
        // _grantRole(_MINTER_ROLE, msg.sender);
    }
    
    //===== Public Functions =====//
    function setSigner(address signerAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(signerAddress_ != address(0), "SBT: invalid signer address");
        _signerAddress = signerAddress_;
    }

    function setMetadataDescriptor(address metadataDescriptor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMetadataDescriptor(metadataDescriptor_);
    }

    function svgLogo() public view returns (string memory) {
        return _svgLogo;
    }

    function setSvgLogo(string calldata svgLogo_) external onlyRole(_MINTER_ROLE) {
        _svgLogo = svgLogo_;
    }
        
    function tokenDataOf(uint256 tokenId) public view returns (TokenInfoData memory) {
        return TokenInfoData(tokenId, ownerOf(tokenId), _tokenDetails[tokenId].nickName, _tokenDetails[tokenId].role, name());
    }

    function mint(
        string memory nickName_,
        string memory role_,
        uint slot_,
        address to_,
        uint256 value_
    ) public  { 
        
        require(balanceOf(to_)==0, "ERR: minted");
        // if (!hasRole(_MINTER_ROLE, msg.sender)) {
        //     bytes32 msgHash = _getMessageHash(nickName_,role_,to_); 
        //     bytes32 ethSignedMessageHash = ECDSAUpgradeable.toEthSignedMessageHash(msgHash); 
        //     require(_verify(ethSignedMessageHash, signature_), "ERR: Invalid signature"); 
        //     tokenId_ = _mint(to_, slot_, 1);
        // } else {
            require(hasRole(_MINTER_ROLE, msg.sender), "ERR: not allowed");
            uint256 tokenId_ = _mint(to_, slot_, value_);
        // }

        _tokenDetails[tokenId_] = TokenDetail({
            nickName: nickName_,
            role: role_,
            locked: true,
            reputation: 0
        });
    }

    function mintBySig(
        string memory nickName_,
        string memory role_,
        uint slot_,
        address to_,
        uint256 value_,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        //
    }

    function burn(uint256 tokenId_) public virtual { 
        require(_isApprovedOrOwner(msg.sender, tokenId_), "ERR: not owner nor approved");
        _burn(tokenId_);
    }

    function burnValue(uint256 tokenId_, uint256 burnValue_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "ERR: not owner nor approved");
        _burnValue(tokenId_, burnValue_);
    }

    //-- orverride -- //
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override(ERC3525Upgradeable, IERC721)  {
        require(!_tokenDetails[tokenId_].locked, "ERR: not allowed");
        super.transferFrom(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override(ERC3525Upgradeable, IERC721) {
        require(!_tokenDetails[tokenId_].locked, "ERR: not allowed");
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    function _mint(address to_, uint256 slot_, uint256 value_) internal virtual override(ERC3525Votes) returns (uint256) {
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
    ) internal virtual override(ERC3525Votes)  {
        super._afterValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }    

    function _authorizeUpgrade(
        address /*newImplementation*/
    ) internal virtual override {
        require(hasRole(_UPGRADER_ROLE, msg.sender), "ERR: Unauthorized");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControlUpgradeable, ERC3525Upgradeable) returns (bool) {
        return 
            // interfaceId == type(ERC3525Upgradeable).interfaceId ||
            interfaceId == type(ERC3525Votes).interfaceId ||        
            interfaceId == type(IAccessControlUpgradeable).interfaceId || 
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //----internal functions----//
    // function _getMessageHash(string memory nickName,string memory role, address to) internal pure returns(bytes32){
    //     return keccak256(abi.encodePacked(nickName, role, to));
    // }

    // function _verify(bytes32 ethSignedMessageHash, bytes memory signature) internal view returns (bool) {
    //     return ECDSAUpgradeable.recover(ethSignedMessageHash, signature) == _signerAddress;
    // }

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
