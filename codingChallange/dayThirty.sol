// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayThirty{
    function concatenate(string memory first, string memory second) public pure returns(string memory) {
        return (string.concat(first,second));
    }
}