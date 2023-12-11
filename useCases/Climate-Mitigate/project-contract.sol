// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./CarbonCreditToken.sol";

contract ProjectContract is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Contribution {
        address contributor;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Contribution) public contributions;

    string public projectName;
    string public projectDescription;
    uint256 public targetAmount;
    uint256 public totalRaised;
    CarbonCreditToken public carbonCreditToken; // Reference to the Carbon Credit Token contract

    event ContributionReceived(address indexed contributor, uint256 amount, uint256 timestamp);

    constructor(
        string memory _projectName,
        string memory _projectDescription,
        uint256 _targetAmount,
        CarbonCreditToken _carbonCreditToken
    ) {
        _setupRole(ADMIN_ROLE, msg.sender);
        projectName = _projectName;
        projectDescription = _projectDescription;
        targetAmount = _targetAmount;
        carbonCreditToken = _carbonCreditToken; // Store reference to Carbon Credit Token contract
    }

    function contribute() public payable {
        require(msg.value > 0, "Contribution amount must be greater than zero");
        totalRaised += msg.value;

        contributions[msg.sender] = Contribution({
            contributor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        });

        emit ContributionReceived(msg.sender, msg.value, block.timestamp);

        // Mint carbon credit tokens based on the contribution amount
        uint256 tokenAmount = msg.value; // Define the conversion rate for tokens based on contribution
        carbonCreditToken.mintTokens(msg.sender, tokenAmount); // Mint tokens directly to user's wallet
    }

    function getProjectDetails()
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256
        )
    {
        return (projectName, projectDescription, targetAmount, totalRaised);
    }

    function getContribution(address contributor)
        public
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        require(contributions[contributor].contributor != address(0), "Contributor not found");
        return (contributions[contributor].contributor, contributions[contributor].amount, contributions[contributor].timestamp);
    }

    function withdrawFunds() public onlyRole(ADMIN_ROLE) {
        // Implement logic to withdraw funds to a designated address
    }
}
