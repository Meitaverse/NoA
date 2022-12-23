// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

// import {DerivativeNFTProxy} from '../upgradeability/DerivativeNFTProxy.sol';
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
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {IManager} from "../interfaces/IManager.sol";
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

    function deployIncubatorContract(
       address ndpt,
       uint256  soulBoundTokenId,
       address incubatorImpl
    ) external returns (address) {
        address incubatorContract = Clones.clone(incubatorImpl);
        IIncubator(incubatorContract).initialize(ndpt, soulBoundTokenId);
        emit Events.IncubatorContractDeployed(soulBoundTokenId, incubatorContract, block.timestamp);
        return incubatorContract;
    }

    function createHub(
        uint256 hubId,
        DataTypes.HubData memory hub,
        mapping(uint256 => DataTypes.HubData) storage _hubInfos
    ) external {
        if (hub.creator == address(0)) revert Errors.InvalidParameter();
        
         _hubInfos[hubId] = DataTypes.HubData({
             creator: hub.creator,
             soulBoundTokenId : hub.soulBoundTokenId,
             name: hub.name,
             description: hub.description,
             image: hub.image
        });

        //TODO

        emit Events.CreateHub(
            hubId, 
            hub.creator, 
            hub.soulBoundTokenId, 
            hub.name,
            hub.description,
            hub.image,
            uint32(block.timestamp));

    }

    function createProject(
        address derivativeImpl,
        address ndpt,
        address treasury,
        uint256 projectId,
        DataTypes.ProjectData memory project,
        address metadataDescriptor,
        mapping(uint256 => address) storage _derivativeNFTByProjectId
    ) external returns(address) {
         address derivativeNFT;
        if(_derivativeNFTByProjectId[projectId] == address(0)) {
                derivativeNFT = _deployDerivativeNFT(
                    derivativeImpl,
                    ndpt,
                    treasury,
                    project.hubId,
                    projectId,
                    project.soulBoundTokenId,
                    project.name, 
                    project.description,
                    metadataDescriptor
                );
                _derivativeNFTByProjectId[projectId] = derivativeNFT;
        }

        return derivativeNFT;
        
    }

    function _deployDerivativeNFT(
        address derivativeImpl,
        address ndpt,
        address treasury,        
        uint256 hubId,
        uint256 projectId,
        uint256  soulBoundTokenId,
        string memory name_,
        string memory symbol_,
        address metadataDescriptor_
    ) private returns (address) {
        address derivativeNFT = Clones.clone(derivativeImpl);
        IDerivativeNFTV1(derivativeNFT).initialize(
            ndpt,
            treasury,    
            name_,
            symbol_,
            hubId,
            projectId,
            soulBoundTokenId,
            metadataDescriptor_
        );

        emit Events.DerivativeNFTDeployed(hubId, projectId, soulBoundTokenId, derivativeNFT, block.timestamp);
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
        currency_;
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
        external
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
        external
        view
        returns (uint256)
    {
        return _derivativeNFTSale[derivativeNFT_].at(index_);
    }

}
