/*
import { ethers, upgrades } from "hardhat";

import { parseEther } from "ethers/lib/utils";

import { deployTokens, vaultActions } from "./common";

import {
  VaultV1__factory,
  VaultV1,
  VaultV2,
  VaultV2__factory,
} from "../../typechain-types";

export async function deployVersionOneUpgradesFixture() {
  const [owner, alice] = await ethers.getSigners();
  const { token0, token1 } = await deployTokens(owner, alice);

  const implV1Factory = new VaultV1__factory(owner);

  const vaultV1Proxy = (await upgrades.deployProxy(
    implV1Factory,
    [token0.address, "Vault"],
    { kind: "uups", initializer: "initialize" }
  )) as VaultV1;

  await token0.connect(owner).approve(vaultV1Proxy.address, parseEther("100"));

  return {
    owner,
    alice,
    token0,
    token1,
    vaultV1Proxy,
  };
}

export async function deployVersionTwoUpgradesFixture() {
  const [owner, alice] = await ethers.getSigners();
  const { token0, token1, token2 } = await deployTokens(owner, alice);

  const implV1Factory = new VaultV1__factory(owner);

  const vaultV1Proxy = (await upgrades.deployProxy(
    implV1Factory,
    [token0.address, "Vault"],
    { kind: "uups", initializer: "initialize" }
  )) as VaultV1;

  await vaultActions(owner, alice, [token0, token1], vaultV1Proxy);

  const implV2Factory = new VaultV2__factory(owner);

  const vaultV2Proxy = (await upgrades.upgradeProxy(
    vaultV1Proxy.address,
    implV2Factory,
    {
      kind: "uups",
      call: { fn: "addToken", args: [token1.address] },
    }
  )) as VaultV2;

  return {
    owner,
    alice,
    token0,
    token1,
    token2,
    vaultV2Proxy,
  };
}

*/