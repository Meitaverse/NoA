// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IncubatorProxy} from '../upgradeability/IncubatorProxy.sol';
import {DerivativeNFTProxy} from '../upgradeability/DerivativeNFTProxy.sol';
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {Constants} from './Constants.sol';
import {IIncubator} from '../interfaces/IIncubator.sol';
import {IDerivativeNFTV1} from "../interfaces/IDerivativeNFTV1.sol";

import {ICollectModule} from '../interfaces/ICollectModule.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {IERC3525} from "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {IManager} from "../interfaces/IManager.sol";
// import "./EthAddressLib.sol";
import "./SafeMathUpgradeable128.sol";

/**
 * @title InteractionLogic
 * @author bitsoul.xyz
 *
 * @notice This is the library that contains the logic for follows & collects. 
 
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood.
 */
library InteractionLogic {
    using Strings for uint256;


   function airdropDerivativeNFT(
        uint256 projectId,
        address derivativeNFT,
        address operator,
        uint256 fromSoulBoundTokenId,
        uint256[] memory toSoulBoundTokenIds,
        uint256 tokenId,
        uint256[] memory values
    ) external {
        if (toSoulBoundTokenIds.length != values.length) revert Errors.LengthNotSame();
        for (uint256 i = 0; i < toSoulBoundTokenIds.length; ) {
            uint256 newTokenId = IDerivativeNFTV1(derivativeNFT).split(tokenId, toSoulBoundTokenIds[i], values[i]);

            emit Events.AirdropDerivativeNFT(
                projectId,
                derivativeNFT,
                fromSoulBoundTokenId,
                operator,
                toSoulBoundTokenIds[i],
                tokenId,
                values[i],
                newTokenId,
                block.timestamp
            );

            unchecked {
                ++i;
            }
        }
    }

    function deployIncubatorContract(
       uint256  soulBoundTokenId
    ) external returns (address) {
        bytes memory functionData = abi.encodeWithSelector(
            IIncubator.initialize.selector,
            soulBoundTokenId
        );
        address incubatorContract = address(new IncubatorProxy(functionData));
        emit Events.IncubatorContractDeployed(soulBoundTokenId, incubatorContract, block.timestamp);
        return incubatorContract;
    }

    function createHub(
        address creater, 
        uint256 soulBoundTokenId,
        uint256 hubId,
        DataTypes.Hub memory hub,
        bytes calldata createHubModuleData,
        mapping(uint256 => DataTypes.Hub) storage _hubInfos
    ) external {
         _hubInfos[hubId] = DataTypes.Hub({
             soulBoundTokenId : soulBoundTokenId,
             name: hub.name,
             description: hub.description,
             image: hub.image,
             metadataURI: hub.metadataURI,
             timestamp: block.timestamp
        });

        //TODO
        createHubModuleData;

        emit Events.CreateHub(creater, soulBoundTokenId, hubId, uint32(block.timestamp));

    }

    function createProject(
        uint256 hubId,
        uint256 projectId,
        uint256 soulBoundTokenId,
        DataTypes.Project memory project,
        address metadataDescriptor,
        bytes calldata projectModuleData,
        mapping(uint256 => address) storage _derivativeNFTByProjectId
    ) external returns(uint256) {
         
        if(_derivativeNFTByProjectId[projectId] == address(0)) {
               address derivativeNFT = _deployDerivativeNFT(
                    hubId,
                    projectId,
                    soulBoundTokenId,
                    project.name, 
                    project.description,
                    metadataDescriptor
                );
                _derivativeNFTByProjectId[projectId] = derivativeNFT;
        }
        //TODO, pre and toggle
        projectModuleData;

        return projectId;
        
    }

    function _deployDerivativeNFT(
        uint256 hubId,
        uint256 projectId,
        uint256  soulBoundTokenId,
        string memory name_,
        string memory symbol_,
        address metadataDescriptor_
    ) private returns (address) {
        bytes memory functionData = abi.encodeWithSelector(
            IDerivativeNFTV1.initialize.selector,
            name_,
            symbol_,
            hubId,
            projectId,
            soulBoundTokenId,
            metadataDescriptor_
        );
        address derivativeNFT = address(new DerivativeNFTProxy(functionData));
        emit Events.DerivativeNFTDeployed(hubId, soulBoundTokenId, derivativeNFT, block.timestamp);
        return derivativeNFT;
    } 
    
     function transferDerivativeNFT(
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 projectId,
        address derivativeNFT,
        address fromIncubator,
        address toIncubator,
        uint256 tokenId,
        bytes calldata transferModuledata
    ) external {
    
         IERC3525(derivativeNFT).transferFrom(fromIncubator, toIncubator, tokenId);

         //TODO process data
         transferModuledata;

         emit Events.TransferDerivativeNFT(
            fromSoulBoundTokenId,
            toSoulBoundTokenId,
            projectId,
            tokenId,
            block.timestamp
         );

    }

    function transferValueDerivativeNFT(
        uint256 fromSoulBoundTokenId,
        uint256 toSoulBoundTokenId,
        uint256 projectId,
        address derivativeNFT,
        address toIncubator,
        uint256 tokenId,
        uint256 value,
        bytes calldata transferValueModuledata
    ) external {
    
        uint256 newTokenId = IERC3525(derivativeNFT).transferFrom(tokenId, toIncubator, value);

         //TODO process data
         transferValueModuledata;

         emit Events.TransferValueDerivativeNFT(
            fromSoulBoundTokenId,
            toSoulBoundTokenId,
            projectId,
            tokenId,
            value,
            newTokenId,
            block.timestamp
         );

    }
    
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeMathUpgradeable128 for uint128;

    uint16 internal constant PERCENTAGE_BASE = 10000;

    function publishFixedPrice(
        DataTypes.Sale memory sale,
        mapping(address => DataTypes.Market) storage markets,
        mapping(uint24 => DataTypes.Sale) storage sales
    ) external {

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
            soulBoundTokenId: sale.soulBoundTokenId,
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

}
