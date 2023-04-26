// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract election {
    address public owner;
    string electionName;
    string electionDesc;
    uint256 electionEndTime;
    bool electionEnded;

    // modifier to prevent adding same voter twice using msg.sender
    modifier onlyOnce() {
        bool found = false;
        for (uint8 i = 1; i < numVoters; i++) {
            if (voters[i].wallet == msg.sender) {
                found = true;
                break;
            }
        }
        require(!found, "You have already registered.");
        _;
    }

    constructor(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 time
    ) {
        owner = _owner;
        electionName = _title;
        electionDesc = _description;
        electionEndTime = time;
        electionEnded = false;
    }

    struct politicalParty {
        string partyName;
        string partySlogan;
        string logoUri;
        uint16 voteCount;
        string contactEmail;
        string officeAddress;
    }

    mapping(uint8 => politicalParty) public parties;

    struct Voter {
        string name;
        string ppsnNumber; // PPSN Number - String
        uint128 dob; // must be entered in epoch format visit this for conversion https://www.epochconverter.com
        string residentialAddress;
        string photoUri;
        string email; // Email Verification
        address wallet;
        bool verified;
        bool voted;
    }

    mapping(uint8 => Voter) voters;

    // mapping to store voter verification uri for identity verification
    mapping(address => string) voterVerificationUri;

    uint8 numParties = 1;
    uint8 numVoters = 1;

    function addParty(
        string memory _name,
        string memory _slogan,
        string memory _logoUri,
        string memory _mail,
        string memory _address
    ) public {
        require(
            owner == msg.sender,
            "You don't have the authority to create a Political Party."
        );

        uint8 _id = numParties;
        parties[_id] = politicalParty(
            _name,
            _slogan,
            _logoUri,
            0,
            _mail,
            _address
        );
        numParties++;
    }

    function getNumOfParties() public view returns (uint8) {
        return (numParties - 1);
    }

    function addVoter(
        string memory _name,
        string memory _ppsn,
        uint128 _dob,
        string memory _address,
        string memory photo,
        string memory email
    ) public onlyOnce {
        require(
            owner != msg.sender,
            "You don't have the authority to create a Voter."
        );
        uint8 _id = numVoters;
        voters[_id] = Voter(
            _name,
            _ppsn,
            _dob,
            _address,
            photo,
            email,
            msg.sender,
            false,
            false
        );
        numVoters++;
    }

    // Upload voter verification image to IPFS and store the hash in the contract
    function uploadVerification(string memory assetURI, uint8 _voterId) public {
        require(
            msg.sender == voters[_voterId].wallet,
            "You don't have authority to upload verification."
        );
        require(
            keccak256(abi.encodePacked(voterVerificationUri[msg.sender])) ==
                keccak256(abi.encodePacked("")) ||
                keccak256(abi.encodePacked(voterVerificationUri[msg.sender])) ==
                keccak256(abi.encodePacked(" ")),
            "You have already uploaded verification."
        );
        voterVerificationUri[msg.sender] = assetURI;
    }

    function checkVerification(
        address _voterAddress
    ) public view returns (string memory) {
        require(
            msg.sender == owner || msg.sender == _voterAddress,
            "You don't have authority to access this information."
        );
        if (
            keccak256(abi.encodePacked(voterVerificationUri[_voterAddress])) ==
            keccak256(abi.encodePacked("")) ||
            keccak256(abi.encodePacked(voterVerificationUri[_voterAddress])) ==
            keccak256(abi.encodePacked(" "))
        ) {
            return "Not Verified";
        } else {
            return voterVerificationUri[_voterAddress];
        }
    }

    function getNumOfVoters() public view returns (uint8) {
        return (numVoters - 1);
    }

    function getVoterDetails(uint8 id) public view returns (Voter memory) {
        require(
            msg.sender == owner || msg.sender == voters[id].wallet,
            "You don't have authority to access this information."
        );
        return voters[id];
    }

    function verifyVoter(uint8 id) public returns (string memory) {
        require(
            msg.sender == owner,
            "You don't have authority to verify voters"
        );
        require(!voters[id].verified, "Voter already verified.");
        voters[id].verified = true;
        return ("You have been verified successfully!");
    }

    function vote(
        uint8 _partyId,
        uint8 _voterId
    ) public returns (string memory) {
        require(
            msg.sender == voters[_voterId].wallet,
            "You can't vote on others behalf."
        );
        require(!voters[_voterId].voted, "You cannot double vote.");
        require(block.timestamp <= electionEndTime, "Election ended.");
        require(voters[_voterId].verified, "You are not verified.");
        require(
            _partyId < numParties && _partyId > 0,
            "You can't vote for a party that doesn't exist."
        );

        voters[_voterId].voted = true;
        parties[_partyId].voteCount++;
        return ("You have voted successfully!");
    }

    // End election using election id and return election status
    function endElection() public returns (bool) {
        require(
            msg.sender == owner,
            "You don't have authority to end election."
        );
        require(!electionEnded, "Election already ended.");
        electionEnded = true;
        return electionEnded;
    }

    // Get winner details using election id
    function winnerDetails() public view returns (politicalParty memory) {
        require(electionEnded, "Election not ended yet.");
        uint8 partyId;
        for (uint8 i = 1; i < numParties; i++) {
            uint16 tempVoteCount = 0;
            if (tempVoteCount < parties[i].voteCount) {
                tempVoteCount = parties[i].voteCount;
                partyId = i;
            }
        }
        return parties[partyId];
    }

    // Get election details using election id
    function getElectionDetails()
        public
        view
        returns (string memory, string memory)
    {
        return (electionName, electionDesc);
    }

    // Check if voter is registered using wallet address and return voter id
    function isRegistered(address _wallet) public view returns (uint8) {
        for (uint8 i = 1; i < numVoters; i++) {
            if (voters[i].wallet == _wallet) {
                return i;
            }
        }
        return 0;
    }
}
