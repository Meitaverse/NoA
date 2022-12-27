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

    // function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    
    function generateVoucher(
        DataTypes.VoucherParValueType vouchType,
        address account
    ) external;

    function generateVoucherBatch(
        DataTypes.VoucherParValueType[] memory vouchTypes,
        address account
    ) external;

    function getVoucher(uint256 voucherId) external view returns(DataTypes.VoucherData memory);

    function setTokenUri(uint tokenId_, string memory uri_) external;

    function setBankTreasury(address bankTreasury) external;
    
    function useVoucher(uint256 voucherId, uint256 soulBoundTokenId) external;

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
