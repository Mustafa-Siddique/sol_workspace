// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event ForceTransfer(
        bytes32 landId,
        address indexed previousOwner,
        address indexed newOwner
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

    // Constructor
    constructor() {
        admin = msg.sender;
        users[msg.sender] = UserTypes.Admin;
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
    function approveLandTransferRequest(uint256 _requestId) public onlyAdmin {
        require(
            landTransferRequests[_requestId].status == Status.Pending,
            "Only pending requests can be approved"
        );
        LandTransferRequest storage _request = landTransferRequests[_requestId];
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
        LandTransferRequest storage _request = landTransferRequests[_requestId];
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
    function getLandRegistrationRequest(
        uint256 _requestId
    )
        public
        view
        onlyAdmin
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
    function getLandRegistrationRequestStatusAndComment(
        uint256 _requestId
    ) public view returns (Status status, string memory comment) {
        registrationRequest memory _request = landRegistrationRequests[
            _requestId
        ];
        return (_request.status, _request.comment);
    }

    // Get Land Transfer Request
    function getLandTransferRequest(
        uint256 _requestId
    )
        public
        view
        onlyAdmin
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
    function getLandTransferRequestStatusAndComment(
        uint256 _requestId
    ) public view returns (Status status, string memory comment) {
        LandTransferRequest memory _request = landTransferRequests[_requestId];
        return (_request.status, _request.comment);
    }

    // Get Land Transfer History
    function getLandTransferHistory(
        bytes32 _landId
    ) public view returns (LandTransferRequest[] memory) {
        return landTransferHistory[_landId];
    }

    // Get all lands of a land owner
    function getLandIdsOfLandOwner(
        address _landOwner
    ) public view returns (bytes32[] memory) {
        require(
            msg.sender == _landOwner || msg.sender == admin,
            "Unauthorized"
        );
        return landOwners[_landOwner].landIds;
    }

    // Get land owner details with registration request
    function getOwnerWithRegistrationRequest(
        address _landOwner,
        uint256 _requestId
    ) public view returns (LandOwner memory, registrationRequest memory) {
        return (landOwners[_landOwner], landRegistrationRequests[_requestId]);
    }

    // Get land owner details
    function getOwner(
        address _landOwner
    ) public view returns (LandOwner memory) {
        require(
            msg.sender == _landOwner || msg.sender == admin,
            "Unauthorized"
        );
        return landOwners[_landOwner];
    }

    // Get land details
    function getLand(bytes32 _landId) public view returns (Land memory) {
        return lands[_landId];
    }

    // Get user type
    function getUserType(address _user) public view returns (UserTypes) {
        return users[_user];
    }

    // Get land registration request count
    function getLandRegistrationRequestCount() public view returns (uint256) {
        return registrationRequestCounter;
    }

    // Get land transfer request count
    function getLandTransferRequestCount() public view returns (uint256) {
        return transferRequestCounter;
    }

    // Get rejected land registration request count
    function getRejectedLandRegistrationRequestCount()
        public
        view
        returns (uint256)
    {
        return rejectedRequestCounter;
    }

    // Get land count of a land owner
    function getLandCountOfLandOwner(
        address _landOwner
    ) public view returns (uint256) {
        require(
            msg.sender == _landOwner || msg.sender == admin,
            "Unauthorized"
        );
        return landOwners[_landOwner].landCount;
    }

    // Get land count
    function getLandCount() public view returns (uint256) {
        return landCounter;
    }

    // Get only pending land registration requests
    function getPendingLandRegistrationRequests()
        public
        view
        onlyAdmin
        returns (registrationRequest[] memory)
    {
        registrationRequest[] memory _requests = new registrationRequest[](
            registrationRequestCounter - rejectedRequestCounter
        );
        uint256 _index = 0;
        for (uint256 i = 1; i <= registrationRequestCounter; i++) {
            if (
                landRegistrationRequests[i].status == Status.Pending &&
                landRegistrationRequests[i].approvalDate == 0
            ) {
                _requests[_index] = landRegistrationRequests[i];
                _index++;
            }
        }
        return _requests;
    }

    // Get only pending land transfer requests
    function getPendingLandTransferRequests()
        public
        view
        onlyAdmin
        returns (LandTransferRequest[] memory)
    {
        LandTransferRequest[] memory _requests = new LandTransferRequest[](
            transferRequestCounter
        );
        uint256 _index = 0;
        for (uint256 i = 1; i <= transferRequestCounter; i++) {
            if (
                landTransferRequests[i].status == Status.Pending &&
                landTransferRequests[i].approvalDate == 0
            ) {
                _requests[_index] = landTransferRequests[i];
                _index++;
            }
        }
        return _requests;
    }

    // Get admin address
    function getAdmin() public view returns (address) {
        return admin;
    }

    // ------------------ Admin Controls ------------------

    // Transfer ownership of contract to a new admin
    function transferOwnership(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
        emit OwnershipTransferred(admin, _newAdmin);
    }

    // Renounce ownership of contract
    function renounceOwnership() public onlyAdmin {
        admin = address(0);
        emit OwnershipTransferred(admin, address(0));
    }

    // Unregister a land owner
    function unregisterLandOwner(address _landOwner) public onlyAdmin {
        require(
            users[_landOwner] == UserTypes.LandOwner,
            "Only land owners can be unregistered"
        );
        users[_landOwner] = UserTypes.Unregistered;
        delete landOwners[_landOwner];
    }

    // Force transfer land ownership back to previous owner
    function forceTransferLandOwnership(
        bytes32 _landId,
        address _previousOwner
    ) public onlyAdmin {
        require(
            lands[_landId].owner != _previousOwner,
            "Land owner and previous owner cannot be same"
        );
        lands[_landId].owner = _previousOwner;
        emit ForceTransfer(_landId, _previousOwner, lands[_landId].owner);
    }

}
