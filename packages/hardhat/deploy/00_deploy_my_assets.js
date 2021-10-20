// deploy/00_deploy_my_assets.js

const fs = require("fs");
const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log("\n\n 📡 Deploying...\n");

  // read in all the assets to get their IPFS hash...
  let uploadedAssets = JSON.parse(fs.readFileSync("./uploaded.json"))
  let bytes32Array = []
  for(let a in uploadedAssets){
    console.log(" 🏷 IPFS:",a)
    let bytes32 = ethers.utils.id(a)
    console.log(" #️⃣ hashed:",bytes32)
    bytes32Array.push(bytes32)
  }
  console.log(" \n")

  await deploy("MyAssets", {
    from: deployer,
    args: [ bytes32Array ],
    log: true,
  });

};
module.exports.tags = ["MyAssets"];

