// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ITokenCreator {
  /**
   * @notice Returns the creator of this dNFT collection.
   * @param tokenId The ID of the dNFT to get the creator payment address for.
   * @return creator The creator of this collection.
   */
  function tokenCreator(uint256 tokenId) external view returns (address payable creator);
}
