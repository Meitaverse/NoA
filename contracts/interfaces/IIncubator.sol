// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IIncubator
 * @author ShowDao Protocol
 *
 * @notice This is the interface for the Incubator contract, which is cloned for any SoulBoundToken.
 */
interface IIncubator {
    /**
     * @notice Initializes the Incubator, setting the manager as the privileged minter and storing the associated SoulBoundToken ID.
     *
     * @param soulBoundTokenId The token ID of the profile in the manager associated with this Incubator, used for transfer hooks.
     */
    function initialize(uint256 soulBoundTokenId) external;

    function name() external returns(string memory);

    /**
     * @notice Implementation of an EIP-712 permit function for an ERC-3525 token (NDPT). We don't need to check
     * if the tokenId exists, since the function calls ownerOf(tokenId), which reverts if the tokenId does
     * not exist.
     *
     * @param derivativeNFT The dNFT spender.
     * @param spender The NPDT spender.
     * @param tokenId The NPDT token ID to approve.
     * @param sig The EIP712 signature struct.
     */
    function permit(
        address derivativeNFT,
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external;

    function permitValue(
        address derivativeNFT,
        address spender,
        uint256 tokenId,
        uint256 value,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Implementation of an EIP-712 permit-style function for ERC-3525 operator approvals. Allows
     * an operator address to control all NDPT a given owner owns.
     *
     * @param derivativeNFT The derivativeNFT contract 
     * @param owner The owner to set operator approvals for.
     * @param operator The operator to approve.
     * @param approved Whether to approve or revoke approval from the operator.
     * @param sig The EIP712 signature struct.
     */
    function permitForAll(
        address derivativeNFT,
        address owner,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Returns the domain separator for this NDPT contract.
     *
     * @return bytes32 The domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

     //TODO withdraw deposit royalties
}