const {ethers} = require("hardhat");

module.exports = async({getNamedAccounts, deployments})=>{
const {deployer} = await getNamedAccounts();
const {deploy, log} = deployments
log(deployer);

const contract = await deploy("RewardToken",{
    from: deployer,
    args: ["KK", "KK"],
    log: true,
});

log("-----Log-------")
}
module.exports.tags = ["all","RewardToken"];
  // "@nomicfoundation/hardhat-ethers": "^3.0.2",
    // "@nomiclabs/hardhat-ethers": "yarn:hardhat-deploy-ethers",
    // "@nomiclabs/hardhat-etherscan": "^3.1.7",
    // "@nomiclabs/hardhat-waffle": "^2.0.6",
    // "@openzeppelin/contracts": "^4.9.3",
    // "chai": "^4.3.7",
    // "dotenv": "^16.3.1",
    // "ethereum-waffle": "^4.0.10",
    // "ethers": "^6.6.7",
    // "hardhat": "^2.17.0",
    // "hardhat-contract-sizer": "^2.10.0",
    // "hardhat-deploy": "^0.11.34",
    // "hardhat-deploy-ethers": "^0.4.1",
    // "hardhat-gas-reporter": "^1.0.9",
    // "prettier": "^3.0.0",
    // "prettier-plugin-solidity": "^1.1.3",
    // "solhint": "^3.4.1",
    // "solidity-coverage": "^0.8.4"