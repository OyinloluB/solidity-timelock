const { ethers } = require("hardhat")

async function main() {
  const timelockContract = await ethers.getContractFactory("Timelock");
  const testTimelockContract = await ethers.getContractFactory("TestTimeLock");

  const deployedTimelockContract = await timelockContract.deploy();
  const deployedTestTimelockContract = await testTimelockContract.deploy();

  await deployedTimelockContract.deployed();
  await deployedTestTimelockContract.deployed();

  const timeLockAddress = deployedTimelockContract.address;
  // const testTimeLockAddress = deployedTestTimelockContract.address;

  console.log("timelock app address", timeLockAddress);

  const deployedTestTimelockContract = await timelockContract.deploy(timeLockAddress);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
})
