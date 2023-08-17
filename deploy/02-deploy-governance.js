const {ethers} = require("hardhat")

module.exports = async({getNamedAccounts, deployments})=>{
    const {deploy,log} = deployments;
    const {deployer} = await getNamedAccounts();
    log ("Going to deploy Governance.sol")
    const RewardTokenAddress = (await ethers.getContract("RewardToken")).target;
    log("RewardTokenAddress",RewardTokenAddress)
    const Governance = await deploy("Governance",{
        from : deployer,
        args : [RewardTokenAddress],
        log : true
    });

    
    // log("Contract deployed",Governance);

    module.exports.tags = ['Governance'];
} 