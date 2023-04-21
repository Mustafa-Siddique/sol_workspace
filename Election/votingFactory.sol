// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./election.sol";

contract votingFactory {
    // Election details
    struct electionDetails {
        address deployedAddress;
        string electionName;
        string electionDesc;
        address authorityAddress;
        uint256 endTime;
    }

    // Owner of the factory
    address public _owner;

    // Wallets of the authority who can deploy elections
    mapping(address => bool) public _authorityWallets;

    // Mapping of election id to election details
    mapping(uint8 => electionDetails) _electionDetails;

    // Number of elections deployed by the factory
    uint8 numElection = 1;

    // Constructor
    constructor() {
        _owner = msg.sender;
        _authorityWallets[msg.sender] = true;
    }

    // Add a new authority wallet
    function addAuthorityWallet(address wallet) public {
        require(!_authorityWallets[wallet], "Wallet already exists");
        require(wallet != address(0), "Wallet cannot be zero address");
        _authorityWallets[wallet] = true;
    }

    // Deploy a new election contract
    function createElection(
        string memory title,
        string memory description,
        uint256 endTime
    ) public {
        require(_authorityWallets[msg.sender], "Not an authority wallet");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(endTime > block.timestamp, "End time must be in the future");
        address electionAddress = address(
            new election(msg.sender, title, description, endTime)
        );

        _electionDetails[numElection] = electionDetails(
            electionAddress,
            title,
            description,
            msg.sender,
            endTime
        );
        numElection++;
    }

    // Get a specific election deployed by the factory
    function getElection(uint8 id)
        public
        view
        returns (electionDetails memory)
    {
        return _electionDetails[id];
    }

    // Get all elections deployed by the factory
    function getAllElections() public view returns (electionDetails[] memory) {
        electionDetails[] memory elections = new electionDetails[](
            numElection - 1
        );
        for (uint8 i = 1; i < numElection; i++) {
            elections[i - 1] = _electionDetails[i];
        }
        return elections;
    }

    // Get active elections deployed by the factory
    function getActiveElections()
        public
        view
        returns (electionDetails[] memory)
    {
        electionDetails[] memory elections = new electionDetails[](
            numElection - 1
        );
        uint8 count = 0;
        for (uint8 i = 1; i < numElection; i++) {
            if (_electionDetails[i].endTime > block.timestamp) {
                elections[count] = _electionDetails[i];
                count++;
            }
        }
        return elections;
    }
}
