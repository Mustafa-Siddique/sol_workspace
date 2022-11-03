//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

contract demo{

    

    // bytes public str = "abc";
    // function pushElement() public {
    //     str.push("d");
    // }
    // function getElement(uint index) public view returns(bytes1){
    //     return str[index];
    // }
    // function getLength() public view returns(uint){
    //     return str.length;
    // }

    // bytes1 b1 = "a";
    // function setBytesArray(bytes1 x) public {
    //     b1 = x;
    // }
    // function getByteValue() public view returns(bytes1){
    //     return b1;
    // }

    // bytes1 public b1;
    // bytes2 public b2;
    // bytes3 public b3;
    // function setter() public {
    //     b1 = "a";
    //     b2 = "ab";
    //     b3 = "abc";
    // }
    // function overRide() public {
    //     b3 = "a";
    // }

    // uint256[] public id;
    // function insert(uint256 item) public{
    //     id.push(item);
    // }
    // function get(uint256 x) public view returns(uint256){
    //     for(uint256 i = 0 ; i < id.length; i++){
    //         if(x == id[i]){
    //             return i;
    //         }
    //     }
    // }
    // function getAll() public view returns(uint256[] memory){
    //     return id;
    // }
    // function length() public view returns(uint256){
    //     return id.length;
    // }
    
    // uint256[] public arr;
    // function pushElement(uint item) public{
    //     arr.push(item);
    // }
    // function popElement() public {
    //     arr.pop();
    // }
    // function len() public view returns(uint){
    //     return arr.length;
    // }

    // function reverseArray(uint256[] memory arr, uint len) public pure returns(uint256[] memory){
    //     uint256 temp;
    //     for(uint256 i = 0; i < len/2; i++){
    //         temp = arr[i];
    //         arr[i] = arr[len - i - 1];
    //         arr[len - i - 1] = temp;
    //     }
    //     return arr;
    // }

    // uint[3] public arr = [10, 20, 30];

    // function insert(uint index, uint element) public {
    //     arr[index] = element;
    // }

    // function len() public view returns(uint){
    //     return arr.length;
    // }

    // function check(bool boolean) public pure returns(string memory){
    //     string memory str;

    //     if ( boolean ){
    //         str = "The value is true";
    //     }
    //     else {
    //         str = "The value is false";
    //     }
    //     return str;
    // }

    // function check(int item) public pure returns(bool){
    //     bool value = true;

    //     if (item < 0) {
    //         return value;
    //     }
    //     else {
    //         value = false;
    //         return value;
    //     }
    // }

    // function checkEvenOdd(int num) public pure returns(string memory){
    //     string memory str;

    //     if(num < 0){
    //         str = "Please enter a positive number";
    //     }
    //     else if (num % 2 == 0) {
    //         str = "Number is even";
    //     }
    //     else if (num % 2 == 1){
    //         str = "Number is odd";
    //     }
    //     return str;
    // }

    // function check(int num) public pure returns(string memory){
    //     string memory str;

    //     if( num > 0 ){
    //         str = "num is greater than 0";
    //     }
    //     else if( num == 0 ){
    //         str = "num is equal to 0";
    //     }
    //     else{
    //         str = "num is less than 0";
    //     }
    //     return str;
    // }

    // string public stateVar = "Yes solidity is fun";

    // function returnStateVariable() public view returns(string memory){
    //     return stateVar;
    // }

    // function returnLocalVariable() public pure returns(string memory){
    //     string memory localVar = "Yes solidity is exciting";
    //     return localVar;
    // }

    string public str = "Hello World!";

    function print() public pure returns(string memory){
        string memory str1 = "Random Text Here";
        return str1;
    }

    function printInt() public pure returns(uint8){
        uint8 output = 25;
        return output;
    }
}