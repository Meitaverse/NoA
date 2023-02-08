// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @notice The required interface for collections to support the NFTDropMarket.
 * @dev This interface must be registered as a ERC165 supported interface to support the NFTDropMarket.
 * @author bitsoul
 */
interface INFTDropCollectionMint {
  function mintCountTo(uint16 count, address to) external returns (uint256 firstTokenId);

  function numberOfTokensAvailableToMint() external view returns (uint256 count);
}
