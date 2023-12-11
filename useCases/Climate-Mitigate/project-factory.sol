// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ProjectContract.sol";
import "./CarbonCreditToken.sol";

contract FactoryContract is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => address) public projectContracts;
    CarbonCreditToken public carbonCreditToken;

    constructor(CarbonCreditToken _carbonCreditToken) {
        _setupRole(ADMIN_ROLE, msg.sender);
        carbonCreditToken = _carbonCreditToken;
    }

    function createProject(
        string memory projectName,
        string memory projectDescription,
        uint256 targetAmount
    ) public onlyRole(ADMIN_ROLE) {
        ProjectContract projectContract = new ProjectContract(
            projectName,
            projectDescription,
            targetAmount
        );
        projectContracts[projectContract.address] = projectContract.address;
        carbonCreditToken.whitelistProjectContract(projectContract.address); // Whitelist new project contract
        emit ProjectCreated(projectContract.address);
    }
}
