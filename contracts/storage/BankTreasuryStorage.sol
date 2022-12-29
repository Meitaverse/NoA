//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';

contract BankTreasuryStorage  {

    //SBT id of BankTreasury
    uint256 _soulBoundTokenId;

    
    mapping(address => uint256) public sigNonces;

    // solhint-disable-next-line var-name-mixedcase
    address internal _MANAGER;
    address internal  _governance;
    address internal  _NDPT;
    address internal  _Voucher;

    address[] internal _signers;
    mapping(address => bool) internal _isSigner;
    uint256 internal _numConfirmationsRequired;
 
    // mapping from tx index => signer => bool
    mapping(uint256 => mapping(address => bool)) internal _isConfirmed;

    DataTypes.Transaction[] internal _transactions;

    uint256 internal _exchangePrice;

    uint256 internal _discountRecharge = 950;  //base point 10000

    mapping(DataTypes.VoucherParValueType => uint256) internal _voucherParValues;
    
}
