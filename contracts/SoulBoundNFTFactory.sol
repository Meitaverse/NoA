//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./SoulBoundTokenV1.sol";
import "./SoulBoundNFTProxyRegistry.sol";

// TODO: make pausable
contract SoulBoundNFTFactory is Ownable {
  //===== State =====//

  SoulBoundNFTProxyRegistry public proxyRegistry;

  //===== Events =====//

  event UpgradeableBeaconCreated(address indexed createdBy, address beacon, address initialImplementation);
  event BeaconProxyCreated(address indexed beacon, address beaconProxy);

  constructor(address _proxyRegistry) {
    proxyRegistry = SoulBoundNFTProxyRegistry(_proxyRegistry);
  }

  function _payload(
    string memory name,
    string memory symbol,
    address metadataDescriptor,
    string memory organization,
    address tokenOwner,
    address minterOfToken,
    address signerAddress
  ) internal pure returns (bytes memory) {
    return
      abi.encodeWithSignature(
        "initialize(string,string,address,string,address,address,address)",
        name,
        symbol,
        metadataDescriptor,
        organization,
        tokenOwner,
        minterOfToken,
        signerAddress
      );
  }

  /// newUpgradeableBeacon creates a new beacon with an initial implementation set
  /// @param initialImplementation sets the first iteration of logic for proxies
  function newUpgradeableBeacon(address initialImplementation) public onlyOwner returns (UpgradeableBeacon beacon) {
    beacon = new UpgradeableBeacon(initialImplementation);
    beacon.transferOwnership(msg.sender);

    emit UpgradeableBeaconCreated(msg.sender, address(beacon), initialImplementation);

    // beaconAddress = address(beacon);
    proxyRegistry.setBeaconAddress(address(beacon));
  }

  /// newBeaconProxy creates and initializes a new proxy for the given UpgradeableBeacon
  function newBeaconProxy(
    string memory name,
    string memory symbol,
    address metadataDescriptor,
    string memory organization,
    address tokenOwner,
    address minterOfToken,
    address signerAddress
  ) public returns (BeaconProxy beaconProxy) {
    address beaconAddress = proxyRegistry.beaconAddress();
    bytes memory data = _payload(name, symbol, metadataDescriptor, organization, tokenOwner, minterOfToken, signerAddress);
    beaconProxy = new BeaconProxy(beaconAddress, data);
    proxyRegistry.registerBeaconProxy(address(beaconProxy), name, symbol, organization, tokenOwner);
    emit BeaconProxyCreated(beaconAddress, address(beaconProxy));
  }
}
