// 

import { Address, BigInt } from "@graphprotocol/graph-ts";

import { Account, Hub, Project } from "../../generated/schema";
import { ZERO_BIG_INT } from "./constants";
import { loadOrCreateNFTContract } from "../dnft";

export function loadProject(projectId : BigInt): Project { //account: Account, derivativeNFTAddress: Address
  
  // let addressHex = derivativeNFTAddress.toHex();
  let project = Project.load(projectId.toString());
  // if (!project) {
  //   project = new Project(projectId.toString());
  //   // project.hub = hub.id
  //   project.derivativeNFT = loadOrCreateNFTContract(derivativeNFTAddress).id;
  //   project.projectId = ZERO_BIG_INT;
  //   project.projectCreator = projectCreator.id;
  //   project.timestamp = ZERO_BIG_INT;
  //   project.save();
  // }
  return project as Project;
}