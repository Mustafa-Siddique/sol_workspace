// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./election.sol";

contract votingFactory{
    
    struct electionDetails{
        address deployedAddress;
        string electionName;
        string electionDesc;
        address authorityAddress;
    }

    mapping(uint8=>electionDetails) _electionDetails;

    uint8 numElection = 1;

    function createElection(string memory title, string memory description, uint256 endTime) public {
        address electionAddress = address(new election(msg.sender, title, description, endTime));

        _electionDetails[numElection] = electionDetails(electionAddress, title, description, msg.sender);
        numElection++;
    }

    function getElection(uint8 id) public view returns(electionDetails memory){
        return _electionDetails[id];
    }

    function getAllElections() public view returns (electionDetails[] memory) {
        electionDetails[] memory elections = new electionDetails[](numElection - 1);
        for (uint8 i = 1; i < numElection; i++) {
            elections[i - 1] = _electionDetails[i];
        }
        return elections;
    }

}