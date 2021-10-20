// deploy/00_deploy_LoanNFT.js

const fs = require("fs");
const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log("\n\n 📡 Deploying...\n");

  // read in all the assets to get their IPFS hash...
   await deploy("LoanNFT", {
    from: deployer,
    log: true,
  });

};
module.exports.tags = ["loanNFT"];