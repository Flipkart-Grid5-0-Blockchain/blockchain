// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const rewardToken = await hre.ethers.deployContract("RewardToken", ["MM","MM"]);
  await rewardToken.waitForDeployment();
  const governance = await hre.ethers.deployContract("Governance", [rewardToken.target]);
  await governance.waitForDeployment();
  console.log(rewardToken,governance);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
