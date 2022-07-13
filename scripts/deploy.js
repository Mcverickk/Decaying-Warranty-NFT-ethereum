const hre = require("hardhat");

async function main() {

  const warrantyNFT = await hre.ethers.getContractFactory("WarrantyNFT");
  const contract = await warrantyNFT.deploy();

  await contract.deployed();

  console.log("Contract deployed at address:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
