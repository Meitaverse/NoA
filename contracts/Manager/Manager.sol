// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../interface/INoAV1.sol";
import "../interface/ISoulBoundTokenV1.sol";


contract Manager is 
    Initializable, 
    Context, 
    AccessControl
{
    INoAV1 internal _noAV1;
    ISoulBoundTokenV1 internal _soulBoundTokenV1;
    // IVoting internal _voting;


    function initialize(
        INoAV1 noAV1_,
        ISoulBoundTokenV1 soulBoundTokenV1_
        // IVoting voting
    ) public initializer {
        _noAV1 = noAV1_;
        _soulBoundTokenV1 = soulBoundTokenV1_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}


}