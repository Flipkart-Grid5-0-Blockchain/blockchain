const {ethers, network, deployments} = require("hardhat");

async function main() {
  await deployments.fixture(["RewardToken","Governance"]);

  const rewardToken = await deployments.get("RewardToken");
  const contract = await ethers.getContractAt(
       rewardToken.abi,
       rewardToken.address
     );

  const governance = await deployments.get("Governance");
 const tx = await contract.transferOwnership(governance.address);
 await tx.wait();
 console.log(await contract.owner());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
