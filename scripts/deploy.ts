import { ethers } from "hardhat";
import { getImpersonatedSigner } from "./impersonate";

async function main() {
  const signer = await getImpersonatedSigner();
  console.log(signer.address)
  // const Arb = await ethers.getContractFactory("Arb");
  // const arb = await Arb.deploy({from: signer});
  // await arb.deployed();
  // console.log(`Arb deployed to ${arb.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
