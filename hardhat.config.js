require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("dotenv").config()
module.exports = {
  solidity: "0.8.19",
  defaultNetwork: "hardhat",
  networks: {
    hardhat:{
     chainId:31337,
     forking:{
      url:process.env.MAINNET_RPC_URL
     }
    },
    sepolia: {
      url: process.env.RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
      saveDeployments:true,
      chainId: 11155111, //for rinkeby
      blockConfirmations:5,
    },
    localhost:{
      url:"http://127.0.0.1:8545/",
      //accounts : Hardhat uses it own local accounts automatically
      chainId:31337,
      blockConfirmations:1,
    }
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