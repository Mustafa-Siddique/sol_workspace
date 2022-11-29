// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayTwentySeven {
    
    mapping(address => uint256) yourBalance;

    function updateBalance(uint256 balance) public {
        yourBalance[msg.sender] = balance; // set this balance to the caller's wallet
    }

    function checkBalance(address _caller) public view returns(uint256) {
        require(msg.sender == _caller, "You are not the owner of the account");
        return yourBalance[msg.sender];
    }

}