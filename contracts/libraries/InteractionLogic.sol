// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {Constants} from './Constants.sol';
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

    
    function createHub(
        address creator,
        uint256 hubId,
        DataTypes.HubData memory hub,
        mapping(uint256 => DataTypes.HubData) storage _hubInfos
    ) external {
        
        if (hubId == 0) revert Errors.HubIdIsZero();
        
         _hubInfos[hubId] = DataTypes.HubData({
             soulBoundTokenId : hub.soulBoundTokenId,
             name: hub.name,
             description: hub.description,
             imageURI: hub.imageURI
        });

        emit Events.HubCreated(
            hub.soulBoundTokenId, 
            creator, 
            hubId,
            hub.name,
            hub.description,
            hub.imageURI,
            uint32(block.timestamp)
        );

    }

    function createProject(
        address derivativeImpl,
        address sbt,
        address treasury,
        uint256 projectId,
        DataTypes.ProjectData memory project,
        address receiver,
        mapping(uint256 => address) storage _derivativeNFTByProjectId
    ) external returns(address) {
        address derivativeNFT;
        if(_derivativeNFTByProjectId[projectId] == address(0)) {
                derivativeNFT = _deployDerivativeNFT(
                    derivativeImpl,
                    sbt,
                    treasury,
                    projectId,
                    project.soulBoundTokenId,
                    project.name, 
                    project.description,
                    project.descriptor,
                    project.defaultRoyaltyPoints,
                    project.feeShareType,
                    receiver
                );
                _derivativeNFTByProjectId[projectId] = derivativeNFT;
        }
        return derivativeNFT;
    }
    
    function _deployDerivativeNFT(
        address derivativeImpl,
        address sbt,
        address treasury,        
        uint256 projectId,
        uint256 soulBoundTokenId,
        string memory name_,
        string memory symbol_,
        address descriptor_,
        uint96 defaultRoyaltyPoints_,
       DataTypes.FeeShareType feeShareType_,
        address receiver_
    ) private returns (address) {

        address derivativeNFT = Clones.clone(derivativeImpl);
        IDerivativeNFTV1(derivativeNFT).initialize(
            sbt,
            treasury,    
            name_,
            symbol_,
            projectId,
            soulBoundTokenId,
            descriptor_,
            receiver_,
            defaultRoyaltyPoints_,
            feeShareType_
        );

        emit Events.DerivativeNFTDeployed(
            projectId, 
            soulBoundTokenId, 
            derivativeNFT, 
            block.timestamp
        );
        
        return derivativeNFT;
    } 
    
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeMathUpgradeable128 for uint128;

    uint16 internal constant PERCENTAGE_BASE = 10000;



    // function _getFee(
    //     address derivativeNFT_, 
    //     address currency_, 
    //     uint256 amount,
    //     mapping(address => DataTypes.Market) storage markets
    // )
    //     internal
    //     view
    //     returns (uint128)
    // {
    //     currency_;
    //     DataTypes.Market storage market = markets[derivativeNFT_];
    //     if (market.feeType == DataTypes.FeeType.FIXED) {
    //         return market.feeAmount;
    //     } else if (market.feeType == DataTypes.FeeType.BY_AMOUNT) {
    //         uint256 fee = amount.mul(uint256(market.feeRate)).div(
    //             uint256(PERCENTAGE_BASE)
    //         );
    //         require(fee <= type(uint128).max, "Fee: exceeds uint128 max");
    //         return uint128(fee);
    //     } else {
    //         revert("unsupported feeType");
    //     }
    // }



}
