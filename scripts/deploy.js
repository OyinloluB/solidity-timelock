const { ethers } = require("hardhat")

async function main() {
  const timelockContract = await ethers.getContractFactory("Timelock");

  const deployedTimelockContract = await timelockContract.deploy();

  await deployedTimelockContract.deployed();

  console.log("timelock app address", deployedTimelockContract.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
})
