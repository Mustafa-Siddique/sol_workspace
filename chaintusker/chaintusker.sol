// Created by: Cadilacs (https://cadillacs.in)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./reentrancyGuard.sol";

// Enum user type
enum UserType {
    UNREGISTERED,
    SUPER_ADMIN,
    MODERATOR
}

struct Project {
    address payable buyer;
    address payable seller;
    address payable offeredSeller;
    string description;
    bytes32 projectHash;
    uint256 totalBudget;
    uint256 remainingBudget;
    uint256 startedAt;
    uint256 deadline;
    bool active;
    uint256[] milestoneRewards;
    bool[] milestoneCompleted;
}

contract Chaintusker is ReentrancyGuard {
    // Contract owner and dev address
    address public owner;
    address payable public devWallet;
    address payable public marketingWallet;

    // Fee for each project
    uint256 public minFee = 20 * 10 ** 18; // 20 USDT minimum budget
    uint256 public minDevFee = 3; // 3% dev fee
    uint256 public minMarketingFee = 7; // 7% marketing fee
    uint256 public maxDevFee = 4; // 4% dev fee
    uint256 public maxMarketingFee = 8; // 8% marketing fee

    // mapping project id to Project struct where project id is the object id in the database
    mapping(bytes12 => Project) public projects;
    mapping(address => UserType) public userTypes;

    // Store all projects ids
    bytes12[] allProjects;

    uint256 public moderatorCount = 0;

    // Events
    event ProjectCreated(bytes12 projectId, address buyer);
    event ProjectOffered(bytes12 projectId, address seller);
    event ProjectAccepted(bytes12 projectId, address seller);
    event ProjectRejected(bytes12 projectId);
    event ProjectMilestoneCompleted(bytes12 projectId, uint256 index);
    event ProjectMilestoneRequested(bytes12 projectId, uint256 index);
    event ProjectProposalCreated(
        bytes12 projectId,
        string description,
        uint256 deadline
    );
    event ModeratorAdded(address moderator);
    event ModeratorRemoved(address moderator);
    event ProjectDisputeRaised(bytes12 projectId);
    event PaymentReleased(bytes12 projectId, address recipient, uint256 amount);
    event PaymentRefunded(bytes12 projectId, address recipient, uint256 amount);

    constructor() {
        owner = msg.sender;
        userTypes[msg.sender] = UserType.SUPER_ADMIN;
    }

    // Modifiers
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can perform this action"
        );
        _;
    }
    modifier onlyModerator() {
        require(
            userTypes[msg.sender] == UserType.MODERATOR,
            "Only a moderator can perform this action"
        );
        _;
    }
    modifier onlyBuyer(bytes12 _projectId) {
        require(
            msg.sender == projects[_projectId].buyer,
            "Only the buyer can perform this action"
        );
        _;
    }
    modifier onlySeller(bytes12 _projectId) {
        require(
            msg.sender == projects[_projectId].seller,
            "Only the seller can perform this action"
        );
        _;
    }
    modifier projectExists(bytes12 _projectId) {
        require(
            projects[_projectId].buyer != address(0),
            "Project does not exist"
        );
        _;
    }
    modifier onlyOfferedSeller(bytes12 _projectId) {
        require(
            msg.sender == projects[_projectId].offeredSeller,
            "Only the offered seller can perform this action"
        );
        _;
    }
    modifier onlyBuyerOrOfferedSeller(bytes12 _projectId) {
        require(
            msg.sender == projects[_projectId].buyer ||
                msg.sender == projects[_projectId].offeredSeller,
            "Only the buyer or the offered seller can perform this action"
        );
        _;
    }
    modifier isAssigned(bytes12 _projectId) {
        require(
            projects[_projectId].seller != address(0),
            "The project has not been offered yet"
        );
        _;
    }
    modifier onlyBuyerOrSeller(bytes12 _projectId) {
        require(
            msg.sender == projects[_projectId].buyer ||
                msg.sender == projects[_projectId].seller,
            "Only the buyer or the seller can perform this action"
        );
        _;
    }

    // Create a new project
    function createProject(
        bytes12 _projectId,
        string memory _description,
        bytes32 _projectHash
    ) public {
        require(_projectId.length > 0, "Project ID is required");
        require(bytes(_description).length > 0, "Description is required");
        require(_projectHash.length > 0, "Project hash is required");

        projects[_projectId].buyer = payable(msg.sender);
        projects[_projectId].description = _description;
        projects[_projectId].projectHash = _projectHash;
        projects[_projectId].startedAt = block.timestamp;
        projects[_projectId].active = true;

        allProjects.push(_projectId);
        emit ProjectCreated(_projectId, msg.sender);
    }

    // Offer a project to a seller
    function offerProject(
        bytes12 _projectId,
        address payable _seller,
        uint256 deadline,
        uint256[] memory _milestoneRewards
    )
        public
        payable
        onlyBuyer(_projectId)
        nonReentrant
        projectExists(_projectId)
    {
        require(
            projects[_projectId].buyer != _seller,
            "The buyer cannot be the seller"
        );
        require(
            projects[_projectId].seller == address(0),
            "The project has already been offered"
        );
        require(_seller != address(0), "Seller address can't be null");
        require(
            _milestoneRewards.length > 0,
            "Milestone rewards cannot be empty"
        );
        require(deadline > block.timestamp, "Deadline cannot be in the past");

        uint256 _budget = 0;
        for (uint256 i = 0; i < _milestoneRewards.length; i++) {
            projects[_projectId].milestoneCompleted.push(false);
            _budget += _milestoneRewards[i];
        }
        
        require(msg.value == _budget, "Wrong amount submitted!");

        projects[_projectId].totalBudget = _budget;
        projects[_projectId].remainingBudget = _budget;
        projects[_projectId].deadline = deadline;
        projects[_projectId].milestoneRewards = _milestoneRewards;
        projects[_projectId].offeredSeller = _seller;
        emit ProjectOffered(_projectId, _seller);
    }

    // Accept a project offer
    function acceptProjectOffer(
        bytes12 _projectId
    ) public payable onlyOfferedSeller(_projectId) projectExists(_projectId) {
        require(
            projects[_projectId].offeredSeller != address(0),
            "The project has not been offered"
        );
        require(
            projects[_projectId].seller == address(0),
            "The project has already been accepted"
        );
        projects[_projectId].seller = payable(msg.sender);
        delete projects[_projectId].offeredSeller;
        emit ProjectAccepted(_projectId, msg.sender);
    }

    // Reject a project offer and return the funds to the buyer
    function rejectProjectOffer(
        bytes12 _projectId
    )
        public
        payable
        nonReentrant
        onlyBuyerOrOfferedSeller(_projectId)
        projectExists(_projectId)
    {
        require(
            projects[_projectId].offeredSeller != address(0),
            "The project has not been offered"
        );
        require(
            projects[_projectId].seller == address(0),
            "The project has already been accepted"
        );

        projects[_projectId].buyer.transfer(
            projects[_projectId].remainingBudget
        );
        delete projects[_projectId].offeredSeller;
        emit ProjectRejected(_projectId);
    }

    // Milestone completion and release milestone payment
    // If the total budget is under minFee, send minDevFee to dev wallet and minMarketingFee to marketing wallet before sending the milestone payment
    // If the total budget is over minFee, send maxDevFee to dev wallet and maxMarketingFee to marketing wallet before sending the milestone payment
    function milestoneCompleted(
        bytes12 _projectId,
        uint256 _projectIndex
    )
        public
        payable
        nonReentrant
        onlyBuyer(_projectId)
        projectExists(_projectId)
        isAssigned(_projectId)
    {
        require(
            projects[_projectId].milestoneCompleted[_projectIndex] == false,
            "Milestone already completed"
        );
        require(
            projects[_projectId].remainingBudget >=
                projects[_projectId].milestoneRewards[_projectIndex],
            "Not enough funds to release payment"
        );
        require(
            msg.value == projects[_projectId].milestoneRewards[_projectIndex],
            "Wrong amount submitted!"
        );

        projects[_projectId].remainingBudget -= projects[_projectId]
            .milestoneRewards[_projectIndex];
        projects[_projectId].milestoneCompleted[_projectIndex] = true;

        if (projects[_projectId].totalBudget < minFee) {
            // Calculate the required amount to send to the dev, marketing wallets and the remaining amount to the seller
            uint256 devFee = (projects[_projectId].milestoneRewards[
                _projectIndex
            ] * minDevFee) / 100;
            uint256 marketingFee = (projects[_projectId].milestoneRewards[
                _projectIndex
            ] * minMarketingFee) / 100;
            uint256 remainingAmount = projects[_projectId].milestoneRewards[
                _projectIndex
            ] -
                devFee -
                marketingFee;
            // Send the required amount to the dev and marketing wallets
            devWallet.transfer(devFee);
            marketingWallet.transfer(marketingFee);
            // Send the remaining amount to the seller
            projects[_projectId].seller.transfer(remainingAmount);
        } else {
            // Calculate the required amount to send to the dev, marketing wallets and the remaining amount to the seller
            uint256 devFee = (projects[_projectId].milestoneRewards[
                _projectIndex
            ] * maxDevFee) / 100;
            uint256 marketingFee = (projects[_projectId].milestoneRewards[
                _projectIndex
            ] * maxMarketingFee) / 100;
            uint256 remainingAmount = projects[_projectId].milestoneRewards[
                _projectIndex
            ] -
                devFee -
                marketingFee;
            // Send the required amount to the dev and marketing wallets
            devWallet.transfer(devFee);
            marketingWallet.transfer(marketingFee);
            // Send the remaining amount to the seller
            projects[_projectId].seller.transfer(remainingAmount);
        }

        // If this is the last milestone, mark the project as completed
        if (_projectIndex == projects[_projectId].milestoneRewards.length - 1) {
            projects[_projectId].active = false;
        }
        emit ProjectMilestoneCompleted(_projectId, _projectIndex);
    }

    // Request a milestone payment
    function requestMilestonePayment(
        bytes12 _projectId,
        uint256 index
    ) public projectExists(_projectId) isAssigned(_projectId) {
        require(
            projects[_projectId].milestoneCompleted[index] == true,
            "Milestone is not completed"
        );
        require(
            projects[_projectId].remainingBudget >=
                projects[_projectId].milestoneRewards[index],
            "Not enough funds to release payment"
        );
        require(
            msg.sender == projects[_projectId].seller,
            "Only the seller can request payment"
        );
        require(projects[_projectId].active == true, "Project is not active");

        emit ProjectMilestoneRequested(_projectId, index);
    }

    // ----------------- GETTERS -----------------
    // Get all projects
    function getAllProjects() public view returns (bytes12[] memory) {
        return allProjects;
    }

    // Get projects by ID
    function getProject(
        bytes12 _projectId
    ) public view returns (Project memory) {
        return projects[_projectId];
    }

    // Get project milestones
    function getProjectMilestones(
        bytes12 _projectId
    ) public view returns (uint256[] memory, bool[] memory) {
        return (
            projects[_projectId].milestoneRewards,
            projects[_projectId].milestoneCompleted
        );
    }

    // Get project dates
    function getProjectDates(
        bytes12 _projectId
    ) public view returns (uint256, uint256, uint256) {
        return (
            projects[_projectId].startedAt,
            projects[_projectId].deadline,
            projects[_projectId].remainingBudget
        );
    }

    // Get Project Seller
    function getProjectSeller(
        bytes12 _projectId
    ) public view returns (address payable) {
        return projects[_projectId].seller;
    }

    // Get Project Hash
    function getProjectHash(bytes12 _projectId) public view returns (bytes32) {
        return projects[_projectId].projectHash;
    }

    // ----------------- CHANGES -----------------
    // Create a proposal to change the Project deadline, description or project hash
    function createProposal(
        bytes12 _projectId,
        string memory _description,
        uint256 _deadline,
        bytes32 _projectHash
    ) public onlyBuyer(_projectId) projectExists(_projectId) {
        require(
            projects[_projectId].deadline > block.timestamp,
            "The project deadline has passed"
        );
        require(
            projects[_projectId].remainingBudget > 0,
            "The project has been completed"
        );
        require(_projectHash.length > 0, "Project hash cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(projects[_projectId].active == true, "Project is not active");

        projects[_projectId].description = _description;
        projects[_projectId].deadline = _deadline;
        projects[_projectId].projectHash = _projectHash;

        emit ProjectProposalCreated(_projectId, _description, _deadline);
    }

    // Raising a dispute from buyer or seller to the moderator
    // If the dispute is raised then the Project budget is frozen and the moderator will decide the outcome from release or refund functions
    function raiseDispute(
        bytes12 _projectId
    )
        public
        projectExists(_projectId)
        isAssigned(_projectId)
        onlyBuyerOrSeller(_projectId)
    {
        require(
            projects[_projectId].remainingBudget > 0,
            "The project has been completed"
        );
        require(projects[_projectId].active == true, "Project is not active");

        projects[_projectId].active = false;

        emit ProjectDisputeRaised(_projectId);
    }

    // ----------------- MODERATOR -----------------

    // Release payment to the seller
    function releasePayment(
        bytes12 _projectId,
        uint256 _milestoneIndex
    )
        public
        payable
        nonReentrant
        onlyModerator
        projectExists(_projectId)
        isAssigned(_projectId)
    {
        require(
            projects[_projectId].milestoneCompleted[_milestoneIndex] != true,
            "Milestone is already completed"
        );
        require(
            projects[_projectId].remainingBudget >=
                projects[_projectId].milestoneRewards[_milestoneIndex],
            "Not enough funds to release payment"
        );
        require(projects[_projectId].active != true, "Dispute is not raised");

        projects[_projectId].remainingBudget -= projects[_projectId]
            .milestoneRewards[_milestoneIndex];
        projects[_projectId].milestoneCompleted[_milestoneIndex] = true;

        projects[_projectId].seller.transfer(
            projects[_projectId].milestoneRewards[_milestoneIndex]
        );

        emit PaymentReleased(
            _projectId,
            projects[_projectId].seller,
            projects[_projectId].milestoneRewards[_milestoneIndex]
        );
    }

    // Refund payment to the buyer
    function refundPayment(
        bytes12 _projectId
    )
        public
        payable
        nonReentrant
        onlyModerator
        projectExists(_projectId)
        isAssigned(_projectId)
    {
        require(
            projects[_projectId].remainingBudget > 0,
            "Project has been completed"
        );
        require(projects[_projectId].active != true, "Dispute is not raised");

        uint256 remainingBudget = projects[_projectId].remainingBudget;
        projects[_projectId].remainingBudget = 0;

        projects[_projectId].buyer.transfer(remainingBudget);

        emit PaymentRefunded(
            _projectId,
            projects[_projectId].buyer,
            remainingBudget
        );
    }

    //  ----------------- TAX & Wallets -----------------
    // Set the tax percentage
    function setMinDevFee(uint256 _minDevFee) public onlyOwner {
        require(_minDevFee > 0, "Tax cannot be 0");
        minDevFee = _minDevFee;
    }

    function setMaxDevFee(uint256 _maxDevFee) public onlyOwner {
        require(_maxDevFee > 0, "Tax cannot be 0");
        maxDevFee = _maxDevFee;
    }

    function setMinMarketFee(uint256 _minMarketFee) public onlyOwner {
        require(_minMarketFee > 0, "Tax cannot be 0");
        minMarketingFee = _minMarketFee;
    }

    function setMaxMarketFee(uint256 _maxMarketFee) public onlyOwner {
        require(_maxMarketFee > 0, "Tax cannot be 0");
        maxMarketingFee = _maxMarketFee;
    }

    // Set the wallet addresses
    function setDevWallet(address payable _devWallet) public onlyOwner {
        require(_devWallet != address(0), "Wallet cannot be 0x0");
        devWallet = _devWallet;
    }

    function setMarketingWallet(
        address payable _marketingWallet
    ) public onlyOwner {
        require(_marketingWallet != address(0), "Wallet cannot be 0x0");
        marketingWallet = _marketingWallet;
    }

    // add a new moderator
    function addModerator(address _moderator) public onlyOwner {
        require(_moderator != address(0), "Moderator cannot be 0x0");
        userTypes[_moderator] = UserType.MODERATOR;
        moderatorCount++;
        emit ModeratorAdded(_moderator);
    }

    // remove a moderator
    function removeModerator(address _moderator) public onlyOwner {
        require(_moderator != address(0), "Moderator cannot be 0x0");
        userTypes[_moderator] = UserType.UNREGISTERED;
        moderatorCount--;
        emit ModeratorRemoved(_moderator);
    }

    // Transfer ownership of the contract
    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Owner cannot be 0x0");
        owner = _newOwner;
    }
}
