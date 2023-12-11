// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CarbonCreditToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => bool) public whitelistedProjectContracts;

    event TokenMinted(address indexed recipient, uint256 amount);

    constructor() ERC20("CarbonCredit", "CC") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mintTokens(address recipient, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(whitelistedProjectContracts[msg.sender], "Project contract not whitelisted");
        _mint(recipient, amount);
        emit TokenMinted(recipient, amount);
    }

    function whitelistProjectContract(address projectContractAddress) public onlyRole(ADMIN_ROLE) {
        whitelistedProjectContracts[projectContractAddress] = true;
    }

    function isWhitelistedProjectContract(address projectContractAddress) public view returns (bool) {
        return whitelistedProjectContracts[projectContractAddress];
    }
}
