const {ethers} = require('hardhat');

module.exports=async({getNamedAccounts, deployments})=>{
    const {deployer} = await getNamedAccounts();
    const {deploy, log} = deployments
    const rewardAddress = (await ethers.getContract("RewardToken")).address;
    const contract = await deploy("Governance",{
        from: deployer,
        args: [rewardAddress],
        log: true,
    });

    log("-----Log-------")
}
module.exports.tags =["all", "Governance"]