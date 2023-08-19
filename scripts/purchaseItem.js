const hre = require("hardhat");

async function main() {
  const signer = (await hre.ethers.getSigners())[0];
  const player = (await hre.ethers.getSigners())[1];
  const rewardTokenAddress = "0x5fbdb2315678afecb367f032d93f642f64180aa3";
  const governanceAddress = "0xe7f1725e7734ce288f8367e1bb143e90bb3f0512";
  const governance = await hre.ethers.getContractAt(
    "Governance",
    governanceAddress,
    signer
  );
  const registerUser = await governance.registerUser("samamrmoi");
  await registerUser.wait();
  const tx = await governance.purchaseItem(100000000,'0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f');
  await tx.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
