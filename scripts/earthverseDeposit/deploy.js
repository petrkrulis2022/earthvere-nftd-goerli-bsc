const { ethers } = require("hardhat");

const main = async () => {
  const EarthverseDeposit = await ethers.getContractFactory(
    "EarthverseDeposit"
  );

  // Deploy the contract
  const earthverseDeposit = await EarthverseDeposit.deploy(
    "0x0856021E4dFeb3F7d74B8311C6B1E9030cB4309d",
    "0xc890Cba52Dd0BAEa79D2d1aEe47676F55Eb11fB4"
  );
  await earthverseDeposit.deployed();

  // Print the address of the deployed contract
  console.log(
    `Contract EarthverseDeposit deployed to:`,
    earthverseDeposit.address
  );

  // Wait for scan to notice that the contract has been deployed
  await earthverseDeposit.deployTransaction.wait(10);

  // Verify the contract after deploying
  await hre.run("verify:verify", {
    address: earthverseDeposit.address,
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
