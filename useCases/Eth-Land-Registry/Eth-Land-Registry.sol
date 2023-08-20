// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ETH Land Registry
// This contract allows to register the ownership of a land.
// The owners of the contract can request a new land registration to govt.
// The govt can approve/reject the registration and generate a unique hash for the land.
// The owners/govt can transfer the ownership to someone else.

enum Status {
    Invalid,
    Pending,
    Approved,
    Rejected
}
enum UserTypes {
    Unregistered,
    Admin,
    LandOwner
}

// Structs
struct Land {
    bytes32 landId;
    string ownerName;
    string location;
    uint256 area;
    address owner;
    uint256 registrationDate;
}

struct registrationRequest {
    bytes32 landId;
    string ownerName;
    string location;
    uint256 area;
    uint256 price;
    address owner;
    uint256 approvalDate;
    string uploadedFiles;
    Status status;
}

struct LandTransferRequest {
    bytes32 landId;
    address from;
    address to;
    uint256 price;
    string uploadedFiles;
    uint256 approvalDate;
    Status status;
}

struct LandOwner {
    string name;
    string nationality;
    string idType;
    string idNumber;
    string _address;
    string uploadedId;
    address wallet;
    uint256 registrationDate;
    uint256 landCount;
    bytes32[] landIds;
}

contract EthLandRegistry {
    // Address
    address private admin;

    // Counters
    uint256 private landCounter = 0;
    uint256 private registrationRequestCounter = 0;
    uint256 private transferRequestCounter = 0;
    uint256 private landOwnerCounter = 0;

    // Mappings
    mapping(bytes32 => Land) public lands;
    mapping(uint256 => registrationRequest) public landRegistrationRequests;
    mapping(uint256 => LandTransferRequest) public landTransferRequests;
    mapping(address => UserTypes) private users;
    mapping(address => LandOwner) private landOwners;
    mapping(bytes32 => LandTransferRequest[]) private landTransferHistory;

    // Events
    event LandRegistered(
        bytes32 landId,
        string ownerName,
        string location,
        uint256 area,
        address owner,
        uint256 registrationDate
    );
    event LandRegistrationRequest(
        bytes32 landId,
        string ownerName,
        string location,
        uint256 area,
        uint256 price,
        address owner,
        uint256 approvalDate,
        string uploadedFiles
    );
    event LandRegistrationRequestApproved(
        bytes32 landId,
        string ownerName,
        string location,
        uint256 area,
        uint256 price,
        address owner,
        uint256 approvalDate,
        string uploadedFiles
    );
    event LandRegistrationRequestRejected(
        bytes32 landId,
        string ownerName,
        string location,
        uint256 area,
        uint256 price,
        address owner,
        uint256 approvalDate,
        string uploadedFiles
    );
    event TransferRequest(
        bytes32 landId,
        address from,
        address to,
        uint256 price,
        string uploadedFiles,
        uint256 approvalDate
    );
    event LandTransferRequestApproved(
        bytes32 landId,
        address from,
        address to,
        uint256 price,
        string uploadedFiles,
        uint256 approvalDate
    );
    event LandTransferRequestRejected(
        bytes32 landId,
        address from,
        address to,
        uint256 price,
        string uploadedFiles,
        uint256 approvalDate
    );

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyLandOwner() {
        require(
            users[msg.sender] == UserTypes.LandOwner,
            "Only land owner can call this function"
        );
        _;
    }

    modifier onlyLandOwnerOrAdmin(bytes32 _landId) {
        require(
            lands[_landId].owner == msg.sender || msg.sender == admin,
            "Only land owner or admin can call this function"
        );
        _;
    }

    // New Land Registration Request
    function newLandRegistrationRequest(
        string memory _ownerName,
        string memory _location,
        uint256 _area,
        uint256 _price,
        string memory _uploadedFiles
    ) public returns (bytes32) {
        require(
            users[msg.sender] == UserTypes.LandOwner,
            "Only land owners can request for new land registration"
        );
        registrationRequestCounter++;
        bytes32 _landId = keccak256(
            abi.encodePacked(
                _ownerName,
                _location,
                _area,
                msg.sender,
                block.timestamp
            )
        );

        landRegistrationRequests[
            registrationRequestCounter
        ] = registrationRequest(
            _landId,
            _ownerName,
            _location,
            _area,
            _price,
            msg.sender,
            0,
            _uploadedFiles,
            Status.Pending
        );
        emit LandRegistrationRequest(
            _landId,
            _ownerName,
            _location,
            _area,
            _price,
            msg.sender,
            0,
            _uploadedFiles
        );
        return _landId;
    }

    // Land owner registration
    function newOwnerRegistration(
        string memory _name,
        string memory _nationality,
        string memory _idType,
        string memory _idNumber,
        string memory _address,
        string memory _uploadedId
    ) public {
        require(
            users[msg.sender] == UserTypes.Unregistered,
            "Only unregistered users can register as land owners"
        );
        landOwnerCounter++;
        landOwners[msg.sender] = LandOwner(
            _name,
            _nationality,
            _idType,
            _idNumber,
            _address,
            _uploadedId,
            msg.sender,
            block.timestamp,
            0,
            new bytes32[](0)
        );
        users[msg.sender] = UserTypes.LandOwner;
    }
}
