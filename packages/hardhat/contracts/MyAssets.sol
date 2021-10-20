pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyAssets is ERC721URIStorage, Ownable{

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  //this marks an item in IPFS as "forsale"
  mapping (bytes32 => bool) public forSale;
  //this lets you look up a token by the uri (assuming there is only one of each uri for now)
  mapping (bytes32 => uint256) public uriToTokenId;


  constructor(bytes32[] memory assetsForSale) ERC721("MyAssets", "MYA") {
    for(uint256 i=0;i<assetsForSale.length;i++){
      forSale[assetsForSale[i]] = true;
    }
  }
  
  
  function addAssets(bytes32[] memory assetsForSale) public{
      for(uint256 i=0;i<assetsForSale.length;i++){
        forSale[assetsForSale[i]] = true;
      }
  }

  function checkStatus(string memory tokenURI) public view
      returns (bool){
      
      bytes32 uriHash = keccak256(abi.encodePacked(tokenURI));
      return forSale[uriHash];
  }

  function mintItem(string memory tokenURI)
      public
      returns (uint256)
  {
      bytes32 uriHash = keccak256(abi.encodePacked(tokenURI));

      //make sure they are only minting something that is marked "forsale"
      require(forSale[uriHash],"NOT AVAILABLE");
      forSale[uriHash]=false;

      _tokenIds.increment();

      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);
      _setTokenURI(id, tokenURI);

      uriToTokenId[uriHash] = id;

      return id;
  }
}