// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FreelancePlatform {
    address public owner;
    uint256 public minFee = 50 * 10**18; // 50 USDT minimum budget
    uint256 public smallFee = 10; // 10% commission fee for projects with budget < minFee
    uint256 public largeFee = 12; // 12% commission fee for projects with budget >= minFee
    
    struct Project {
        address payable buyer;
        string description;
        uint256 budget;
        uint256 deadline;
        bool active;
        mapping(address => uint256) bids;
        mapping(address => bool) moderators;
        mapping(uint256 => Milestone) milestones;
        uint256 milestoneCount;
    }
    
    struct Milestone {
        string description;
        uint256 amount;
        bool completed;
    }
    
    mapping(uint256 => Project) public projects;
    uint256 public projectCount;
    
    event ProjectCreated(uint256 projectId, address buyer);
    event ProjectBidded(uint256 projectId, address bidder, uint256 amount);
    event ProjectMilestoneCompleted(uint256 projectId, uint256 milestoneId);
    event ProjectCompleted(uint256 projectId, address seller, uint256 amount);
    event ProjectRejected(uint256 projectId);
    event ModeratorAdded(uint256 projectId, address moderator);
    event ModeratorRemoved(uint256 projectId, address moderator);
    event PaymentReleased(uint256 projectId, address recipient, uint256 amount);
    event PaymentRefunded(uint256 projectId, address recipient, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }
    
    function addModerator(uint256 _projectId, address _moderator) public {
        require(msg.sender == projects[_projectId].buyer, "Only the buyer can add a moderator");
        require(!projects[_projectId].moderators[_moderator], "Moderator is already added");
        
        projects[_projectId].moderators[_moderator] = true;
        
        emit ModeratorAdded(_projectId, _moderator);
    }
    
    function removeModerator(uint256 _projectId, address _moderator) public {
        require(msg.sender == projects[_projectId].buyer, "Only the buyer can remove a moderator");
        require(projects[_projectId].moderators[_moderator], "Moderator is not added");
        
        projects[_projectId].moderators[_moderator] = false;
        
        emit ModeratorRemoved(_projectId, _moderator);
    }
    
    function createProject(string memory _description, uint256 _budget, uint256 _deadline) public payable {
        require(msg.value == _budget, "You must provide the full budget for the project");
        require(_budget >= minFee, "The project budget must be at least 50 USDT");
        require(_deadline > block.timestamp, "The project deadline must be in the future");
        
        projectCount++;
        projects[projectCount] = Project(payable(msg.sender), _description, _budget, _deadline, true, mapping(address => uint256), mapping(address => bool), mapping(uint256 => Milestone), 0);
        
        emit ProjectCreated(projectCount, msg.sender);
    }
    
    function bid(uint256 _projectId) public payable {
        require(projects[_projectId].active, "The project is not active");
        require(msg.value >= projects[_projectId].budget, "Your bid must be at least equal to the project budget");
        require(msg.sender != projects[_projectId].buyer, "The buyer cannot bid on their own project");
        require(projects[_projectId].bids[msg.sender] == 0, "You have already bid on this project");
        projects[_projectId].bids[msg.sender] = msg.value;
    
        emit ProjectBidded(_projectId, msg.sender, msg.value);
    }
    function completeMilestone(uint256 _projectId, uint256 _milestoneId) public {
        require(msg.sender == projects[_projectId].buyer || projects[_projectId].moderators[msg.sender], "Only the buyer or a moderator can complete a milestone");
        require(!projects[_projectId].milestones[_milestoneId].completed, "Milestone is already completed");
        
        projects[_projectId].milestones[_milestoneId].completed = true;
        
        emit ProjectMilestoneCompleted(_projectId, _milestoneId);
    }

    function completeProject(uint256 _projectId) public {
        require(msg.sender == projects[_projectId].buyer || projects[_projectId].moderators[msg.sender], "Only the buyer or a moderator can complete the project");
        require(block.timestamp <= projects[_projectId].deadline, "The project deadline has passed");
        
        uint256 totalBids = 0;
        address payable winner;
        
        for (uint i = 0; i < projectCount; i++) {
            if (projects[_projectId].bids[address(i)] > 0) {
                totalBids += projects[_projectId].bids[address(i)];
                winner = payable(address(i));
            }
        }
        
        uint256 commissionFee = projects[_projectId].budget >= minFee ? (projects[_projectId].budget * largeFee) / 100 : (projects[_projectId].budget * smallFee) / 100;
        uint256 payment = projects[_projectId].budget - commissionFee;
        
        winner.transfer(payment);
        owner.transfer(commissionFee);
        
        projects[_projectId].active = false;
        
        emit ProjectCompleted(_projectId, winner, payment);
    }

    function rejectProject(uint256 _projectId) public {
        require(msg.sender == projects[_projectId].buyer || projects[_projectId].moderators[msg.sender], "Only the buyer or a moderator can reject the project");
        
        for (uint i = 0; i < projectCount; i++) {
            if (projects[_projectId].bids[address(i)] > 0) {
                payable(address(i)).transfer(projects[_projectId].bids[address(i)]);
            }
        }
        
        projects[_projectId].active = false;
        
        emit ProjectRejected(_projectId);
    }

    function releasePayment(uint256 _projectId, address payable _recipient, uint256 _amount) public {
        require(msg.sender == projects[_projectId].buyer || projects[_projectId].moderators[msg.sender], "Only the buyer or a moderator can release payment");
        require(_amount <= address(this).balance, "The contract balance is insufficient");
        
        _recipient.transfer(_amount);
        
        emit PaymentReleased(_projectId, _recipient, _amount);
    }

    function refundPayment(uint256 _projectId, address payable _recipient, uint256 _amount) public {
        require(msg.sender == projects[_projectId].buyer || projects[_projectId].moderators[msg.sender], "Only the buyer or a moderator can refund payment");
        require(_amount <= address(this).balance, "The contract balance is insufficient");
        
        _recipient.transfer(_amount);
        
        emit PaymentRefunded(_projectId, _recipient, _amount);
    }
}