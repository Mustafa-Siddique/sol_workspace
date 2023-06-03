// ERC1155 contract with Airdrop functionality that mints tokens to owner for free where supply is 1111 without any contract import
// NFT URI - ipfs://bafybeifkvqldhedgli2rmueucrxfhke35wkhqtngqossojofvospaqru7m
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC1155, Ownable {
    constructor() ERC1155("ipfs://bafybeifkvqldhedgli2rmueucrxfhke35wkhqtngqossojofvospaqru7m") {}

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    // Only owner can transfer NFTs
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _safeTransferFrom(from, to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
}