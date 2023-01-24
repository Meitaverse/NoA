// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @author batu-inal & HardlyDifficult
 */
interface INFTCollectionInitializer {
  function initialize(
    address payable _creator,
    string memory _name,
    string memory _symbol
  ) external;
}
