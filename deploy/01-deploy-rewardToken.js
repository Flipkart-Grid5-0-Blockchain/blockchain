const {} = require("hardhat")

module.exports = async({getNamedAccounts, deployments})=>{
    const {deploy,log} = deployments;
    const {deployer} = await getNamedAccounts();
   log ("Going to deploy RewardToken.sol")
   const RewardToken = await deploy("RewardToken",{
        from : deployer,
        args : ['Sam',"s"],
        log : true
    });

    log(RewardToken.address);
    

    // const contract = await ethers.getContract("RentalCar");
    // log (contract);
    // log("Contract deployed",RewardToken);

    module.exports.tags = ['RewardToken'];
} 