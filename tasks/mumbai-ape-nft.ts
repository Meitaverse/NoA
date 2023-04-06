
import '@nomiclabs/hardhat-ethers';
import { hexlify, keccak256, parseEther, RLP } from 'ethers/lib/utils';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { task } from 'hardhat/config';
import { exportAddress } from "./config";
import { exportSubgraphNetworksJson } from "./subgraph";

import {
    MIN_DELAY,
    QUORUM_PERCENTAGE,
    VOTING_PERIOD,
    VOTING_DELAY,
  } from "../helper-hardhat-config"

import {
    NFT, NFT__factory,
} from '../typechain';

import { deployContract, deployWithVerify, waitForTx, ProtocolState, Error, ZERO_ADDRESS} from './helpers/utils';

import { DataTypes } from '../typechain/contracts/modules/template/Template';
import { BigNumber } from 'ethers';
  

  export let runtimeHRE: HardhatRuntimeEnvironment;
  
  // yarn hardhat --network mumbai mumbai-ape-nft

  task('mumbai-ape-nft', 'get the APE NFT from MUMBAI testnet').setAction(async ({}, hre) => {
        // Note that the use of these signers is a placeholder and is not meant to be used in
        // production.
        runtimeHRE = hre;
        const ethers = hre.ethers;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];
        

        // let baseURI = "http://bitsoul.net/nft/";
        let apeContract = "0x960356840F632BD1De65aD5d93d61bA902d005c5";
        let  apeNFT = NFT__factory.connect(apeContract, deployer);
        

        // let tokenId=5;
        // let uri = baseURI + tokenId + ".png";
        // await waitForTx(await apeNFT.mint(user5, tokenId));
        // await waitForTx(await apeNFT.connect(deployer).setTokenURI(tokenId, uri));

        let name = await apeNFT.name();
        console.log(`\t-- NFT name is `,  name);
        let symbol = await apeNFT.symbol();
        console.log(`\t-- NFT symbol is `,  symbol);

        let tokenId=5;
        let tokenURI = await apeNFT.tokenURI(tokenId);
        const tokenURIData = JSON.parse(Buffer.from(tokenURI.split(",")[1], "base64").toString());
        console.log('\n\t-- NFT tokenURIData is: ', tokenURIData);
        console.log('\n\t-- NFT tokenURIData.name is: ', tokenURIData.name);
        console.log('\t-- NFT tokenURIData.description is: ', tokenURIData.description);
        console.log('\t-- NFT tokenURIData.image is: ', tokenURIData.image);

        
        let owner = await apeNFT.ownerOf(tokenId);
        console.log(`\t-- TokenID: `,tokenId,` , NFT owner is `,  owner);
        
   });