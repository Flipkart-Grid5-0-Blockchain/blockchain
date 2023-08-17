require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
require("hardhat-gas-reporter");
require("solidity-coverage");
require("hardhat-deploy");
require("hardhat-contract-sizer");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.14",
  defaultNetwork: "hardhat",
  networks: {},
  namedAccounts: {
    deployer: {
      default: 0,
      4: 0,
    },
    player: {
      default: 1,
    },
  },
};
