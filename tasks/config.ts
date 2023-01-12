import { Contract } from "ethers";
import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import { readFile, writeFile } from "fs/promises";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
  ERC1967Proxy__factory,
    Currency,
    Currency__factory,
    Events,
    Events__factory,
    PublishModule,
    PublishModule__factory,
    FeeCollectModule,
    FeeCollectModule__factory,
    Helper,
    Helper__factory,
    InteractionLogic__factory,
    PublishLogic__factory,
    ModuleGlobals,
    ModuleGlobals__factory,
    TransparentUpgradeableProxy__factory,
    ERC3525ReceiverMock,
    ERC3525ReceiverMock__factory,
    GovernorContract,
    GovernorContract__factory,
    BankTreasury,
    BankTreasury__factory,
    MarketPlace,
    DerivativeNFTV1,
    DerivativeNFTV1__factory,
    NFTDerivativeProtocolTokenV1,
    NFTDerivativeProtocolTokenV2,
    NFTDerivativeProtocolTokenV1__factory,
    NFTDerivativeProtocolTokenV2__factory,
    Manager,
    Manager__factory,
    Voucher,
    Voucher__factory,
    DerivativeMetadataDescriptor,
    DerivativeMetadataDescriptor__factory,
    Template,
    Template__factory,
    MarketPlace__factory,
    TimeLock__factory,

} from "../typechain";
import { TimeLock, metadataDescriptors } from "../typechain/contracts";

export const DEFAULT_CONFIG_PATH = "./deployments/networks.json";
export const DEFAULT_LOCALHOST_CONFIG_PATH =
  "./deployments/networks.localhost.json";

export type ContractName =
  | "ManagerImpl"
  | "Manager"
  | "SBT"
  | "TimeLock"
  | "GovernorContract"
  | "BankTreasury"
  | "MarketPlace"
  | "Voucher"
  | "FeeCollectModule"
  | "PublishModule"
  | "Template"
  | "MetadataDescriptor"
  | "Receiver"
  | "ModuleGlobals";

export type DAOContract =
  | Manager
  | NFTDerivativeProtocolTokenV1
  | BankTreasury
  | TimeLock
  | GovernorContract
  | MarketPlace
  | Voucher
  | Template
  | DerivativeMetadataDescriptor
  | ERC3525ReceiverMock
  | ModuleGlobals;

export type NetworkConfig = {
  [key: number]: {
    [key in ContractName]?: string;
  };
};

export const ROLES = {
  DEFAULT_ADMIN_ROLE:
    "0x0000000000000000000000000000000000000000000000000000000000000000",
  OPERATOR_ROLE: keccak256(toUtf8Bytes("OPERATOR_ROLE")),
  RESOLUTION_ROLE: keccak256(toUtf8Bytes("RESOLUTION_ROLE")),
  ESCROW_ROLE: keccak256(toUtf8Bytes("ESCROW_ROLE")),
  SHAREHOLDER_REGISTRY_ROLE: keccak256(
    toUtf8Bytes("SHAREHOLDER_REGISTRY_ROLE")
  ),
} as const;

function getDefaultConfigPath(
  hre: HardhatRuntimeEnvironment,
  configPath?: string
) {
  if (!configPath) {
    configPath =
      hre.network.name === "local"
        ? DEFAULT_LOCALHOST_CONFIG_PATH
        : DEFAULT_CONFIG_PATH;
  }
  return configPath;
}

export async function exportAddress(
  hre: HardhatRuntimeEnvironment,
  contract: Contract,
  name: ContractName,
  configPath?: string
) {
  configPath = getDefaultConfigPath(hre, configPath);
  const { chainId } = await hre.ethers.provider.getNetwork();
  let previousConfig: NetworkConfig = {};
  try {
    previousConfig = JSON.parse(await readFile(configPath, "utf-8"));
  } catch (e: any) {
    if (e.code !== "ENOENT") {
      throw e;
    }
  }

  const config = {
    ...previousConfig,
    [chainId]: {
      ...previousConfig[chainId],
      [name]: contract.address,
    },
  };

  await writeFile(configPath, JSON.stringify(config, null, 2));
}

type ContractFactory =
  | typeof Manager__factory
  | typeof NFTDerivativeProtocolTokenV1__factory
  | typeof BankTreasury__factory
  | typeof GovernorContract__factory
  | typeof TimeLock__factory
  | typeof MarketPlace__factory
  | typeof Voucher__factory
  | typeof FeeCollectModule__factory
  | typeof PublishModule__factory
  | typeof Template__factory
  | typeof DerivativeMetadataDescriptor__factory
  | typeof ERC3525ReceiverMock__factory
  | typeof ModuleGlobals__factory;

export async function loadContract<T extends ContractFactory>(
  hre: HardhatRuntimeEnvironment,
  contractFactory: T,
  name: ContractName,
  configPath?: string
) {
  configPath = getDefaultConfigPath(hre, configPath);
  const networks: NetworkConfig = JSON.parse(
    await readFile(configPath, "utf8")
  );
  const [deployer] = await hre.ethers.getSigners();
  const { chainId, name: networkName } = await hre.ethers.provider.getNetwork();
  const addresses = networks[chainId];

  if (!addresses || !addresses[name]) {
    console.error(`Cannot find address for ${name} in network ${networkName}.`);
    process.exit(1);
  }

  // FIXME: I thought `address[name]` type would be `string` because of the previous `if`.
  const address = addresses[name]!;

  return contractFactory.connect(address, deployer) as ReturnType<T["connect"]>;
}

export async function loadContractByName(
  hre: HardhatRuntimeEnvironment,
  name: ContractName,
  configPath?: string
): Promise<DAOContract> {
  configPath = getDefaultConfigPath(hre, configPath);
  const networks: NetworkConfig = JSON.parse(
    await readFile(configPath, "utf8")
  );
  const [deployer] = await hre.ethers.getSigners();
  const { chainId } = await hre.ethers.provider.getNetwork();
  const addresses = networks[chainId];

  if (!addresses || !addresses[name]) {
    console.error(`Cannot find address for ${name}.`);
    process.exit(1);
  }

  // FIXME: I thought `address[name]` type would be `string` because of the previous `if`.
  const address = addresses[name]!;

  switch (name) {
    case "Manager":
      return Manager__factory.connect(address, deployer);
    case "SBT":
      return NFTDerivativeProtocolTokenV1__factory.connect(address, deployer);
    case "TimeLock":
      return TimeLock__factory.connect(address, deployer);
    case "GovernorContract":
      return GovernorContract__factory.connect(address, deployer);
    case "BankTreasury":
      return BankTreasury__factory.connect(address, deployer);
    case "MarketPlace":
      return MarketPlace__factory.connect(address, deployer);
    case "Voucher":
      return Voucher__factory.connect(address, deployer);
    case "Template":
      return Template__factory.connect(address, deployer);
    case "MetadataDescriptor":
      return DerivativeMetadataDescriptor__factory.connect(address, deployer);
    case "Receiver":
      return ERC3525ReceiverMock__factory.connect(address, deployer);
    case "ModuleGlobals":
      return ModuleGlobals__factory.connect(address, deployer);
    default:
      console.error(`Cannot find contract with name ${name}.`);
      process.exit(1);
  }
}
