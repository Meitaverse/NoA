
const TransparentUpgradeableProxy = require('@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json');
const ProxyAdmin = require('@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol/ProxyAdmin.json');
const {getInitializerData} = require("@openzeppelin/hardhat-upgrades/dist/utils");

const { shouldBehaveLikeERC3525, shouldBehaveIsPoAP, shouldBehaveCanCombo } = require('./NoA.behavior');

async function fetchOrDeployAdminProxy(proxyAdminAddress) {
  const address = proxyAdminAddress ? ethers.utils.getAddressFromAccount(ethers.utils.parseAccount(proxyAdminAddress)) : null;
  
  const proxyAdminFactory = await ethers.getContractFactory(ProxyAdmin.abi, ProxyAdmin.bytecode);
  const proxyAdmin = proxyAdminAddress ? (await proxyAdminFactory.attach(address)) : (await proxyAdminFactory.deploy());
  await proxyAdmin.deployed();

  // console.log("ProxyAdmin deployed to:", proxyAdmin.address);

  return proxyAdmin
}


async function deployProxy(proxyAdmin, ImplFactory, args, opts) {
  if (!Array.isArray(args)) {
      opts = args;
      args = [];
  }
  const impl = await ImplFactory.deploy()
  await impl.deployed();

  const ProxyFactory = await ethers.getContractFactory(TransparentUpgradeableProxy.abi, TransparentUpgradeableProxy.bytecode);
  const data = getInitializerData(impl.interface, args, opts.initializer);
  const proxy = await ProxyFactory.deploy(impl.address, proxyAdmin.address, data)
  await proxy.deployed();
  return await ImplFactory.attach(proxy.address)
}

async function deployNoA(name, symbol, decimals) {
  
    // Deploy the dao metadata descriptor contract
    const MetadataDescriptor = await ethers.getContractFactory('MetadataDescriptor');
    const descriptor = await MetadataDescriptor.deploy();
    await descriptor.deployed();
    // console.log('MetadataDescriptor deployed to:', descriptor.address);
    // console.log("");

    const NoA = await ethers.getContractFactory("NoAV1");

    const proxyAdmin = await fetchOrDeployAdminProxy();
    const noa = await deployProxy(proxyAdmin, NoA, [name, symbol, decimals, descriptor.address], { initializer: 'initialize' });
    await noa.deployed();
    return noa;
}

describe('NoA', () => {

  const name = 'Network Of Attendance';
  const symbol = 'NoA';
  const decimals = 0;

  beforeEach(async function () {
    this.token = await deployNoA(name, symbol, decimals);
    //console.log('NoA deployed to:',  this.token .address);
  })

  shouldBehaveLikeERC3525('NoA');
  shouldBehaveIsPoAP('NoA');
  shouldBehaveCanCombo('NoA');
  

  // shouldBehaveLikeERC3525Metadata('ERC3525Metadata');

})