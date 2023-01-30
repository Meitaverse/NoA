// 

import { Address, BigInt } from "@graphprotocol/graph-ts";

import { Account, Hub, Project } from "../../generated/schema";
import { ZERO_BIG_INT } from "./constants";
import { loadOrCreateDNFTContract } from "../dnft";

export function loadProject(projectId : BigInt): Project { 
  
  let project = Project.load(projectId.toString());
  return project as Project;
}