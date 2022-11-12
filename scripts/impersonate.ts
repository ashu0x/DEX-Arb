import { ethers } from "hardhat";

export async function getImpersonatedSigner(){
    const impersonatedSigner = await ethers.getImpersonatedSigner("0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045");
    return impersonatedSigner;
}
