import hre from 'hardhat' 
import assert from 'assert'
import { util } from 'chai'
import { ethers } from 'hardhat'

before('get factories', async function() {
  this.TokenIsERC20 = await hre.ethers.getContractFactory('TokenIsERC20')
  this.TokenIsERC20V2 = await hre.ethers.getContractFactory('TokenIsERC20V2')
})

it('Should deploy the first smart contract and then upgrade it', async function() {
  const TokenIsERC20 = await hre.upgrades.deployProxy(this.TokenIsERC20, [], {
    initializer: "initialize"
  })
  const PROXY = TokenIsERC20.address
  const accounts = await ethers.getSigners();
  let balanceOfOwner = await TokenIsERC20.balanceOf(accounts[0].address)
  let balanceOfOwnerToString = balanceOfOwner.toString()
  assert.equal(balanceOfOwnerToString, "1000000")

  const TokenIsERC20V2 = await hre.upgrades.upgradeProxy(PROXY, this.TokenIsERC20V2)
  assert.equal(await TokenIsERC20V2.version(), "V2")

  await TokenIsERC20V2.mint(accounts[0].address, 777)
  balanceOfOwner = await TokenIsERC20.balanceOf(accounts[0].address)
  balanceOfOwnerToString = balanceOfOwner.toString()
  assert.equal(balanceOfOwnerToString, "1000777")

})