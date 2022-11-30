// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./election.sol";

contract votingFactory{
    
    struct electionDetails{
        address deployedAddress;
        string electionName;
        string electionDesc;
    }

    function createElection(string memory _alias, string memory title, string memory description) public {
        address electionAddress = address(new election(msg.sender, title, description));

        electionDetails[_alias].deployedAddress = electionAddress;
        electionDetails[_alias].electionName = title;
        electionDetails[_alias].electionDesc = description;
    }

}