import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-mainnet.g.alchemy.com/v2/EVNEqs3LOXxUMjwS64R_H_8292h92VIt",
      }
    }
  },
  solidity: "0.8.17",
};

export default config;
