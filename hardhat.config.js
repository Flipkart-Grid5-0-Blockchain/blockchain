require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()
module.exports = {
  solidity: "0.8.19",
  defaultNetwork: "hardhat",
  networks:{
  },
  namedAccounts:{
    deployer:{
      default:0,
      4:0,
    },
    player:{
      default:1,
    } 
  },

};