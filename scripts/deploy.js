const { ethers } = require("hardhat");

async function main() {
  const Governance = await ethers.getContract("Governance");
  console.log("Governance Contract Address:", Governance.address);

  // Now you can interact with the Governance contract methods
  // For example:
  // const userBalance = await Governance.addressToUser(someUserAddress);
  // console.log("User Balance:", userBalance);

  // Make sure to provide actual method calls that interact with the contract
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
