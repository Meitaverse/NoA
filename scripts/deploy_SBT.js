/*
$ npx hardhat run scripts/deploy_SBT.js
*/

const { ethers, upgrades } = require("hardhat");

async function main() {
 
  let [deployer,ownerofToken] = await ethers.getSigners();
        console.log(deployer.address);
        console.log(ownerofToken.address);

        // Deploy the SBT metadata sbtDescriptor contract
        const SBTMetadataDescriptor = await ethers.getContractFactory('SBTMetadataDescriptor');
        const sbtDescriptor = await SBTMetadataDescriptor.deploy();
        await sbtDescriptor.deployed();
        console.log('SBTMetadataDescriptor deployed to:', sbtDescriptor.address);
        console.log("");

        const SoulBoundTokenV1 = await ethers.getContractFactory('SoulBoundTokenV1');
    
        const name = "Soul Bound Token";
        const symbol = "SBT";
        const organization = "Bitsoul";
        const minterOfToken = deployer.address;
        const signer = deployer.address;

        const soulBoundToken = await upgrades.deployProxy(SoulBoundTokenV1, [
            name, 
            symbol, 
            sbtDescriptor.address,
            organization,
            ownerofToken.address,
            minterOfToken,
            signer
        ], {
          initializer: "initialize",
          kind: "uups",
        });
    
      await soulBoundToken.deployed();

      console.log("soulBoundToken.address: ", soulBoundToken.address);

      let version1 = await soulBoundToken.version();
      console.log("version: ", version1.toNumber());

    //   const SoulBoundTokenV2 = await ethers.getContractFactory('SoulBoundTokenV2');
    //   let soulBoundTokenV2 =  await upgrades.upgradeProxy(soulBoundToken, SoulBoundTokenV2);
    //    console.log("soulBoundTokenV2.address: ", soulBoundTokenV2.address);
    // let version2 = await soulBoundToken.version();
    // console.log("After upgrade, version: ", version2.toNumber());



}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
