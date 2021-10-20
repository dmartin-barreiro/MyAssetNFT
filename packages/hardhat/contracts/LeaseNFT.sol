// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract LeaseNFT is IERC721Receiver, Pausable, Ownable {

    event LeasesUpdated();

    using SafeMath for uint;

    enum Status { PENDING, ACTIVE, CANCELLED, ENDED }

    struct LeaseOffer {
        uint leaseID;
        address payable lessor; // Owner of asset
        address payable lessee; // User of asset
        address smartContractAddressOfNFT;
        uint tokenIdNFT;
        uint collateralAmount;
        uint leasePrice;
        uint leasePeriod;
        uint endLeaseTimeStamp;
        Status status;
    }

    uint public totalLeaseOffers;
    mapping(uint => LeaseOffer) public allLeaseOffers;

    
    modifier isValidLeaseID(uint leaseID) {
        require(leaseID < totalLeaseOffers, "Lease ID is invalid.");
        _;
    }

    
    constructor() public {
         totalLeaseOffers = 0;
    }

    // Equivalent to 'bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))'
    // Or this.onERC721Received.selector
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public override returns (bytes4) {
        return 0x150b7a02;
    }

    //Pause Leasing contract
    function pauseLeasing() public onlyOwner {
        _pause();
    }
    
    
    //Reactivate Leasing contract
    function unPauseLeasing() public onlyOwner {
        _unpause();
    }
    
    //It is called by users who want to lease out their NFT. They
    //must have approved the address of the leasing smart contract to begin the transfer of the NFT

    function createLeaseOffer(address smartContractAddressOfNFT,
                                uint tokenIdNFT,
                                uint collateralAmount,
                                uint leasePrice,
                                uint leasePeriod) public whenNotPaused {
        
        require(leasePeriod < 4 weeks, "Lease for a maximum of 4 weeks.");

        IERC721 currentNFT = IERC721(smartContractAddressOfNFT);
        require(currentNFT.getApproved(tokenIdNFT) == address(this), "Transfer has to be approved first");

        LeaseOffer storage leaseOffer =  allLeaseOffers[totalLeaseOffers];
        leaseOffer.leaseID = totalLeaseOffers;
        leaseOffer.lessor = payable(msg.sender);
        leaseOffer.lessee = payable(address(0x0));
        leaseOffer.smartContractAddressOfNFT = smartContractAddressOfNFT;
        leaseOffer.tokenIdNFT = tokenIdNFT;
        leaseOffer.collateralAmount = collateralAmount;
        leaseOffer.leasePrice = leasePrice;
        leaseOffer.leasePeriod = leasePeriod;
        leaseOffer.status = Status.PENDING;
        totalLeaseOffers = SafeMath.add(totalLeaseOffers, 1);

        //The NFT is transfered from its owner to the address of the smart contract.
        currentNFT.safeTransferFrom(msg.sender, address(this), tokenIdNFT);
        emit LeasesUpdated();
    }

    //Call by a lessee given the leaseID
    function acceptLeaseOffer(uint leaseID) payable public isValidLeaseID(leaseID) whenNotPaused {
        
        require(allLeaseOffers[leaseID].status == Status.PENDING, "Status is not PENDING for lease.");
        require(allLeaseOffers[leaseID].lessor != msg.sender, "Invalid operation. You cannot lease your own asset.");

        uint sumRequiredToLease = SafeMath.add(allLeaseOffers[leaseID].collateralAmount, allLeaseOffers[leaseID].leasePrice);

        require(msg.value >= sumRequiredToLease, "Not enough Ether sent to function to start lease.");

        allLeaseOffers[leaseID].lessee = payable(msg.sender);
        allLeaseOffers[leaseID].status = Status.ACTIVE;
        allLeaseOffers[leaseID].endLeaseTimeStamp = SafeMath.add(block.timestamp, allLeaseOffers[leaseID].leasePeriod);

        // Send lease price to lessor
        allLeaseOffers[leaseID].lessor.transfer(allLeaseOffers[leaseID].leasePrice);

        // Send NFT to lessee
        IERC721 currentNFT = IERC721(allLeaseOffers[leaseID].smartContractAddressOfNFT);
        currentNFT.transferFrom(address(this), msg.sender, allLeaseOffers[leaseID].tokenIdNFT);
        emit LeasesUpdated();
    }

    
    function endLeaseOffer(uint leaseID) public isValidLeaseID(leaseID) {
        require(allLeaseOffers[leaseID].status == Status.ACTIVE, "Status is not ACTIVE to end lease");
        require((msg.sender == allLeaseOffers[leaseID].lessor && block.timestamp >= allLeaseOffers[leaseID].endLeaseTimeStamp) 
                 || msg.sender == allLeaseOffers[leaseID].lessee, "Invalid operation.");

        allLeaseOffers[leaseID].status = Status.ENDED;

        // Lessee sends token back to lessor and receives his collateral, after he approves the transfer
        if (msg.sender == allLeaseOffers[leaseID].lessee) {
            IERC721 currentNFT = IERC721(allLeaseOffers[leaseID].smartContractAddressOfNFT);
            require(currentNFT.getApproved(allLeaseOffers[leaseID].tokenIdNFT) == address(this), "Smart contract needs to be approved first.");
            currentNFT.safeTransferFrom(msg.sender, allLeaseOffers[leaseID].lessor,
                                        allLeaseOffers[leaseID].tokenIdNFT);
        }

        // The caller of the function will receive the collateral
        payable(msg.sender).transfer(allLeaseOffers[leaseID].collateralAmount);
        emit LeasesUpdated();
    }

    function cancelLeaseOffer(uint leaseID) public isValidLeaseID(leaseID) {
        require(allLeaseOffers[leaseID].status == Status.PENDING, "Status is not PENDING to cancel lease agreement.");
        require(msg.sender == allLeaseOffers[leaseID].lessor, "You are not the lessor.");

        allLeaseOffers[leaseID].status = Status.CANCELLED;

        IERC721 currentNFT = IERC721(allLeaseOffers[leaseID].smartContractAddressOfNFT);
        currentNFT.safeTransferFrom(address(this), allLeaseOffers[leaseID].lessor,
                                    allLeaseOffers[leaseID].tokenIdNFT);
        emit LeasesUpdated();
    }
}
