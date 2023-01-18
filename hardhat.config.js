require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "binanceSmartChainTestNet",
  networks: {
    hardhat: {},
    binanceSmartChainMainNet: {
      url: process.env.BSC_MAIN_NET_PROVIDER_URL,
      accounts: [process.env.WALLET_PRIVATE_KEY],
      chainId: 56,
    },
    binanceSmartChainTestNet: {
      url: process.env.BSC_TEST_NET_PROVIDER_URL,
      accounts: [process.env.WALLET_PRIVATE_KEY],
      chainId: 97,
    },
  },
  etherscan: {
    apiKey: process.env.BSC_SCAN_API_KEY,
  },
};
