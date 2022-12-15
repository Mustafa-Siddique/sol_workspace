// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

// Define the data structure for the NFTs
struct Domain {
    string name;
    uint256 totalSupply;
}

// Define the contract that can mint NFTs
contract DomainMinter {
    // Define the array of NFTs
    Domain[] public domains;

    // Define the mint function
    function mint(string memory _name, uint256 _totalSupply) public {
        // Create a new Domain NFT
        Domain memory newDomain = Domain(_name, _totalSupply);

        // Add the new Domain NFT to the array of NFTs
        domains.push(newDomain);
    }
}
