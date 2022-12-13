// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {Errors} from "./Errors.sol";
import {DataTypes} from './DataTypes.sol';
import {Events} from "./Events.sol";
import {IManager} from "../interfaces/IManager.sol";
import {IDerivativeNFTV1} from "../interfaces/IDerivativeNFTV1.sol";
import "./EthAddressLib.sol";
import "./SafeMathUpgradeable128.sol";

library MarketLogic {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeMathUpgradeable128 for uint128;

    uint16 internal constant PERCENTAGE_BASE = 10000;

    function publishFixedPrice(
        DataTypes.Sale memory sale,
        mapping(address => DataTypes.Market) storage markets,
        mapping(uint24 => DataTypes.Sale) storage sales
    ) external  {

        // DataTypes.PriceType priceType_ = DataTypes.PriceType.FIXED;

        require(markets[sale.derivativeNFT].isValid, "unsupported derivativeNFT");
        //TODO
        // require(currencies[currency_] || currency_ == IUnderlyingContainer(icToken_).underlying(), "unsupported currency");
        if (sale.max > 0) {
            require(sale.min <= sale.max, "min > max");
        }

        uint128 units = uint128(IERC3525(sale.derivativeNFT).balanceOf(sale.tokenId));
        require(units <= type(uint128).max, "exceeds uint128 max");
        sales[sale.saleId] = DataTypes.Sale({
            saleId: sale.saleId,
            soundBoundTokenId: sale.soundBoundTokenId,
            projectId : sale.projectId,
            seller: msg.sender,
            price: sale.price,
            tokenId: sale.tokenId,
            total: uint128(units),
            units: uint128(units),
            startTime: sale.startTime,
            min: sale.min,
            max: sale.max,
            derivativeNFT: sale.derivativeNFT,
            currency: sale.currency,
            priceType: sale.priceType,
            useAllowList: sale.useAllowList,
            isValid: true
        });

        emit Events.PublishSale(
            sale.derivativeNFT,
            sale.seller,
            sale.tokenId,
            sale.saleId,
            uint8(sale.priceType),
            sale.units,
            sale.startTime,
            sale.currency,
            sale.min,
            sale.max,   
            sale.useAllowList
        );
        
        emit Events.FixedPriceSet(
            sale.derivativeNFT,
            sale.saleId,
            sale.projectId,
            sale.tokenId,
            uint128(units),
            uint8(sale.priceType),
            sale.price
        );
    }

    function removeSale(
        uint24 saleId_,
        mapping(uint24 => DataTypes.Sale) storage sales
    ) external {
        DataTypes.Sale memory sale = sales[saleId_];
        require(sale.isValid, "invalid sale");
        require(sale.seller == msg.sender, "only seller");

        delete sales[saleId_];

        emit Events.RemoveSale(
            sale.derivativeNFT,
            sale.seller,
            sale.saleId,
            sale.total,
            sale.total - sale.units
        );
    }

    function addMarket(
        address derivativeNFT_,
        uint64 precision_,
        uint8 feePayType_,
        uint8 feeType_,
        uint128 feeAmount_,
        uint16 feeRate_,
        mapping(address => DataTypes.Market) storage markets
    ) external {
        markets[derivativeNFT_].isValid = true;
        markets[derivativeNFT_].precision = precision_;
        markets[derivativeNFT_].feePayType = DataTypes.FeePayType(feePayType_);
        markets[derivativeNFT_].feeType = DataTypes.FeeType(feeType_);
        markets[derivativeNFT_].feeAmount = feeAmount_;
        markets[derivativeNFT_].feeRate = feeRate_;

        emit Events.AddMarket(
            derivativeNFT_,
            precision_,
            feePayType_,
            feeType_,
            feeAmount_,
            feeRate_
        );
    }

    function removeMarket(
        address derivativeNFT_,
        mapping(address => DataTypes.Market) storage markets
    ) external {
        delete markets[derivativeNFT_];
        emit Events.RemoveMarket(derivativeNFT_);
    }

    function buyByUnits(
        uint256 nextTradeId_,
        address buyer_,
        uint24 saleId_, 
        uint128 price_,
        uint128 units_,
        mapping(address => DataTypes.Market) storage markets,
        mapping(uint24 => DataTypes.Sale) storage sales
    ) external returns (uint256 amount_, uint128 fee_) {
        DataTypes.Sale storage sale_ = sales[saleId_];

        amount_ = uint256(units_).mul(uint256(price_)).div(
            uint256(markets[sale_.derivativeNFT].precision)
        );

        // if (
        //     sale_.currency == EthAddressLib.ethAddress() &&
        //     sale_.priceType == DataTypes.PriceType.DECLIINING_BY_TIME &&
        //     amount_ != msg.value
        // ) {
        //     amount_ = msg.value;
        //     uint128 fee = _getFee(sale_.derivativeNFT, sale_.currency, amount_, markets);
        //     uint256 units256;
        //     if (markets[sale_.derivativeNFT].feePayType == DataTypes.FeePayType.BUYER_PAY) {
        //         units256 = amount_
        //         .sub(fee, "fee exceeds amount")
        //         .mul(uint256(markets[sale_.derivativeNFT].precision))
        //         .div(uint256(price_));
        //     } else {
        //         units256 = amount_
        //         .mul(uint256(markets[sale_.derivativeNFT].precision))
        //         .div(uint256(price_));
        //     }
        //     require(units256 <= type(uint128).max, "exceeds uint128 max");
        //     units_ = uint128(units256);
        // }

        fee_ = _getFee(sale_.derivativeNFT, sale_.currency, amount_, markets);

        sale_.units = sale_.units.sub(units_, "insufficient units for sale");
        // DataTypes.FeePayType feePayType =  DataTypes.FeePayType.BUYER_PAY;
        // BuyLocalVar memory vars;
        // vars.feePayType = markets[sale_.icToken].feePayType;

        // if (vars.feePayType == FeePayType.BUYER_PAY) {
        //     vars.transferInAmount = amount_.add(fee_);
        //     vars.transferOutAmount = amount_;
        // } else if (vars.feePayType == FeePayType.SELLER_PAY) {
        //     vars.transferInAmount = amount_;
        //     vars.transferOutAmount = amount_.sub(fee_, "fee exceeds amount");
        // } else {
        //     revert("unsupported feePayType");
        // }

        // ERC20TransferHelper.doTransferIn(
        //     sale_.currency,
        //     buyer_,
        //     vars.transferInAmount
        // );
        // if (units_ == IVNFT(sale_.icToken).unitsInToken(sale_.tokenId)) {
        //     VNFTTransferHelper.doTransferOut(
        //         sale_.icToken,
        //         buyer_,
        //         sale_.tokenId
        //     );
        // } else {
        //     VNFTTransferHelper.doTransferOut(
        //         sale_.icToken,
        //         buyer_,
        //         sale_.tokenId,
        //         units_
        //     );
        // }

        // ERC20TransferHelper.doTransferOut(
        //     sale_.currency,
        //     payable(sale_.seller),
        //     vars.transferOutAmount
        // );

        //CompilerError: Stack too deep.
        emit Events.Traded(
            buyer_,
            sale_.saleId,
            sale_.derivativeNFT,
            sale_.tokenId,
            nextTradeId_,
            uint32(block.timestamp),
            sale_.currency,
            uint8(sale_.priceType),
            price_,
            units_,
            amount_,
            // uint8(feePayType),
            fee_
        );  

        if (sale_.units == 0) {
            emit Events.RemoveSale(
                sale_.derivativeNFT,
                sale_.seller,
                sale_.saleId,
                sale_.total,
                sale_.total - sale_.units
            );
            delete sales[sale_.saleId];
        }
        return (amount_, fee_);
    }


    function _getFee(
        address derivativeNFT_, 
        address currency_, 
        uint256 amount,
        mapping(address => DataTypes.Market) storage markets
    )
        internal
        view
        returns (uint128)
    {
        // if (currency_ == IUnderlyingContainer(derivativeNFT_).underlying()) {
        //     uint256 fee = amount.mul(uint256(repoFeeRate)).div(PERCENTAGE_BASE);
        //     require(fee <= type(uint128).max, "Fee: exceeds uint128 max");
        //     return uint128(fee);
        // }

        DataTypes.Market storage market = markets[derivativeNFT_];
        if (market.feeType == DataTypes.FeeType.FIXED) {
            return market.feeAmount;
        } else if (market.feeType == DataTypes.FeeType.BY_AMOUNT) {
            uint256 fee = amount.mul(uint256(market.feeRate)).div(
                uint256(PERCENTAGE_BASE)
            );
            require(fee <= type(uint128).max, "Fee: exceeds uint128 max");
            return uint128(fee);
        } else {
            revert("unsupported feeType");
        }
    }

    function purchasedUnits(
        uint24 saleId_, 
        address buyer_,
        mapping(uint24 => mapping(address => uint128)) storage saleRecords
    ) external view returns(uint128) {
        return saleRecords[saleId_][buyer_];
    }

    // function getPrice(uint24 saleId_)
    //     external
    //     view
    //     returns (uint128)
    // {
    //     return PriceManager.price(sales[saleId_].priceType, saleId_);
    // }

    function totalSalesOfICToken(
        address derivativeNFT_,
        mapping(address => EnumerableSetUpgradeable.UintSet) storage _derivativeNFTSale
    )
        public
        view
        returns (uint256)
    {
        return _derivativeNFTSale[derivativeNFT_].length();
    }

    function saleIdOfICTokenByIndex(
        address derivativeNFT_, 
        uint256 index_,
        mapping(address => EnumerableSetUpgradeable.UintSet) storage _derivativeNFTSale
    )
        public
        view
        returns (uint256)
    {
        return _derivativeNFTSale[derivativeNFT_].at(index_);
    }

    /*

    mapping(address => bool) public currencies;

    ISolver public solver;
    uint24 public nextSaleId;
    address payable public pendingAdmin;
    uint24 public nextTradeId;
    address payable public admin;
    bool public initialized;
    uint16 internal constant PERCENTAGE_BASE = 10000;

    // managers with authorities to set allow addresses of a voucher market
    mapping(address => EnumerableSetUpgradeable.AddressSet) internal allowAddressManagers;

    uint16 public repoFeeRate;

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyAllowAddressManager(address icToken_) {
        require(msg.sender == admin || allowAddressManagers[icToken_].contains(msg.sender), "only manager");
        _;
    }

    struct PublishDecliningPriceLocalVars {
        address icToken;
        uint24 tokenId;
        address currency;
        uint128 min;
        uint128 max;
        uint32 startTime;
        bool useAllowList;
        uint128 highest;
        uint128 lowest;
        uint32 duration;
        uint32 interval;
        address seller;
    }

    function publishDecliningPrice(
        address icToken_,
        uint24 tokenId_,
        address currency_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        bool useAllowList_,
        uint128 highest_,
        uint128 lowest_,
        uint32 duration_,
        uint32 interval_
    ) external virtual override returns (uint24 saleId) {
        PublishDecliningPriceLocalVars memory vars;
        vars.seller = msg.sender;
        vars.icToken = icToken_;
        vars.tokenId = tokenId_;
        vars.currency = currency_;
        vars.min = min_;
        vars.max = max_;
        vars.startTime = startTime_;
        vars.useAllowList = useAllowList_;
        vars.highest = highest_;
        vars.lowest = lowest_;
        vars.duration = duration_;
        vars.interval = interval_;

        require(vars.interval > 0, "interval cannot be 0");
        require(vars.lowest <= vars.highest, "lowest > highest");
        require(vars.duration > 0, "duration cannot be 0");

        uint256 err = solver.publishDecliningPriceAllowed(
            vars.icToken,
            vars.tokenId,
            vars.seller,
            vars.currency,
            vars.min,
            vars.max,
            vars.startTime,
            vars.useAllowList,
            vars.highest,
            vars.lowest,
            vars.duration,
            vars.interval
        );
        require(err == 0, "Solver: not allowed");

        PriceManager.PriceType priceType = PriceManager
        .PriceType
        .DECLIINING_BY_TIME;
        saleId = _publish(
            vars.seller,
            vars.icToken,
            vars.tokenId,
            vars.currency,
            priceType,
            vars.min,
            vars.max,
            vars.startTime,
            vars.useAllowList
        );

        PriceManager.setDecliningPrice(
            saleId,
            vars.startTime,
            vars.highest,
            vars.lowest,
            vars.duration,
            vars.interval
        );

        emit DecliningPriceSet(
            vars.icToken,
            saleId,
            vars.tokenId,
            vars.highest,
            vars.lowest,
            vars.duration,
            vars.interval
        );
    }

    function buyByAmount(uint24 saleId_, uint256 amount_)
        external
        payable
        virtual
        override
        returns (uint128 units_)
    {
        Sale storage sale = sales[saleId_];
        address buyer = msg.sender;
        uint128 fee = _getFee(sale.icToken, sale.currency, amount_);
        uint128 price = PriceManager.price(sale.priceType, sale.saleId);
        uint256 units256;
        if (markets[sale.icToken].feePayType == FeePayType.BUYER_PAY) {
            units256 = amount_
            .sub(fee, "fee exceeds amount")
            .mul(uint256(markets[sale.icToken].precision))
            .div(uint256(price));
        } else {
            units256 = amount_
            .mul(uint256(markets[sale.icToken].precision))
            .div(uint256(price));
        }
        require(units256 <= type(uint128).max, "exceeds uint128 max");
        units_ = uint128(units256);

        uint256 err = solver.buyAllowed(
            sale.icToken,
            sale.tokenId,
            saleId_,
            buyer,
            sale.currency,
            amount_,
            units_,
            price
        );
        require(err == 0, "Solver: not allowed");

        _buy(buyer, sale, amount_, units_, price, fee);
        return units_;
    }

    struct BuyLocalVar {
        uint256 transferInAmount;
        uint256 transferOutAmount;
        FeePayType feePayType;
    }

    function _generateNextSaleId() internal returns (uint24) {
        return nextSaleId++;
    }

    function _generateNextTradeId() internal returns (uint24) {
        return nextTradeId++;
    }

    function _setCurrency(address currency_, bool enable_) public onlyAdmin {
        currencies[currency_] = enable_;
        emit SetCurrency(currency_, enable_);
    }

    function _setRepoFeeRate(uint16 newRepoFeeRate_) external onlyAdmin {
        repoFeeRate = newRepoFeeRate_;
    }

    function _withdrawFee(address icToken_, uint256 reduceAmount_)
        public
        onlyAdmin
    {
        require(
            ERC20TransferHelper.getCashPrior(icToken_) >= reduceAmount_,
            "insufficient cash"
        );
        ERC20TransferHelper.doTransferOut(icToken_, admin, reduceAmount_);
        emit WithdrawFee(icToken_, reduceAmount_);
    }

    function _addAllowAddress(
        address icToken_, 
        address[] calldata addresses_,
        bool resetExisting_
    ) external onlyAllowAddressManager(icToken_) {
        require(markets[icToken_].isValid, "unsupported icToken");
        EnumerableSetUpgradeable.AddressSet storage set = _allowAddresses[icToken_];

        if (resetExisting_) {
            while (set.length() != 0) {
                set.remove(set.at(0));
            }
        }

        for (uint256 i = 0; i < addresses_.length; i++) {
            set.add(addresses_[i]);
        }
    }

    function _removeAllowAddress(
        address icToken_,
        address[] calldata addresses_
    ) external onlyAllowAddressManager(icToken_) {
        require(markets[icToken_].isValid, "unsupported icToken");
        EnumerableSetUpgradeable.AddressSet storage set = _allowAddresses[icToken_];
        for (uint256 i = 0; i < addresses_.length; i++) {
            set.remove(addresses_[i]);
        }
    }

    function isBuyerAllowed(address icToken_, address buyer_) external view returns (bool) {
        return _allowAddresses[icToken_].contains(buyer_);
    }

    function setAllowAddressManager(
        address icToken_, 
        address[] calldata managers_, 
        bool resetExisting_
    ) external onlyAdmin {
        require(markets[icToken_].isValid, "unsupported icToken");
        EnumerableSetUpgradeable.AddressSet storage set = allowAddressManagers[icToken_];
        if (resetExisting_) {
            while (set.length() != 0) {
                set.remove(set.at(0));
            }
        }

        for (uint256 i = 0; i < managers_.length; i++) {
            set.add(managers_[i]);
        }
    }

    function allowAddressManager(address icToken_, uint256 index_) external view returns(address) {
        return allowAddressManagers[icToken_].at(index_);
    }

    function _setSolver(ISolver newSolver_) public virtual onlyAdmin {
        ISolver oldSolver = solver;
        require(newSolver_.isSolver(), "invalid solver");
        solver = newSolver_;

        emit NewSolver(oldSolver, newSolver_);
    }

    function _setPendingAdmin(address payable newPendingAdmin) public {
        require(msg.sender == admin, "only admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function _acceptAdmin() public {
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "only pending admin"
        );

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    */
}
