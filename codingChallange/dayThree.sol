// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayThree{

    uint256 stateVar;

    // a setter function for setting value to state variable with an argument
    function set(uint256 arg) public {
        stateVar = arg;
    }

    // a getter function for getting value of state variable
    function get() public view returns(uint256){
        return stateVar;
    }

}