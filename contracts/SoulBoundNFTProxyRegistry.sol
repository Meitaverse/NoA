//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SoulBoundNFTProxyRegistry is Ownable {
  using Counters for Counters.Counter;

  //===== State =====//

  Counters.Counter public proxyCount;

  struct ContractInfo {
    string name;
    string symbol;
    string organization;
    address owner;
  }

  address public beaconAddress;
  address[] public proxies;

  mapping(address => address[]) internal _ownerToProxyAddress;
  mapping(address => ContractInfo) internal _proxyAddressToContractInfo;

  address public proxyFactory;

  //管理合约: proxy合约注册
  constructor() {}

  /// newBeaconProxy creates and initializes a new proxy for the given UpgradeableBeacon
  function registerBeaconProxy(
    address proxyAddress,
    string memory name,
    string memory symbol,
    string memory organization,
    address tokenOwner
  ) public onlyProxyFactory {
    _ownerToProxyAddress[tokenOwner].push(proxyAddress);

    _proxyAddressToContractInfo[proxyAddress] = ContractInfo({ name: name, symbol: symbol, organization: organization, owner: tokenOwner });

    proxies.push(proxyAddress);

    proxyCount.increment();
  }

  function getProxiesByOwnerAddress(address _owner) public view returns (address[] memory) {
    return _ownerToProxyAddress[_owner];
  }

  function getContractInfoByProxyAddress(address _proxy) public view returns (ContractInfo memory) {
    return _proxyAddressToContractInfo[_proxy];
  }

  //设置信标地址
  function setBeaconAddress(address _beaconAddress) public onlyProxyFactory {
    beaconAddress = _beaconAddress;
  }

  //设置工厂合约地址
  function setProxyFactory(address _factory) public onlyOwner {
    proxyFactory = _factory;
  }

  //只有工厂合约才能调用
  modifier onlyProxyFactory() {
    require(msg.sender == proxyFactory, "Not allowed");
    _;
  }
}
