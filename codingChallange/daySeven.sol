// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract daySeven {

    uint256 number = 5324;
    bytes len;

    function demo() public pure returns(uint){
        len = number;
        return len.length;
    }
    
    // function digitSum(int256 n) public pure returns(int256){

    //     int256 result;

    //     for(int256 cycle = 0; cycle <= bytes(n).length - 1; cycle++){
    //         result += n[cycle];
    //     }

    //     return result;
    // }

}