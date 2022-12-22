// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {DataTypes} from './libraries/DataTypes.sol';
import {IBankTreasury} from './interfaces/IBankTreasury.sol';
import {IIncubator} from "./interfaces/IIncubator.sol";
import {IManager} from "./interfaces/IManager.sol";
import {IVoucher} from "./interfaces/IVoucher.sol";
import "./libraries/EthAddressLib.sol";
import "./storage/BankTreasuryStorage.sol";

/**
 *  @title Bank Treasury
 *  @author bitsoul Protocol
 * 
 *  Holds the fee, and set currencies whitelist
 * 
 */
contract BankTreasury is 
    Initializable, 
    IBankTreasury, 
    BankTreasuryStorage,
    IERC165, 
    IERC3525Receiver, 
    PausableUpgradeable,
    AccessControlUpgradeable, 
    IERC1155ReceiverUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint16 internal constant BPS_MAX = 10000;

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    /**
     * @dev This modifier reverts if the caller is not the configured manager address.
     */
    modifier onlyManager() {
        _validateCallerIsManager();
        _;
    }
    
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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address manager,
        address governance,
        address ndpt,
        address voucher,
        uint256 soulBoundTokenId,
        address[] memory _owners, 
        uint256 _numConfirmationsRequired
    ) external override initializer { 
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        if (manager == address(0)) revert Errors.InitParamsInvalid();
        if (governance == address(0)) revert Errors.InitParamsInvalid();
        if (ndpt == address(0)) revert Errors.InitParamsInvalid();
       
        _setManager(manager);
        _setGovernance(governance);
        _setNDPT(ndpt);
        _setVoucher(voucher);
        _soulBoundTokenId = soulBoundTokenId;

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

    }

    function setManager(address newManager) external onlyGov {
        _setManager(newManager);
    }

    function _setManager(address newManager) internal {
        _MANAGER = newManager;
    }

    function getManager() external view returns(address) {
        return _MANAGER;
    }
    
    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    function getGovernance() external view returns(address) {
        return _governance;
    }

    function setNDPT(address newNDPT) external override onlyGov {
        _setNDPT(newNDPT);
    }
    
    function _setNDPT(address newNDPT) internal {
       _NDPT = newNDPT;
    }
    
    function setVoucher(address newVoucher) external override onlyGov {
       _setVoucher(newVoucher);
    }

    function _setVoucher(address newVoucher) internal {
       _Voucher = newVoucher;
    }

     function getVoucher() external view returns(address) {
        return _Voucher;
     }

    function getNDPT() external view returns(address) {
        return _NDPT;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    receive() external payable {
        emit Events.Deposit(msg.sender, msg.value, address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, IERC165, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId || 
            interfaceId == type(AccessControlUpgradeable).interfaceId || 
            interfaceId == type(IERC3525Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    } 

    function onERC3525Received(
        address operator, 
        uint256 fromTokenId, 
        uint256 toTokenId, 
        uint256 value, 
        bytes calldata data
    ) public override returns (bytes4) {
        emit Events.ERC3525Received(operator, fromTokenId, toTokenId, value, data, gasleft());
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
    ) public whenNotPaused onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            DataTypes.Transaction({
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

        emit Events.SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        whenNotPaused
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        DataTypes.Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit Events.ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        public
        whenNotPaused
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        DataTypes.Transaction storage transaction = transactions[_txIndex];

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
            IERC20Upgradeable(transaction.currency).safeTransfer(transaction.to, transaction.value);

        } else  if (transaction.currencyType == DataTypes.CurrencyType.ERC3525) {
           IERC3525(transaction.currency).transferFrom(transaction.fromTokenId, transaction.toTokenId, transaction.value);
           emit Events.ExecuteTransactionERC3525(_txIndex, transaction.fromTokenId, transaction.toTokenId, transaction.value);
        }

        emit Events.ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        whenNotPaused
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        DataTypes.Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit Events.RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint256) {
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
        DataTypes.Transaction storage transaction = transactions[_txIndex];

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
    ) external whenNotPaused {
        IERC3525(currency).transferFrom(fromTokenId, toTokenId, value);
        emit Events.WithdrawERC3525(fromTokenId, toTokenId, value);
    }
 
    function exchangeNDPT(
        address currency, 
        uint256 fromTokenId, 
        uint256 toTokenId,
        uint256 value
        // uint256 nonce, 
        // DataTypes.EIP712Signature calldata sign
    ) external payable whenNotPaused {
        if (currency == EthAddressLib.ethAddress()) {

        }
    }

    function createVoucher(
        address account, 
        uint256 id, 
        uint256 amount, 
        bytes memory data 
    ) external payable whenNotPaused onlyGov {
        IVoucher(_Voucher).mint(account, id, amount, data);
    }

    function createBatchVoucher(
        address account, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data 
    ) external payable whenNotPaused onlyGov {
        IVoucher(_Voucher).mintBatch(account, ids, amounts, data);
    }

    function setPublishFee(uint256 publishFee) external onlyGov{

    }

    function getPublishFee() external returns (uint256){

    }
    //--- internal  ---//

    function _setGovernance(address newGovernance) internal {
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.GovernanceSet(msg.sender, prevGovernance, newGovernance, block.timestamp);
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }

    function _validateCallerIsManager() internal view {
        if (msg.sender != _MANAGER) revert Errors.NotManager();
    }

    //-- orverride -- //
    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        if (!hasRole(UPGRADER_ROLE, _msgSender())) revert Errors.Unauthorized();
    }

    function getSoulBoundTokenId() external view returns(uint256) {
        return _soulBoundTokenId;
    }

    function onERC1155Received(
        address operator, //操作者
        address from,     //上一个owner
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        //TODO mint NDPT to {from} and burn {id}
        emit Events.ERC1155Received(operator, from, id, value, data, gasleft());
        // uint256 balance = IERC1155Upgradeable(msg.sender).balanceOf(address(this), id);
        uint256 fromTokenId = IManager(_MANAGER).getTokenIdIncubatorOfSoulBoundTokenId(_soulBoundTokenId);
        uint256 toSoulBoundTokenId =  IManager(_MANAGER).getWalletBySoulBoundTokenId(from);
        uint256 toTokenId = IManager(_MANAGER).getTokenIdIncubatorOfSoulBoundTokenId(toSoulBoundTokenId);
        IERC3525(_NDPT).transferFrom(fromTokenId, toTokenId, value);

        IVoucher(_Voucher).burn(address(this), id, value);
    
        return this.onERC1155Received.selector;
    }


    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        //TODO mint NDPT to {from} and burn {id}
        emit Events.ERC1155BatchReceived(operator, from, ids, values, data, gasleft());
        uint256 fromTokenId = IManager(_MANAGER).getTokenIdIncubatorOfSoulBoundTokenId(_soulBoundTokenId);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 toSoulBoundTokenId =  IManager(_MANAGER).getWalletBySoulBoundTokenId(from);
            uint256 toTokenId = IManager(_MANAGER).getTokenIdIncubatorOfSoulBoundTokenId(toSoulBoundTokenId);
            IERC3525(_NDPT).transferFrom(fromTokenId, toTokenId, values[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

}
