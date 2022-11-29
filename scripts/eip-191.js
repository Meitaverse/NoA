
/*
$ npx hardhat run scripts/eip-191.js
*/

const { ethers } = require('hardhat');
const { BigNumber, Signer, utils, Wallet } = require('ethers');
const { arrayify, keccak256, solidityKeccak256 }  = require('ethers/lib/utils');
const contract = require('../artifacts/contracts/SoulBoundTokenV1.sol/SoulBoundTokenV1.json');

async function main() {
    const [deployer, admin, organizer, user1,user2,user3,user4] = await ethers.getSigners();
    const signingKey = process.env.PRIVATE_KEY;
    console.log("signingKey: ", signingKey);

    const nickName_ = "Sky Lee";
    const role_ = "Organizer";
    let signature_;
    let to_ = user2.address;
    
    const wallet = new Wallet(signingKey, ethers.provider)
    const hash = ethers.utils.solidityKeccak256(['string', 'string', 'address'], [nickName_, role_, to_]);
    signature_ = await wallet.signMessage(arrayify(hash));
    console.log("hash: ", hash);

    const contractAddress = '0x9A676e781A523b5d0C0e43731313A708CB607508';
    const contractProxy = await ethers.getContractAt(contract.abi, contractAddress);

    let tx = await contractProxy.connect(user2).mint(nickName_, role_, to_, signature_);

    let receipt = await tx.wait();
    let transferEvent = receipt.events.filter(e => e.event === 'Transfer')[0];
    let tokenId = transferEvent.args['_tokenId'];

    console.log(
        "user2 mint SBT ok, tokenId: ", tokenId.toNumber()
    );
    
}


main();