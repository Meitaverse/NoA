// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {DataTypes} from '../libraries/DataTypes.sol';
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";

/**
 * @title IGovernorContract
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the GovernorContract contract, from which the GovernorContract inherit.
 */
interface IGovernorContract {

     function initialize(
        IVotesUpgradeable _token,
        TimelockControllerUpgradeable _timelock,
        uint256 _quorumPercentage,
        uint256 _votingPeriod,
        uint256 _votingDelay
    ) external ;

}