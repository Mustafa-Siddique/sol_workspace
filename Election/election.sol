// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract election{

    address public owner;
    string electionName;
    string electionDesc;
    bool electionEnded;

    constructor(address _owner, string memory _title, string memory _description){
        owner = _owner;
        electionName = _title;
        electionDesc = _description;
        electionEnded = false;
    }

    struct politicalParty{
        string partyName;
        string partySlogan;
        string logoUri;
        uint16 voteCount;
        string contactEmail;
        string officeAddress;
    }

    mapping(uint8=>politicalParty) public parties;

    struct Voter{
        string name;
        uint32 nationalId; // PPSN Number - String
        uint128 dob; // must be entered in epoch format visit this for conversion https://www.epochconverter.com
        string residentialAddress; 
        string photoUri;
        string email; // Email Verification
        address wallet;
        string verificationStatus;
        bool voted;
    }

    mapping(uint8=>Voter) voters;

    uint8 numParties = 1;
    uint8 numVoters;

    function addParty(string memory _name, string memory _slogan, string memory _logoUri, string memory _mail, string memory _address) public {
        require(owner == msg.sender, "You don't have the authority to create a Political Party.");

        uint8 _id = numParties;
        parties[_id] = politicalParty(_name, _slogan, _logoUri, 0, _mail, _address);
    }
}