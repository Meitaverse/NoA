const { ethers, upgrades } = require('hardhat');


const TransparentUpgradeableProxy = require('@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json');
const ProxyAdmin = require('@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol/ProxyAdmin.json');
const {getInitializerData} = require("@openzeppelin/hardhat-upgrades/dist/utils");

const { 
  shouldBehaveLikeERC3525, 
  shouldBehaveLikeERC3525Metadata, 
  shouldBehaveLikeERC3525SlotEnumerable
 } = require('./NoA.behavior');
const Error = [ 'None', 'RevertWithMessage', 'RevertWithoutMessage', 'Panic' ]
  .reduce((acc, entry, idx) => Object.assign({ [entry]: idx }, acc), {});


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

async function deployNoA(name, symbol) {
  
    // Deploy the dao metadata descriptor contract
    const DerivativeMetadataDescriptor = await ethers.getContractFactory('DerivativeMetadataDescriptor');
    const descriptor = await DerivativeMetadataDescriptor.deploy();
    await descriptor.deployed();
    console.log('DerivativeMetadataDescriptor deployed to:', descriptor.address);
    console.log("");

    //接收者
    const ERC3525ReceiverMockFactory = await ethers.getContractFactory('ERC3525ReceiverMock');
    const RECEIVER_MAGIC_VALUE = '0x009ce20b';

    const receiver = await ERC3525ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.None);
    await receiver.deployed();
    const NoA = await ethers.getContractFactory("NoAV1");

    // const UTokenV1 = await ethers.getContractFactory('UTokenV1');
    // const uToken = await upgrades.deployProxy(UTokenV1, [], {
    //   initializer: 'initialize',
    // });
    // await uToken.deployed();
    // console.log('uToken deployed to:', uToken.address);
    // console.log("");

    const proxyAdmin = await fetchOrDeployAdminProxy();
    const noa = await deployProxy(proxyAdmin, NoA, [name, symbol, descriptor.address, receiver.address], { initializer: 'initialize' });
    await noa.deployed();
    return noa;
}

describe('NoA', () => {

  const name = 'Network Of Attendance';
  const symbol = 'NoA';

  beforeEach(async function () {
    this.token = await deployNoA(name, symbol);
    console.log('NoA deployed to:',  this.token.address);
  })

  shouldBehaveLikeERC3525('NoA');
  // shouldBehaveLikeERC3525Metadata('NoAMetadata');
  // shouldBehaveLikeERC3525SlotEnumerable('NoASlotEnumerable');
  

})