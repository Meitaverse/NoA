// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title Interface for the main ENS FIFSRegistrar contract.
 * @notice Used in testnet only.
 */
interface IFIFSRegistrar {
  function register(bytes32 label, address owner) external;
}
