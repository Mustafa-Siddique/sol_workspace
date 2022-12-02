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

    uint8 public numElection = 1;

    function createElection(string memory title, string memory description) public {
        address electionAddress = address(new election(msg.sender, title, description));

        _electionDetails[numElection] = electionDetails(electionAddress, title, description, msg.sender);
        numElection++;
    }

    function getElection(uint8 id) public view returns(electionDetails memory){
        return _electionDetails[id];
    }

}