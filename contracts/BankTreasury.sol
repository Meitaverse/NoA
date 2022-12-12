// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {DataTypes} from './libraries/DataTypes.sol';
import {IBankTreasury} from './interfaces/IBankTreasury.sol';
import {IIncubator} from "./interfaces/IIncubator.sol";
import "./libraries/EthAddressLib.sol";

/**
 *  @title Bank Treasury
 *  @author bitsoul Protocol
 * 
 *  Holds the fee, and set currencies whitelist
 * 
 */
contract BankTreasury is IBankTreasury, IERC165, IERC3525Receiver, AccessControl {
    using SafeERC20 for IERC20;

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );

    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransactionERC3525(uint256 indexed txIndex, uint256 indexed fromTokenId, uint256 indexed toTokenId, uint256 value);
    event WithdrawERC3525(uint256 indexed fromTokenId, uint256 indexed toTokenId, uint256 value);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    bool private _initialized;

    // solhint-disable-next-line var-name-mixedcase
    address private immutable _MANAGER;
    // solhint-disable-next-line var-name-mixedcase
    address private immutable _NDPT;

    address private _goverance;

    struct Transaction {
        address currency;
        DataTypes.CurrencyType currencyType;
        address to;
        uint256 fromTokenId;
        uint256 toTokenId;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }


    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor( 
        address manager,
        address ndpt,
        address[] memory _owners, 
        uint256 _numConfirmationsRequired
    ) {
        if (manager == address(0)) revert Errors.InitParamsInvalid();
        if (ndpt == address(0)) revert Errors.InitParamsInvalid();
       
        _MANAGER = manager;
        _NDPT = ndpt;

        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function initialize(address goverance) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;

        if (goverance == address(0)) revert Errors.InitParamsInvalid();
        _goverance = goverance;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
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

    function submitTransaction(
        address _currency,
        DataTypes.CurrencyType _currencyType,
        address _to,
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                currency: _currency,
                currencyType: _currencyType,
                to: _to,
                fromTokenId: _fromTokenId,
                toTokenId: _toTokenId,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        if (transaction.currencyType == DataTypes.CurrencyType.ETHER) {
            (bool success, ) = transaction.to.call{value: transaction.value}(
                transaction.data
            );
            require(success, "tx failed");
        } else if (transaction.currencyType == DataTypes.CurrencyType.ERC20) {
            IERC20(transaction.currency).safeTransfer(transaction.to, transaction.value);

        } else  if (transaction.currencyType == DataTypes.CurrencyType.ERC3525) {
           IERC3525(transaction.currency).transferFrom(transaction.fromTokenId, transaction.toTokenId, transaction.value);
           emit ExecuteTransactionERC3525(_txIndex, transaction.fromTokenId, transaction.toTokenId, transaction.value);
        }

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address currency,
            address to,
            uint256 fromTokenId,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.currency,
            transaction.to,
            transaction.fromTokenId,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function withdrawERC3525(
        address currency, 
        uint256 fromTokenId, 
        uint256 toTokenId, 
        uint256 value
        // uint256 nonce, 
        // DataTypes.EIP712Signature calldata sig
    ) external {
        IERC3525(currency).transferFrom(fromTokenId, toTokenId, value);
        emit WithdrawERC3525(fromTokenId, toTokenId, value);
    }
 
    function exchangeNDPT(
        address currency, 
        uint256 fromTokenId, 
        uint256 toTokenId,
        uint256 value
        // uint256 nonce, 
        // DataTypes.EIP712Signature calldata sign
    ) external payable {
        if (currency == EthAddressLib.ethAddress()) {

        }
    }
}
