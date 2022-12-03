// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interface/INoAV1.sol";
import "../interface/ISoulBoundTokenV1.sol";

contract Manager is 
    Initializable, 
    ContextUpgradeable, 
    AccessControlUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    bytes32 internal constant _PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 internal constant _UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    bytes32 private constant _MINT_SBT_TYPEHASH =
        keccak256("MintSBT(string nickName,string role,address to,uint256 value)");

    INoAV1 internal _noAV1;
    ISoulBoundTokenV1 internal _soulBoundTokenV1;
    // IVoting internal _voting;

    address internal _signerAddress;

    function initialize(
        INoAV1 noAV1_,
        ISoulBoundTokenV1 soulBoundTokenV1_,
        // IVoting voting
        address signer_
    ) public initializer {
        __Context_init();
        __Ownable_init();
        __AccessControl_init();
        __Pausable_init();

        _noAV1 = noAV1_;
        _soulBoundTokenV1 = soulBoundTokenV1_;
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(_UPGRADER_ROLE, _msgSender());
        _grantRole(_PAUSER_ROLE, _msgSender());

        _signerAddress =  signer_;

    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function setSigner(address signerAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(signerAddress_ != address(0), "SBT: invalid signer address");
        _signerAddress = signerAddress_;
    }
    
    //-- external -- //

    function pause() external {
        require(hasRole(_PAUSER_ROLE, _msgSender()), "ERR: Unauthorized");
        _pause();
    }

    function unpause() external {
        require(hasRole(_PAUSER_ROLE, _msgSender()), "ERR: Unauthorized");
        _unpause();
    }
    
    function mintSoulBoundTokenBySig(
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
    ) external whenNotPaused {
        //
    }


    //-- orverride -- //
    function _authorizeUpgrade(
        address /*newImplementation*/
    ) internal virtual override {
        require(hasRole(_UPGRADER_ROLE, _msgSender()), "ERR: Unauthorized");
    }


}