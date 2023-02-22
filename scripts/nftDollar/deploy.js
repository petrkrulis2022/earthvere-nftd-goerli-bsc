const { ethers } = require("hardhat");

const main = async () => {
  const NFTDollar = await ethers.getContractFactory("NFTDollar");

  // Deploy the contract
  const nftDollar = await NFTDollar.deploy();
  await nftDollar.deployed();

  // Print the address of the deployed contract
  console.log(`Contract NFT Dollar deployed to:`, nftDollar.address);

  // Wait for scan to notice that the contract has been deployed
  await nftDollar.deployTransaction.wait(10);

  // Verify the contract after deploying
  await hre.run("verify:verify", {
    address: nftDollar.address,
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
