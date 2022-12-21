// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title ITemplate
 * @author Bitsoul Protocol
 *
 * @notice This is the interface for the Template contract
 */
interface ITemplate {
  
  // function setCanvas(uint256 width, uint256 height) external;
  // function getCanvas() external returns(uint256, uint256);

  // function setWatermarkCanvas(uint256 width, uint256 height) external;
  // function getWatermarkCanvas() external returns(uint256, uint256);

  // function setWatermarkPosition(uint256 x, uint256 y) external;
  // function getWatermarkPosition() external returns(uint256, uint256);
  
  function template() external view returns(bytes memory);
  
}