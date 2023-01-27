// 

import { Address } from "@graphprotocol/graph-ts";

import { Profile, Project } from "../../generated/schema";
import { ZERO_BIG_INT } from "./constants";
import { loadOrCreateProfile } from "./profile";

export function loadOrCreateProject(profile: Profile, derivativeNFTAddress: Address): Project {
  // const profile = loadOrCreateProfile(creator)
  
  let addressHex = derivativeNFTAddress.toHex();
  let project = Project.load(addressHex);
  if (!project) {
    project = new Project(addressHex);
    project.derivativeNFT = derivativeNFTAddress;
    project.projectId = ZERO_BIG_INT;
    project.profile = profile.id;
    project.timestamp = ZERO_BIG_INT;
    project.save();
  }
  return project as Project;
}