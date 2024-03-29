// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title Interface for the main ENS contract
 */
interface IENS {
  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external returns (bytes32);

  function setResolver(bytes32 node, address resolver) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);
}
