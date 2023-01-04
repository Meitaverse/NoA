import { task } from "hardhat/config";

task("helloworld", "Print Hello world")
.addParam("name", "hello to who")
.setAction(async ({ name }: { name: string }, hre) =>  {
  console.log("Hello ", name);  
});