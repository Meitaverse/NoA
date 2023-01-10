// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';

/**
 * @title IVoucher
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the Voucher contract
 */
interface IVoucher {
    /**
     * @notice mint a ERC1155 NFT and transfer value to bank treasury,
     * 
     * @param soulBoundTokenId The soulBoundToken Id of current caller
     * @param amountSBT The amount of SBT
     * @param account The account to received 
     *
     */
    function mintNFT(
        uint256 soulBoundTokenId,
        uint256 amountSBT,
        address account
    ) external;

    /**
     * @notice generate a voucher card by voucherType,
     * 
     * @dev only call by owner
     *
     * @param voucherType The type of voucher.
     * @param account The account to received 
     *
     */
    function generateVoucher(
        DataTypes.VoucherParValueType voucherType,
        address account
    ) external;

    /**
     * @notice generate a voucher card by voucherType,
     * 
     * @dev only call by owner
     *
     * @param voucherTypes The array type of voucher.
     * @param account The account to received 
     *
     */
    function generateVoucherBatch(
        DataTypes.VoucherParValueType[] memory voucherTypes,
        address account
    ) external;

    function getGlobalModule() external view returns(address);

    function getVoucherData(uint256 tokenId) external view returns(DataTypes.VoucherData memory);

    function setTokenUri(uint tokenId_, string memory uri_) external;

    function getUserAmountLimit() external view returns(uint256);

    /**
     * @notice generate a voucher card by voucherType,
     * 
     * @dev only call by owner
     *
     * @param account The account to exchange 
     * @param tokenId The account to received 
     * @param tokenId The soulBoundTokenId of  
     *
     */
    function useVoucher(address account, uint256 tokenId, uint256 soulBoundTokenId) external;

     function burn(
        address owner,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address owner,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
    

}
