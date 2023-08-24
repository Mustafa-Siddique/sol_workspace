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
    string comment;
}

struct LandTransferRequest {
    bytes32 landId;
    address from;
    address to;
    uint256 price;
    string uploadedFiles;
    uint256 approvalDate;
    Status status;
    string comment;
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
    uint256 private rejectedRequestCounter = 0;
    uint256 private transferRequestCounter = 0;
    uint256 private landOwnerCounter = 0;

    // Mappings
    mapping(bytes32 => Land) public lands;
    mapping(uint256 => registrationRequest) private landRegistrationRequests;
    mapping(uint256 => LandTransferRequest) private landTransferRequests;
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
            Status.Pending,
            ""
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

    // Approve Land Registration Request
    function approveLandRegistrationRequest(
        uint256 _requestId
    ) public onlyAdmin {
        require(
            landRegistrationRequests[_requestId].status == Status.Pending,
            "Only pending requests can be approved"
        );
        registrationRequest storage _request = landRegistrationRequests[
            _requestId
        ];
        landCounter++;
        lands[_request.landId] = Land(
            _request.landId,
            _request.ownerName,
            _request.location,
            _request.area,
            _request.owner,
            block.timestamp
        );
        _request.approvalDate = block.timestamp;
        _request.status = Status.Approved;
        landOwners[_request.owner].landCount++;
        landOwners[_request.owner].landIds.push(_request.landId);
        emit LandRegistered(
            _request.landId,
            _request.ownerName,
            _request.location,
            _request.area,
            _request.owner,
            block.timestamp
        );
        emit LandRegistrationRequestApproved(
            _request.landId,
            _request.ownerName,
            _request.location,
            _request.area,
            _request.price,
            _request.owner,
            block.timestamp,
            _request.uploadedFiles
        );
    }

    // Reject Land Registration Request with a comment
    function rejectLandRegistrationRequest(
        uint256 _requestId,
        string memory _comment
    ) public onlyAdmin {
        require(
            landRegistrationRequests[_requestId].status == Status.Pending,
            "Only pending requests can be rejected"
        );
        registrationRequest storage _request = landRegistrationRequests[
            _requestId
        ];
        _request.approvalDate = block.timestamp;
        _request.status = Status.Rejected;
        _request.comment = _comment;
        rejectedRequestCounter++;
        emit LandRegistrationRequestRejected(
            _request.landId,
            _request.ownerName,
            _request.location,
            _request.area,
            _request.price,
            _request.owner,
            block.timestamp,
            _request.uploadedFiles
        );
    }

    // New Land Transfer Request
    function newLandTransferRequest(
        bytes32 _landId,
        address _to,
        uint256 _price,
        string memory _uploadedFiles
    ) public onlyLandOwnerOrAdmin(_landId) {
        require(
            lands[_landId].owner != _to,
            "Land owner and new owner cannot be same"
        );
        transferRequestCounter++;
        landTransferRequests[transferRequestCounter] = LandTransferRequest(
            _landId,
            lands[_landId].owner,
            _to,
            _price,
            _uploadedFiles,
            0,
            Status.Pending,
            ""
        );
        emit TransferRequest(
            _landId,
            lands[_landId].owner,
            _to,
            _price,
            _uploadedFiles,
            0
        );
    }

    // Approve Land Transfer Request
    function approveLandTransferRequest(uint256 _requestId)
        public
        onlyAdmin
    {
        require(
            landTransferRequests[_requestId].status == Status.Pending,
            "Only pending requests can be approved"
        );
        LandTransferRequest storage _request = landTransferRequests[
            _requestId
        ];
        lands[_request.landId].owner = _request.to;
        _request.approvalDate = block.timestamp;
        _request.status = Status.Approved;
        landTransferHistory[_request.landId].push(_request);
        emit LandTransferRequestApproved(
            _request.landId,
            _request.from,
            _request.to,
            _request.price,
            _request.uploadedFiles,
            block.timestamp
        );
    }

    // Reject Land Transfer Request with a comment
    function rejectLandTransferRequest(
        uint256 _requestId,
        string memory _comment
    ) public onlyAdmin {
        require(
            landTransferRequests[_requestId].status == Status.Pending,
            "Only pending requests can be rejected"
        );
        LandTransferRequest storage _request = landTransferRequests[
            _requestId
        ];
        _request.approvalDate = block.timestamp;
        _request.status = Status.Rejected;
        _request.comment = _comment;
        emit LandTransferRequestRejected(
            _request.landId,
            _request.from,
            _request.to,
            _request.price,
            _request.uploadedFiles,
            block.timestamp
        );
    }

    // ------------------ Getters ------------------

    // Get Land Registration Request
    function getLandRegistrationRequest(uint256 _requestId)
        public
        view
        onlyAdmin()
        returns (
            bytes32 landId,
            string memory ownerName,
            string memory location,
            uint256 area,
            uint256 price,
            address owner,
            uint256 approvalDate,
            string memory uploadedFiles,
            Status status,
            string memory comment
        )
    {
        registrationRequest memory _request = landRegistrationRequests[
            _requestId
        ];
        return (
            _request.landId,
            _request.ownerName,
            _request.location,
            _request.area,
            _request.price,
            _request.owner,
            _request.approvalDate,
            _request.uploadedFiles,
            _request.status,
            _request.comment
        );
    }

    // Get Land Registration Request Status and Comment
    function getLandRegistrationRequestStatusAndComment(uint256 _requestId)
        public
        view
        returns (Status status, string memory comment)
    {
        registrationRequest memory _request = landRegistrationRequests[
            _requestId
        ];
        return (_request.status, _request.comment);
    }

    // Get Land Transfer Request
    function getLandTransferRequest(uint256 _requestId)
        public
        view
        onlyAdmin()
        returns (
            bytes32 landId,
            address from,
            address to,
            uint256 price,
            string memory uploadedFiles,
            uint256 approvalDate,
            Status status,
            string memory comment
        )
    {
        LandTransferRequest memory _request = landTransferRequests[_requestId];
        return (
            _request.landId,
            _request.from,
            _request.to,
            _request.price,
            _request.uploadedFiles,
            _request.approvalDate,
            _request.status,
            _request.comment
        );
    }

    // Get Land Transfer Request Status and Comment
    function getLandTransferRequestStatusAndComment(uint256 _requestId)
        public
        view
        returns (Status status, string memory comment)
    {
        LandTransferRequest memory _request = landTransferRequests[_requestId];
        return (_request.status, _request.comment);
    }

    // Get Land Transfer History
    function getLandTransferHistory(bytes32 _landId)
        public
        view
        returns (LandTransferRequest[] memory)
    {
        return landTransferHistory[_landId];
    }
}
