const { ethers } = require("hardhat");

const main = async () => {
  const VRFv2Consumer = await ethers.getContractFactory("VRFv2Consumer");

  // Deploy the contract
  const vRFv2Consumer = await VRFv2Consumer.deploy(); //TODO Add subscriptionId as constructor parameter
  await vRFv2Consumer.deployed();

  // Print the address of the deployed contract
  console.log(`Contract VRFv2Consumer deployed to:`, vRFv2Consumer.address);

  // Wait for bscscan to notice that the contract has been deployed
  await vRFv2Consumer.deployTransaction.wait(10);

  // Verify the contract after deploying
  await hre.run("verify:verify", {
    address: vRFv2Consumer.address,
    constructorArguments: [],
  });
};

// Call the main function and catch if there is any error
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
