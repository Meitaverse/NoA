import { Contract } from "ethers";
import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import { readFile, writeFile } from "fs/promises";
import { HardhatRuntimeEnvironment } from "hardhat/types";

export const DEFAULT_NETWORKS_JSON_PATH = "./subgraph/networks.json";
export const DEFAULT_DERIVARIVE_NETWORKS_JSON_PATH = "./subgraphDerivativeNFT/networks.json";


function getDefaultNetworksJsonPath(
  hre: HardhatRuntimeEnvironment,
  configPath?: string
) {
  if (!configPath) {
    configPath = DEFAULT_NETWORKS_JSON_PATH;
  }
  return configPath;
}

function getDerivariveNetworksJsonPath(
  hre: HardhatRuntimeEnvironment,
  configPath?: string
) {
  if (!configPath) {
    configPath = DEFAULT_DERIVARIVE_NETWORKS_JSON_PATH;
  }
  return configPath;
}

export async function exportSubgraphNetworksJson(
  hre: HardhatRuntimeEnvironment,
  contract: Contract,
  name: string,
  networkName: string = "mainnet",
  startBlock: number = 1,
  configPath?: string,
) {
  configPath = getDefaultNetworksJsonPath(hre, configPath);
  const { chainId } = await hre.ethers.provider.getNetwork();
  let previousConfig = {};
  try {
    previousConfig = JSON.parse(await readFile(configPath, "utf-8"));
  } catch (e: any) {
    if (e.code !== "ENOENT") {
      throw e;
    }
  }

  const config = {
    ...previousConfig,
    [networkName]: {
      ...previousConfig[networkName],
      [name]:
      {
        ["address"]: contract.address,
        ["startBlock"]: startBlock,
      }
    },
  };

  await writeFile(configPath, JSON.stringify(config, null, 2));
}

export async function exportDerivativeSubgraphNetworksJson(
  hre: HardhatRuntimeEnvironment,
  contract: Contract,
  name: string,
  networkName: string = "mainnet",
  startBlock: number = 1,
  configPath?: string,
) {
  configPath = getDerivariveNetworksJsonPath(hre, configPath);
  const { chainId } = await hre.ethers.provider.getNetwork();
  let previousConfig = {};
  try {
    previousConfig = JSON.parse(await readFile(configPath, "utf-8"));
  } catch (e: any) {
    if (e.code !== "ENOENT") {
      throw e;
    }
  }

  const config = {
    ...previousConfig,
    [networkName]: {
      ...previousConfig[networkName],
      [name]:
      {
        ["address"]: contract.address,
        ["startBlock"]: startBlock,
      }
    },
  };

  await writeFile(configPath, JSON.stringify(config, null, 2));
}
