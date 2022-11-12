import { ethers, network } from "hardhat";

let owner,arb, balances;

const setup = async()=>{
    [owner] = await ethers.getSigners()
    console.log("Owner Address ", owner.address)
    const IArb = await ethers.getContractFactory("Arb");
    arb = await IArb.deploy();
    await arb.deployed();
    balances = {};
    
}