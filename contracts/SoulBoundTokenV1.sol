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
import "./storage/SBTStorage.sol";

contract SoulBoundTokenV1 is 
    SBTStorage,
    Initializable,
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

    bytes32 internal constant _MINT_HASH =  keccak256("Mint(string nickName,string role,address to)");
    bytes32 internal constant _PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 internal constant _UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 internal constant _MINTER_ROLE = keccak256("MINTER_ROLE");


    //===== Events =====//

    event ToggleTransferable(bool transferable);
    event ToggleMintable(bool mintable);

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
        bool transferable_,
        bool mintable_,
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
        _transferable = transferable_;
        _mintable = mintable_;
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

    function toggleTransferable() external onlyRole(_PAUSER_ROLE) returns (bool) {
        if (_transferable) {
        _transferable = false;
        } else {
        _transferable = true;
        }
        emit ToggleTransferable(_transferable);
        return _transferable;
    }

    function toggleMintable() external onlyRole(_MINTER_ROLE) returns (bool) {
        if (_mintable) {
            _mintable = false;
        } else {
            _mintable = true;
        }
        emit ToggleMintable(_mintable);
        return _mintable;
    }
    
    function setMetadataDescriptor(address metadataDescriptor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMetadataDescriptor(metadataDescriptor_);
    }
    
    //===== Public Functions =====//
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
    
    function transferable() public view returns (bool) {
        return _transferable;
    }   

    function mintable() public view returns (bool) {
        return _mintable;
    }

    function mintedTo(uint256 tokenId_) public view returns (address) {
        return _mintedTo[tokenId_];
    }

    function mint(
        string calldata nickName_,
        string calldata role_,
        address to_,
        bytes calldata signature_
    ) public whenNotPaused {
        require(balanceOf(to_)==0, "SBT:Only mint one time");
        if (_mintable && !hasRole(_MINTER_ROLE, msg.sender)) {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    keccak256(abi.encode(_MINT_HASH,nickName_,role_,to_))
            ));
            require(digest.recover(signature_) == _signerAddress, "SBT:Invalid Signature");
        } else {
            require(hasRole(_MINTER_ROLE, msg.sender), "SBT: not allowed to mint!");
        }
        uint slot_ = _getSlot(role_);
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

    modifier isTransferable() {
        require(transferable() == true, "SBT: not transferable");
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

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControlUpgradeable, ERC3525SlotEnumerableUpgradeable) returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(
        address /*newImplementation*/
    ) internal virtual override {
        require(hasRole(_UPGRADER_ROLE, msg.sender), "SBT: Unauthorized Upgrade");
    }

    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override isTransferable() {
        super._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }

    //----internal functions----//

    function _getSlot(string memory role_) internal pure returns(uint256) {
        if (keccak256(abi.encodePacked(role_)) == keccak256(abi.encodePacked("Orginazer"))) {
            return 2;
        }  else {
             return 1;
        }
    }

    uint256[50] private __gap;
}