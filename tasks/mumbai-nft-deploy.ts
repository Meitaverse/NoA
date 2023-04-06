
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
  
  // yarn mumbai-nft-deploy

  task('mumbai-nft-deploy', 'deploys the APE NFT to MUMBAI testnet').setAction(async ({}, hre) => {
        // Note that the use of these signers is a placeholder and is not meant to be used in
        // production.
        runtimeHRE = hre;
        const ethers = hre.ethers;
        const accounts = await ethers.getSigners();
        const deployer = accounts[0];

        let user="0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC";
        let user2="0x90F79bf6EB2c4f870365E785982E1f101E93b906";
        let user3= "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65";
        let user4="0x976EA74026E726554dB657fA54763abd0C3a0aa9";
        let user5="0x14dC79964da2C08b23698B3D3cc7Ca32193d9955";
        let user6="0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f";
        let user7="0xa0Ee7A142d267C1f36714E4a8F75612F20a79720";

      
        let baseURI = "http://bitsoul.net/nft/";
      
        console.log('\n\t-- Deploying NFT to MJMBAI--');
        const apeNFT = await deployContract(
            new NFT__factory(deployer).deploy()
        );

        console.log(`\t-- NFT deployed to ${apeNFT.address} --`);
        
        console.log('\n\t-- Starting to mint some NFTs --');

        let tokenId =1;
        let uri = baseURI + tokenId + ".png";
        console.log('\n\t uri is: ', uri);
        
        await waitForTx(await apeNFT.connect(deployer).mint(user, tokenId));
        await waitForTx(await apeNFT.connect(deployer).setTokenURI(tokenId, uri));
  
        tokenId =2;
        uri = baseURI + tokenId + ".png";
        await waitForTx(await apeNFT.mint(user2, tokenId));
        await waitForTx(await apeNFT.setTokenURI(tokenId, uri));

        tokenId =3;
        uri = baseURI + tokenId + ".png";
        await waitForTx(await apeNFT.mint(user3, tokenId));
        await waitForTx(await apeNFT.setTokenURI(tokenId, uri));

        tokenId=4;
        uri = baseURI + tokenId + ".png";
        await waitForTx(await apeNFT.mint(user4, tokenId));
        await waitForTx(await apeNFT.setTokenURI(tokenId, uri));

        tokenId=5;
        uri = baseURI + tokenId + ".png";
        await waitForTx(await apeNFT.mint(user5, tokenId));
        await waitForTx(await apeNFT.setTokenURI(tokenId, uri));

        tokenId=6;
        uri = baseURI + tokenId + ".png";
        await waitForTx(await apeNFT.mint(user6, tokenId));
        await waitForTx(await apeNFT.setTokenURI(tokenId, uri));

        tokenId=7;
        uri = baseURI + tokenId + ".png";
        await waitForTx(await apeNFT.mint(user7, tokenId));
        await waitForTx(await apeNFT.setTokenURI(tokenId, uri));
        
        let tokenURI  = await apeNFT.tokenURI(1);
        console.log('\n\t-- NFT tokenURI is: ', tokenURI);
        const tokenURIData = JSON.parse(Buffer.from(tokenURI.split(",")[1], "base64").toString());
        // console.log('\n\t-- NFT tokenURIData is: ', tokenURIData);
        console.log('\n\t-- NFT tokenURIData.name is: ', tokenURIData.name);
        console.log('\t-- NFT tokenURIData.description is: ', tokenURIData.description);
        console.log('\t-- NFT tokenURIData.image is: ', tokenURIData.image);

        let owner = await apeNFT.ownerOf(1);
        console.log(`\t-- TokenID: 1 , NFT owner is `,  owner);

   });