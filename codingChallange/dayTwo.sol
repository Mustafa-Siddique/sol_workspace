// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayTwo{

    uint256 age = 58; //State Varialble

    function getState() public view returns(uint256) {
        return age;
    }

    function getLocal() public pure returns(string memory){
        string memory user = "Mustafa Siddique"; // Local Variable
        return user;
    }
}