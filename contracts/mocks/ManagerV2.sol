// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../base/NFTDerivativeProtocolMultiState.sol";
import "../Manager.sol";
import {VersionedInitializable} from '../upgradeability/VersionedInitializable.sol';

contract ManagerV2 is 
    NFTDerivativeProtocolMultiState, 
    VersionedInitializable,
    Manager
{

    uint256 internal _additionalValue;

    function reInitialize( 
        address dNftV1_, 
        address receiver_
    ) external initializer {

    }

    //-- external --//

    function setAdditionalValue(uint256 newValue) external {
        _additionalValue = newValue;
    }

    function getAdditionalValue() external view returns (uint256) {
        return _additionalValue;
    }

    function version() public pure override returns(uint256) {
        return 2;
    }

    function getRevision() internal pure virtual override(Manager, VersionedInitializable) returns (uint256) {
        return 2;
    }
}
