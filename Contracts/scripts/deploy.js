const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const RobotPartsContract = await hre.ethers.getContractFactory("RobotParts");
  const RobotParts = await RobotPartsContract.deploy();

  await RobotParts.deployed();

  console.log("RobotParts deployed to:", RobotParts.address);

  const RewarderContract = await hre.ethers.getContractFactory("RewarderManager");
  const Rewarder = await RewarderContract.deploy(RobotParts.address);
  await Rewarder.deployed();
  console.log("Rewarder deployed to:", Rewarder.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
