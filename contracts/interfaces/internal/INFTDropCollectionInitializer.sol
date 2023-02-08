// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @author bitsoul Protocol
 */
interface INFTDropCollectionInitializer {
  function initialize(
    address payable _creator,
    string calldata _name,
    string calldata _symbol,
    string calldata _baseURI,
    bool isRevealed,
    uint32 _maxTokenId,
    address _approvedMinter,
    address payable _paymentAddress
  ) external;
}
