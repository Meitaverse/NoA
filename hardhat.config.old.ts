// import { HardhatUserConfig } from 'hardhat/types';
import { HardhatUserConfig, task } from "hardhat/config";
import "@openzeppelin/hardhat-upgrades";
import { accounts } from './helpers/test-wallets';
import { eEthereumNetwork, eNetwork, ePolygonNetwork, eXDaiNetwork } from './helpers/types';
import { HARDHATEVM_CHAINID } from './helpers/hardhat-constants';
import { NETWORKS_RPC_URL } from './helper-hardhat-config';
import dotenv from 'dotenv';
import glob from 'glob';
import path from 'path';
import "@nomicfoundation/hardhat-toolbox";


dotenv.config({ path: '.env' });

import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@typechain/hardhat';
import 'solidity-coverage';
import 'hardhat-gas-reporter';
import 'hardhat-contract-sizer';
import 'hardhat-log-remover';
import 'hardhat-spdx-license-identifier';
import "@nomiclabs/hardhat-truffle5";


if (!process.env.SKIP_LOAD) {
  glob.sync('./tasks/**/*.ts').forEach(function (file) {
    require(path.resolve(file));
  });
}

const DEFAULT_BLOCK_GAS_LIMIT = 12450000;
const MNEMONIC_PATH = "m/44'/60'/0'/0";
const MNEMONIC = process.env.MNEMONIC || '';
const MAINNET_FORK = process.env.MAINNET_FORK === 'true';
const GASREPORT_FILE = process.env.GASREPORT_FILE || "";
const NO_COLORS = process.env.NO_COLORS == "false" || GASREPORT_FILE != "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const COINMARKETCAP_KEY = process.env.COINMARKETCAP_KEY || "";
const CRONOSCAN_API_KEY = process.env.CRONOSCAN_API_KEY;
const TOKEN = process.env.TOKEN || "MATIC";
const GASPRICE_API = {
  MATIC: "https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice",
  ETH: "https://api.etherscan.io/api?module=proxy&action=eth_gasPrice",
  CRO: `https://api.cronoscan.com/api?module=proxy&action=eth_gasPrice&apiKey=${CRONOSCAN_API_KEY}`,
}[TOKEN];

const getCommonNetworkConfig = (networkName: eNetwork, networkId: number) => ({
  url: NETWORKS_RPC_URL[networkName] ?? '',
  accounts: {
    mnemonic: MNEMONIC,
    path: MNEMONIC_PATH,
    initialIndex: 0,
    count: 20,
  },
});

const mainnetFork = MAINNET_FORK
  ? {
      blockNumber: 12012081,
      url: NETWORKS_RPC_URL['main'],
    }
  : undefined;

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.17',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
            details: {
              yul: true,
            },
          },
        },
      },
    ],
  },
  defaultNetwork: "local",
  networks: {
    kovan: getCommonNetworkConfig(eEthereumNetwork.kovan, 42),
    ropsten: getCommonNetworkConfig(eEthereumNetwork.ropsten, 3),
    main: getCommonNetworkConfig(eEthereumNetwork.main, 1),
    tenderlyMain: getCommonNetworkConfig(eEthereumNetwork.tenderlyMain, 3030),
    matic: getCommonNetworkConfig(ePolygonNetwork.matic, 137),
    mumbai: getCommonNetworkConfig(ePolygonNetwork.mumbai, 80001),
    xdai: getCommonNetworkConfig(eXDaiNetwork.xdai, 100),
    hardhat: {
      hardfork: 'london',
      blockGasLimit: DEFAULT_BLOCK_GAS_LIMIT,
      gas: DEFAULT_BLOCK_GAS_LIMIT,
      gasPrice: 8000000000,
      chainId: HARDHATEVM_CHAINID,
      throwOnTransactionFailures: true,
      throwOnCallFailures: true,
      accounts: accounts.map(({ secretKey, balance }: { secretKey: string; balance: string }) => ({
        privateKey: secretKey,
        balance,
      })),
      forking: mainnetFork,
    },
    
    local: {
      url: 'http://127.0.0.1:8545/',
      accounts: {
        mnemonic: MNEMONIC,
        path: MNEMONIC_PATH,
        initialIndex: 0,
        count: 20,
      },
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
    only: [
      ':ModuleGlobals$', 
      ':FETH$', 
      ':Voucher$', 
      ':VoucherMarket$', 
      ':MarketPlace$', 
      ':Manager$',
      ':BankTreasury$',
      ':RoyaltyRegistry$',
      ':DerivativeNFT$', 
      ':NFTDerivativeProtocolTokenV1$', 
      'GovernorContract$'],
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS ? true : false, 
    currency: 'USD', //USD
    showTimeSpent: false,
    showMethodSig: true,
    coinmarketcap: COINMARKETCAP_KEY,
    outputFile: GASREPORT_FILE,
    noColors: NO_COLORS,
    token: TOKEN,
    excludeContracts: [
      "MockERC1155CreatorExtensionBurnable",
      "Currency",
      "MockERC1155CreatorExtensionOverride",
      "MockERC1155CreatorMintPermissions",
      "VotingMock",
    ],
    gasPriceApi: GASPRICE_API,
  },
  spdxLicenseIdentifier: {
    overwrite: false,
    runOnCompile: false,
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  mocha: {
    timeout: 100000000
  },

};

export default config;
