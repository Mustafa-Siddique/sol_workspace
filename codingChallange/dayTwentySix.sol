// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayTwentySix {
    
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function returnOwner() public view returns(address) {
        require(msg.sender == owner, "You are not the owner");
        return owner;
    }

}