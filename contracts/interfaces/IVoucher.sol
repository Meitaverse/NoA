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

    function mintNFT(
        uint256 soulBoundTokenId,
        uint256 amountNDP,
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

    function getVoucherData(uint256 voucherId) external view returns(DataTypes.VoucherData memory);

    function setTokenUri(uint tokenId_, string memory uri_) external;

    function setBankTreasury(address bankTreasury) external;

    // function setGlobalModule(address moduleGlobals) external;
    
    /**
     * @notice generate a voucher card by voucherType,
     * 
     * @dev only call by owner
     *
     * @param account The account to exchange 
     * @param voucherId The account to received 
     * @param voucherId The soulBoundTokenId of  
     *
     */
    function useVoucher(address account, uint256 voucherId, uint256 soulBoundTokenId) external;

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
