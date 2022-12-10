// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IManager} from '../interfaces/IManager.sol';
import {Proxy} from '@openzeppelin/contracts/proxy/Proxy.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

contract DerivativeNFTProxy is Proxy {
    using Address for address;
    
    // solhint-disable-next-line var-name-mixedcase
    address immutable _MANAGER;

    constructor(bytes memory data) {
        _MANAGER = msg.sender;
        IManager(msg.sender).getDNFTImpl().functionDelegateCall(data);
    }

    function _implementation() internal view override returns (address) {
        return IManager(_MANAGER).getDNFTImpl();
    }
}
