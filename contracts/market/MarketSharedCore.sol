// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title A place for common modifiers and functions used by various market mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 * @author batu-inal & HardlyDifficult
 */
abstract contract MarketSharedCore {
  /**
   * @notice Checks who the seller for an DNFT is if listed in this market.
   * @param dnftContract The address of the DNFT contract.
   * @param tokenId The id of the DNFT.
   * @return seller The seller which listed this DNFT for sale, or address(0) if not listed.
   */
  // function getSellerOf(address dnftContract, uint256 tokenId) external view returns (address payable seller) {
  //   seller = _getSellerOf(dnftContract, tokenId);
  // }

  // /**
  //  * @notice Checks who the seller for an DNFT is if listed in this market.
  //  */
  // function _getSellerOf(address dnftContract, uint256 tokenId) internal view virtual returns (address payable seller);

  // /**
  //  * @notice Checks who the seller for an DNFT is if listed in this market or returns the current owner.
  //  */
  
  // function _getSellerOrOwnerOf(address dnftContract, uint256 tokenId)
  //   internal
  //   view
  //   virtual
  //   returns (address payable sellerOrOwner);
  

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  // uint256[500] private __gap;
}
