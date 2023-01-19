// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title ITemplate
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the Template contract
 */
interface ITemplate {
  /**
   * @notice get the template via svg
   */
  function template() external view returns(bytes memory);
  
}