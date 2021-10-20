/* eslint no-use-before-define: "warn" */
const fs = require("fs");
//const chalk = require("chalk");
const { config, ethers } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");
const ipfsAPI = require('ipfs-http-client');
const ipfs = ipfsAPI({host: 'ipfs.infura.io', port: '5001', protocol: 'https' })

const main = async () => {

  let allAssets = {}

  console.log("\n\n Loading artwork.json...\n");
  const artwork = JSON.parse(fs.readFileSync("../../artworkSingle.json").toString())

  for(let a in artwork){
    console.log("  Uploading "+artwork[a].name+"...")
    const stringJSON = JSON.stringify(artwork[a])
    const uploaded = await ipfs.add(stringJSON)
    console.log("   "+artwork[a].name+" ipfs:",uploaded.path)
    allAssets[uploaded.path] = artwork[a]
  }
  fs.writeFileSync("./uploaded2.json",JSON.stringify(allAssets))
  console.log("\n Injecting assets into the smartcontract...")
  let uploadedAssets = JSON.parse(fs.readFileSync("./uploaded2.json"))
  console.log(">",uploadedAssets)
  let bytes32Array = []
  for(let a in uploadedAssets){
    let bytes32 = ethers.utils.id(a)
    bytes32Array.push(bytes32)
  }
  const address = '0x758dE11D79B8adca127c35612f35A660D5Eb8d94'
  const MyAssets = await ethers.getContractFactory('MyAssets')
  const myAssets = await MyAssets.attach(address)
  await myAssets.addAssets(bytes32Array)

};

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

