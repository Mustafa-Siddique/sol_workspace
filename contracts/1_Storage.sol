// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Houses is Ownable, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter public totalHouses;
    
    uint256 maxHouses;
    string private _currentBaseURI;

    struct House {
        string code;
        uint256 xCoord;
        uint256 yCoord;
    }

    constructor() ERC721("Houses", "Houses") {
        maxHouses = 10000;
    }

    function mintPlayer() payable public 
    {
        require(msg.value >= 0.1 ether, 'Mint price is 0.1 ETH');
        require(totalHouses.current() <= maxHouses, 'Max NFTs reached');
        uint256 newHouseId = totalHouses.current();

        totalHouses.increment();

        _safeMint(msg.sender, newHouseId);
        
    }

        function setBaseURI(string memory baseURI) public onlyOwner
    {
        _currentBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return _currentBaseURI;
    }

    function landCoords(uint) external view returns (uint256 x, uint256 y) {
        
    }


    function fetchBalance() external onlyOwner 
    {
        payable(msg.sender).transfer(address(this).balance);
    }
}   
