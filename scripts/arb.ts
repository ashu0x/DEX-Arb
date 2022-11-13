import { ethers, network } from "hardhat";
 
let owner,arb:any;
let balances: any = {};

let config = require("../config/fantom.json")

const searchForGoodRoutes = async()=>{
    const targetRoute: any = {}
    targetRoute.router1 = config.routers[Math.floor(Math.random() * config.routers.length)].address
    targetRoute.router2 = config.routers[Math.floor(Math.random() * config.routers.length)].address
    targetRoute.token1 = config.baseAssets[Math.floor(Math.random() * config.routers.length)].address
    targetRoute.token2 = config.baseAssets[Math.floor(Math.random() * config.routers.length)].address
    return targetRoute;
}

let goodCount = 0;
const useGoodRoutes = async()=>{
    const targetRoute:any = {}
    const route = config.routes[goodCount]
    goodCount += 1;
    if(goodCount > config.routes.length) goodCount = 0
    targetRoute.router1 = route[0]
    targetRoute.router2 = route[1]
    targetRoute.token1 = route[2]
    targetRoute.token2 = route[3]
    return targetRoute
}

const lookForDualTrade = async()=>{
    let targetRoute: any;
    if(config.routes.length > 0){
        targetRoute = useGoodRoutes();
    } else{
        targetRoute = searchForGoodRoutes();
    }
    try {
        let tradeSize = balances[targetRoute.token1].balance;
        const amtBack = await arb.estimateDualDexTrade(targetRoute.router1, targetRoute.router2, targetRoute.token1, targetRoute.token2, tradeSize)
        const multiplier = ethers.BigNumber.from(config.minBasisPointsPerTrade + 10000)
    } catch (error) {
        
    }
}

const setup = async()=>{
    [owner] = await ethers.getSigners()
    console.log("Owner Address ", owner.address)
    const IArb = await ethers.getContractFactory("Arb");
    const arbContractAddress = process.env.ARB_ADDRESS;
    arb = await IArb.attach("0x0dE17CF26B7519c6f761f3702DEd3BC13bc71Be5");
    await arb.deployed();
    for(let i=0; i<config.baseAssets.length; i++){
        const asset = config.baseAssets[i];
        const inf = await ethers.getContractFactory("WETH9");
        const assetToken = await inf.attach(asset.address);
        const balance = await assetToken.balanceOf(config.arbContractAddress);
        console.log(asset.sym, balance.toString());
        balances[asset.address] = {sym: asset.sym, balance, startBalance: balance }
    }
}

const logResults = async()=>{
    console.log("....LOGS.....")
    for(let i=0;i<config.baseAssets.length;i++){
        const asset = config.baseAssets[i]
        const inf = await ethers.getContractFactory("WETH9")
        const assetToken = await inf.attach(asset.address)
        balances[asset.address].balance = await assetToken.balanceOf(config.arbContractAddress)
        const diff = balances[asset.address].balance.sub(balances[asset.address].startBalance)
        const basisPoints = diff.mul(10000).div(balances[asset.address].startBalance)
        console.log(`${asset.sym} BasisPoints: ${basisPoints}`)
    }
}