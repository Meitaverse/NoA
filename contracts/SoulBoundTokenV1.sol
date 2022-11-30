// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525SlotEnumerableUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interface/ISoulBoundTokenV1.sol";
import "./interface/IERC5192.sol";
import "./storage/SBTStorage.sol";

contract SoulBoundTokenV1 is 
    SBTStorage,
    Initializable,
    IERC5192,
    ISoulBoundTokenV1,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable, 
    OwnableUpgradeable,
    ERC3525SlotEnumerableUpgradeable
 {
    using Counters for Counters.Counter;
    using ECDSAUpgradeable for bytes32;

    /* ========== error definitions ========== */
    // revertedWithCustomError
    error ZeroAddress();

    bytes32 internal constant _PAUSER_ROLE = keccak256("PAUSER_ROLE");
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
        address metadataDescriptor_,
        string memory organization_,
        address tokenOwner_,
        address minterOfToken_,
        address signerAddress_
    ) public virtual initializer {
        if (metadataDescriptor_ == address(0)) {
            revert ZeroAddress();
        }
        if (signerAddress_ == address(0)) {
            revert ZeroAddress();
        }
         __AccessControl_init();
         __Ownable_init();

        __ERC3525_init_unchained(name_, symbol_, 0);
        _setMetadataDescriptor(metadataDescriptor_);
        
        _organization = organization_;
        _signerAddress = signerAddress_;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(_UPGRADER_ROLE, msg.sender);

        _grantRole(DEFAULT_ADMIN_ROLE, tokenOwner_);
        _grantRole(_PAUSER_ROLE, tokenOwner_);
        _grantRole(_MINTER_ROLE, minterOfToken_);

     }
    
    //===== External Functions =====//
    fallback() external payable {
        return;
    }

    receive() external payable {
        return;
    }

    function setSigner(address signerAddress_) external onlyRole(_MINTER_ROLE) {
        require(signerAddress_ != address(0), "SBT: invalid signer address");
        _signerAddress = signerAddress_;
    }

    function setSvgLogo(string calldata svgLogo_) external onlyRole(_MINTER_ROLE) {
        _svgLogo = svgLogo_;
    }
    
    function setMetadataDescriptor(address metadataDescriptor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMetadataDescriptor(metadataDescriptor_);
    }

    //===== Public Functions =====//
    function locked(uint256 tokenId_) public view returns (bool) {
        require(ownerOf(tokenId_) != address(0));
        return _slotDetails[slotOf(tokenId_)].locked;
    }
    
    function svgLogo() public view returns (string memory) {
        return _svgLogo;
    }

    function nickNameOf(uint256 tokenId) public view returns (string memory) {
        return _tokenOwnerInfo[tokenId].nickName;
    }

    function roleOf(uint256 tokenId) public view returns (string memory) {
        return _tokenOwnerInfo[tokenId].role;
    }
        
    function tokenDataOf(uint256 tokenId) public view returns (TokenInfoData memory) {
        return TokenInfoData(tokenId, ownerOf(tokenId), mintedTo(tokenId), nickNameOf(tokenId), roleOf(tokenId), organization(), name());
    }
    
    function version() public pure returns (uint256) {
        return 1;
    }

    function organization() public view returns (string memory) {
        return _organization;
    }
    
    function mintedTo(uint256 tokenId_) public view returns (address) {
        return _mintedTo[tokenId_];
    }

    function mint(
        string memory nickName_,
        string memory role_,
        address to_,
        bytes memory signature_
    ) public whenNotPaused {
        require(balanceOf(to_)==0, "SBT: Only mint one time per address");
        if (!hasRole(_MINTER_ROLE, msg.sender)) {
            bytes32 msgHash = _getMessageHash(nickName_,role_,to_); 
            bytes32 ethSignedMessageHash = ECDSAUpgradeable.toEthSignedMessageHash(msgHash); 
            require(_verify(ethSignedMessageHash, signature_), "SBT: Invalid signature"); 
        } else {
            require(hasRole(_MINTER_ROLE, msg.sender), "SBT: not allowed to mint!");
        }

        uint slot_ = _getSlot(role_);

        _slotDetails[slot_] = SlotDetail({
            nickName: nickName_,
            role: role_,
            locked: true,
            reputation: 0
        });

        uint256 tokenId_ = ERC3525Upgradeable._mint(to_, slot_, 1);
        _tokenOwnerInfo[tokenId_] = TokenOwnerInfo({
            nickName: nickName_,
            role : role_
        });
    }

    function burn(uint256 tokenId_) public virtual exists(tokenId_) onlyMinterOrTokenOwner(tokenId_){
        ERC3525Upgradeable._burn(tokenId_);
    }

    //===== Modifiers =====//

    modifier isTransferAllowed(uint256 tokenId_) {
        require(!_slotDetails[slotOf(tokenId_)].locked, "SBT: not allowed");
        _;
    }

    modifier exists(uint256 tokenId_) {
        require(_exists(tokenId_), "SBT: token doesn't exist or has been burnt");
        _;
    }

    modifier onlyMinterOrTokenOwner(uint256 tokenId_) {
        require(_exists(tokenId_), "SBT: token doesn't exist or has been burnt");
        require(_isApprovedOrOwner(_msgSender(), tokenId_) || hasRole(_MINTER_ROLE, msg.sender), "SBT: sender not owner or token owner");
        _;
    }

    //------override------------//
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override(ERC3525Upgradeable, IERC721) isTransferAllowed(tokenId_)   {
        super.transferFrom(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override(ERC3525Upgradeable, IERC721)  isTransferAllowed(tokenId_)  {
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    function approve(address to_, uint256 tokenId_) public payable virtual override(ERC3525Upgradeable, IERC721) isTransferAllowed(tokenId_)  {
        super.approve(to_, tokenId_);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControlUpgradeable, ERC3525SlotEnumerableUpgradeable) returns (bool) {
        return 
        interfaceId == type(IAccessControlUpgradeable).interfaceId || 
        interfaceId == type(IERC165).interfaceId ||
        interfaceId == type(IERC5192).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(
        address /*newImplementation*/
    ) internal virtual override {
        require(hasRole(_UPGRADER_ROLE, msg.sender), "SBT: Unauthorized Upgrade");
    }

    //----internal functions----//
    function _getMessageHash(string memory nickName,string memory role, address to) internal pure returns(bytes32){
        return keccak256(abi.encodePacked(nickName, role, to));
    }

    function _verify(bytes32 ethSignedMessageHash, bytes memory signature) internal view returns (bool) {
        return ECDSAUpgradeable.recover(ethSignedMessageHash, signature) == _signerAddress;
    }

    function _getSlot(string memory role_) internal pure returns(uint256) {
        if (keccak256(abi.encodePacked(role_)) == keccak256(abi.encodePacked("GuildLeader"))) {
            return 1;
        } else if (keccak256(abi.encodePacked(role_)) == keccak256(abi.encodePacked("Organizer"))) {
             return 2;
        } else if (keccak256(abi.encodePacked(role_)) == keccak256(abi.encodePacked("User"))) {
             return 3;
        } else {
            return 4;
        }
    }

    uint256[50] private __gap;
}