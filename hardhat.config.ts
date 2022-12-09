
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-truffle5";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";

import { HardhatUserConfig } from "hardhat/types";

import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task("balance", "Prints an account's balance")
  .addParam("account", "The account's address")
  .setAction(async (taskArgs, hre) => {
    const balance = await hre.ethers.provider.getBalance(taskArgs.account);

    console.log(hre.ethers.utils.formatEther(balance), "ETH");
  });

import("./tasks").catch((e) => console.log("Cannot load tasks", e.toString()));

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.15",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: false,
    },
  },
  defaultNetwork: "localhost",
  networks: {
    localhost:{
      url:"http://127.0.0.1:8545"
    },    
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    coverage: {
      url: "http://127.0.0.1:8555", // Coverage launches its own ganache-cli client
    },
  },
  typechain: {
    outDir: "./typechain",
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    only: [':NoAV1$',':Manager$',':Incubator$',':SoulBoundTokenV1$',':DerivativeNFTV1$', ':NFTDerivativeProtocolTokenV1$'],
  },
  gasReporter: {
    enabled: true,
    currency: 'USD', //USD
    showTimeSpent: true,
    showMethodSig: true,
    coinmarketcap: 'b7d62a59-7758-4be6-8438-1a5f7a705989',
    gasPriceApi:
      'https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice',
  },
};

export default config;