// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {DataTypes} from '../libraries/DataTypes.sol';
import {IBankTreasuryV2} from '../interfaces/IBankTreasuryV2.sol';
import {IManager} from "../interfaces/IManager.sol";
import {IVoucher} from "../interfaces/IVoucher.sol";
import "../libraries/EthAddressLib.sol";
import "../storage/BankTreasuryStorage.sol";
import {INFTDerivativeProtocolTokenV1} from "../interfaces/INFTDerivativeProtocolTokenV1.sol";
import {IModuleGlobals} from "../interfaces/IModuleGlobals.sol";

/**
 *  @title Bank TreasuryV2
 *  @author bitsoul Protocol
 * 
 *  Holds the fee, and set currencies whitelist
 */
contract BankTreasuryV2 is 
    Initializable,
    ReentrancyGuard,
    IBankTreasuryV2,
    BankTreasuryStorage,
    IERC165,
    IERC3525Receiver,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        );  

    bytes32 internal constant EIP712_REVISION_HASH = keccak256('1');

    bytes32 internal constant EXCHANGE_SBT_BY_ETHER_TYPEHASH =
        keccak256('ExchangeSBTByEth(address exchangeWallet,uint256 soulBoundTokenId,uint256 amount,uint256 nonce,uint256 deadline)');

    bytes32 internal constant EXCHANGE_ETHER_BY_SBT_TYPEHASH =
        keccak256('ExchangeyEthBySBT(address to,uint256 soulBoundTokenId,uint256 sbtamount,uint256 nonce,uint256 deadline)');

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint16 internal constant BPS_MAX = 10000;

    string public name;

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

    modifier onlySigner() {
        _validateCallerIsSigner();
        _;
    }

    modifier txExists(uint256 _txIndex) {
        _validateTxExists(_txIndex);
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        _validateNotExecuted(_txIndex);
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        _validateNotConfirmed(_txIndex);
        _;
    }

    function setGlobalModule(address moduleGlobals) external onlyGov {
        if (moduleGlobals == address(0)) revert Errors.InitParamsInvalid();
        MODULE_GLOBALS = moduleGlobals;
    }
    
    function getManager() external view returns(address) {
        return IModuleGlobals(MODULE_GLOBALS).getManager();
    }

    function getGovernance() external view returns (address) {
        return _governance;
    }

    function getVoucher() external view returns (address) {
        address _voucher = IModuleGlobals(MODULE_GLOBALS).getVoucher();
        return _voucher;
    }

    function getSBT() external view returns (address) {
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        return _sbt;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    receive() external payable {
        emit Events.Deposit(msg.sender, msg.value, address(this), address(this).balance);
    }

    fallback() external payable {
        emit Events.DepositByFallback(msg.sender, msg.value, msg.data, address(this), address(this).balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlUpgradeable, IERC165) returns (bool) {
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
    ) public whenNotPaused onlySigner {
        uint256 txIndex = _transactions.length;

        _transactions.push(
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

    function confirmTransaction(
        uint256 _txIndex
    ) public whenNotPaused onlySigner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        DataTypes.Transaction storage transaction = _transactions[_txIndex];
        transaction.numConfirmations += 1;
        _isConfirmed[_txIndex][msg.sender] = true;

        emit Events.ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(
        uint256 _txIndex
    ) public whenNotPaused onlySigner txExists(_txIndex) notExecuted(_txIndex) {
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        DataTypes.Transaction storage transaction = _transactions[_txIndex];

        if (transaction.numConfirmations < _numConfirmationsRequired) revert Errors.CannotExecuteTx();

        transaction.executed = true;

        //withdraw ether
        if (transaction.currencyType == DataTypes.CurrencyType.ETHER) {
            (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
            if (!success) revert Errors.TxFailed();
        } else if (transaction.currencyType == DataTypes.CurrencyType.ERC20) {
            IERC20Upgradeable(transaction.currency).safeTransfer(transaction.to, transaction.value);
            emit Events.ExecuteTransaction(
                msg.sender,
                _txIndex,
                transaction.to,
                transaction.value
            );

        } else if (transaction.currencyType == DataTypes.CurrencyType.ERC3525) {
            INFTDerivativeProtocolTokenV1(_sbt).transferValue(
                transaction.fromTokenId,
                transaction.toTokenId,
                transaction.value
            );
            emit Events.ExecuteTransactionERC3525(
                msg.sender,
                _txIndex,
                transaction.fromTokenId,
                transaction.toTokenId,
                transaction.value
            );
        }
    }

    function revokeConfirmation(
        uint256 _txIndex
    ) public whenNotPaused onlySigner txExists(_txIndex) notExecuted(_txIndex) {
        DataTypes.Transaction storage transaction = _transactions[_txIndex];

        if (!_isConfirmed[_txIndex][msg.sender]) revert Errors.TxNotConfirmed();

        transaction.numConfirmations -= 1;
        _isConfirmed[_txIndex][msg.sender] = false;

        emit Events.RevokeConfirmation(msg.sender, _txIndex);
    }

    function getSigners() external view returns (address[] memory) {
        return _signers;
    }

    function getTransactionCount() external view returns (uint256) {
        return _transactions.length;
    }

    function getTransaction(
        uint256 _txIndex
    )
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
        DataTypes.Transaction storage transaction = _transactions[_txIndex];

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

    //testing
    function withdrawERC3525(
        uint256 toSoulBoundTokenId,
        uint256 amount
    )
        external
        whenNotPaused
        nonReentrant
        onlyGov
    {
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        INFTDerivativeProtocolTokenV1(_sbt).transferValue(_soulBoundTokenId, toSoulBoundTokenId, amount);
        emit Events.WithdrawERC3525(_soulBoundTokenId, toSoulBoundTokenId, amount, block.timestamp);
    }

    function calculateAmountEther(uint256 ethAmount) external view returns(uint256) {
          if (_exchangePrice == 0) revert Errors.ExchangePriceIsZero();
        return ethAmount.div(_exchangePrice);
    }

    function calculateAmountSBT(uint256 sbtValue) external view returns(uint256) {
        if (_exchangePrice == 0) revert Errors.ExchangePriceIsZero();
        return sbtValue.mul(_exchangePrice);
    }

    function exchangeSBTByEth(
        uint256 soulBoundTokenId,
        uint256 amount,
        DataTypes.EIP712Signature calldata sig
    )
        external
        payable
        whenNotPaused
        nonReentrant
    {
        // only called by owner of soulBoundTokenId
        address _manager = IModuleGlobals(MODULE_GLOBALS).getManager();

        if (msg.sender != IManager(_manager).getWalletBySoulBoundTokenId(soulBoundTokenId) ) {
            revert Errors.Unauthorized();
        }

        if (_exchangePrice == 0) revert Errors.ExchangePriceIsZero();
        if (amount == 0) revert Errors.AmountIsZero();
        address exchangeWallet = msg.sender;
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            EXCHANGE_SBT_BY_ETHER_TYPEHASH,
                            exchangeWallet,
                            soulBoundTokenId,
                            amount,
                            sigNonces[exchangeWallet]++,
                            sig.deadline
                        )
                    )
                ),
                exchangeWallet,
                sig
            );
        }

        if (msg.value < _exchangePrice.mul(amount)) revert Errors.PaymentError();
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        INFTDerivativeProtocolTokenV1(_sbt).transferValue(_soulBoundTokenId, soulBoundTokenId, amount);

         emit Events.ExchangeSBTByEth(
             soulBoundTokenId,
             exchangeWallet,
             amount,
             block.timestamp
         );

    }

    function exchangeEthBySBT(
        uint256 soulBoundTokenId,
        uint256 sbtValue,
        DataTypes.EIP712Signature calldata sig        
    )
        external
        payable
        whenNotPaused
        nonReentrant
    {
        // only called by owner of soulBoundTokenId
        address _manager = IModuleGlobals(MODULE_GLOBALS).getManager();

        if (msg.sender != IManager(_manager).getWalletBySoulBoundTokenId(soulBoundTokenId)) {
            revert Errors.Unauthorized();
        }

        if (_exchangePrice == 0) revert Errors.ExchangePriceIsZero();
        if (sbtValue == 0) revert Errors.AmountIsZero();
        if (soulBoundTokenId ==0) revert Errors.SoulBoundTokenIdNotExists();
        
        address payable _to = payable(msg.sender);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            EXCHANGE_ETHER_BY_SBT_TYPEHASH,
                            _to,
                            soulBoundTokenId,
                            sbtValue,
                            sigNonces[_to]++,
                            sig.deadline
                        )
                    )
                ),
                _to,
                sig
            );
        }

        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        INFTDerivativeProtocolTokenV1(_sbt).transferValue(soulBoundTokenId, _soulBoundTokenId, sbtValue);

        //transfer eth to msg.sender
        uint256 ethAmount = sbtValue.mul(_exchangePrice);

        (bool success, ) = _to.call{value: ethAmount}("");
        if (!success) revert Errors.TxFailed();

         emit Events.ExchangeEthBySBT(
             soulBoundTokenId,
             _to,
             sbtValue,
             _exchangePrice,
             ethAmount,
             block.timestamp
         );
    }

    function exchangeVoucher(
        uint256 tokenId,
        uint256 soulBoundTokenId
    ) 
        external
        whenNotPaused
        nonReentrant
    {
        address _sbt = IModuleGlobals(MODULE_GLOBALS).getSBT();
        address _voucher = IModuleGlobals(MODULE_GLOBALS).getVoucher();
        //isvalid
        if (IERC3525(_sbt).ownerOf(soulBoundTokenId) != msg.sender ) {
            revert Errors.Unauthorized();
        }

       DataTypes.VoucherData memory voucherData =  IVoucher(_voucher).getVoucherData(tokenId);
       if (voucherData.tokenId == 0) revert Errors.VoucherNotExists();
       if (voucherData.isUsed) revert Errors.VoucherIsUsed();

       INFTDerivativeProtocolTokenV1(_sbt).transferValue(_soulBoundTokenId, soulBoundTokenId, voucherData.sbtValue);
       IVoucher(_voucher).useVoucher(msg.sender, tokenId, soulBoundTokenId); 

       emit Events.ExchangeVoucher(
            soulBoundTokenId,
            msg.sender,
            tokenId,
            voucherData.sbtValue,
            block.timestamp
       );
    }
    
    function setExchangePrice(uint256 exchangePrice_) external nonReentrant onlyGov {
        _exchangePrice = exchangePrice_;
    }

    //--- internal  ---//
    function _setGovernance(address newGovernance) internal {
        _governance = newGovernance;
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }

    function _validateCallerIsManager() internal view {
       address _manager = IModuleGlobals(MODULE_GLOBALS).getManager();
        if (msg.sender != _manager) revert Errors.NotManager();
    }

    function _validateCallerIsSigner() internal view {
        if (!_isSigner[msg.sender]) revert Errors.NotSinger();
    }

    function _validateTxExists(uint256 _txIndex) internal view {
        if (_txIndex >= _transactions.length) revert Errors.TxNotExists();
    }

    function _validateNotExecuted(uint256 _txIndex) internal view {
        if (_transactions[_txIndex].executed) revert Errors.TxAlreadyExecuted();
    }

    function _validateNotConfirmed(uint256 _txIndex) internal view {
        if (_isConfirmed[_txIndex][msg.sender]) revert Errors.TxAlreadyConfirmed();
    }

    //-- orverride -- //
    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        if (!hasRole(UPGRADER_ROLE, _msgSender())) revert Errors.Unauthorized();
    }

    function getDomainSeparator() external view override returns (bytes32) {
        return _calculateDomainSeparator();
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
                    keccak256(bytes(name)),
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
}
