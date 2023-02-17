import { task } from "hardhat/config";

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();
  
    for (const account of accounts) {

      let balance  = await hre.ethers.provider.getBalance(account.address);
      console.log("account: ", account.address, ", balance: ", balance);
      // console.log("account: ", account.address);
    }
});