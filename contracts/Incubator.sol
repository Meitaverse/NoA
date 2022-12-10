// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {IIncubator} from "./interfaces/IIncubator.sol";
import {DataTypes} from './libraries/DataTypes.sol';

/**
 * @title Incubator
 * @author Derivative NFT Protocol
 * 
 * @notice This is the contract that is minted upon collecting a given publication of dNFT. 
 *         It is cloned upon the first collect for a given publication of dNFT.
 *         Incubator can receive standard ERC20 and ERC3525 Token
 */
contract Incubator is IIncubator, IERC165, IERC3525Receiver, AccessControl 
{
    using SafeERC20 for IERC20;

    // solhint-disable-next-line const-name-snakecase
    string internal constant _name = "Incubator";

    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant EIP712_REVISION_HASH = keccak256('1');

    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256('Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');
    
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant PERMIT_VALUE_TYPEHASH =
        keccak256('Permit(address spender,uint256 tokenId,uint256 value,uint256 nonce,uint256 deadline)');
    
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant PERMIT_FOR_ALL_TYPEHASH =
        keccak256(
            'PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)'
        );

    // solhint-disable-next-line private-vars-leading-underscore    
    bytes32 internal constant BURN_WITH_SIG_TYPEHASH =
        keccak256('BurnWithSig(uint256 tokenId,uint256 nonce,uint256 deadline)');

    // solhint-disable-next-line private-vars-leading-underscore    
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        );

    mapping(address => uint256) public sigNonces;

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;

    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }

    bool private _initialized;

    uint256 internal _soulBoundTokenId;

    // solhint-disable-next-line var-name-mixedcase
    address private immutable _MANAGER;
    // solhint-disable-next-line var-name-mixedcase
    address private immutable _SOULBOUNDTOKEN;

    constructor(
        address manager,
        address soulBoundToken
    ) {
        if (manager == address(0)) revert Errors.InitParamsInvalid();
        if (soulBoundToken == address(0)) revert Errors.InitParamsInvalid();

        _MANAGER = manager;
        _SOULBOUNDTOKEN = soulBoundToken;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function initialize(uint256 soulBoundTokenId) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        _soulBoundTokenId = soulBoundTokenId;
         
        emit Events.IncubatorInitialized(_soulBoundTokenId, block.timestamp);
    }

    function name() external pure returns(string memory) {
        return _name;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId || 
            interfaceId == type(AccessControl).interfaceId || 
            interfaceId == type(IERC3525Receiver).interfaceId;
    } 

    function onERC3525Received(
        address operator, 
        uint256 fromTokenId, 
        uint256 toTokenId, 
        uint256 value, 
        bytes calldata data
    ) public override returns (bytes4) {
        emit Events.Received(operator, fromTokenId, toTokenId, value, data, gasleft());
        return 0x009ce20b;
    }
 
    function permit(
        address derivativeNFT,
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external {
        if (spender == address(0)) revert Errors.ZeroSpender();
        
        address owner = ERC3525Upgradeable(derivativeNFT).ownerOf(tokenId);

         unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            spender,
                            tokenId,
                            sigNonces[owner]++,
                            sig.deadline
                        )
                    )
                ),
                owner,
                sig
            );
        }
        ERC3525Upgradeable(derivativeNFT).approve(spender, tokenId);
    }
 
    function permitValue(
        address derivativeNFT,
        address spender,
        uint256 tokenId,
        uint256 value,
        DataTypes.EIP712Signature calldata sig
    ) external {
        if (spender == address(0)) revert Errors.ZeroSpender();
        
        address owner = ERC3525Upgradeable(derivativeNFT).ownerOf(tokenId);

         unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            PERMIT_VALUE_TYPEHASH,
                            spender,
                            tokenId,
                            value,
                            sigNonces[owner]++,
                            sig.deadline
                        )
                    )
                ),
                owner,
                sig
            );
        }
        ERC3525Upgradeable(derivativeNFT).approve(tokenId, spender, value);
    }

    function permitForAll(
        address derivativeNFT,
        address owner,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external {
       if (operator == address(0)) revert Errors.ZeroSpender();
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            PERMIT_FOR_ALL_TYPEHASH,
                            owner,
                            operator,
                            approved,
                            sigNonces[owner]++,
                            sig.deadline
                        )
                    )
                ),
                owner,
                sig
            );
        }
        ERC3525Upgradeable(derivativeNFT).setApprovalForAll(operator, approved);
    }

    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(
        bytes32 digest,
        address expectedAddress,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        if (sig.deadline < block.timestamp) revert Errors.SignatureExpired();
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        if (recoveredAddress == address(0) || recoveredAddress != expectedAddress)
            revert Errors.SignatureInvalid();
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(_name)),
                    EIP712_REVISION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
     *
     * @param hashedMessage The message hash from which the digest should be calculated.
     *
     * @return bytes32 A 32-byte output representing the EIP712 digest.
     */
    function _calculateDigest(bytes32 hashedMessage) internal view returns (bytes32) {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked('\x19\x01', _calculateDomainSeparator(), hashedMessage)
            );
        }
        return digest;
    }

    function getDomainSeparator() external view override returns (bytes32) {
        return _calculateDomainSeparator();
    }
    
     //TODO
     // split
     // combo
     // publish
    //TODO withdraw deposit royalties

    
}