// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: immigrants
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract Immigrant is ERC721Community {
    constructor() ERC721Community("immigrants", "Immigrant", 10000, 2, START_FROM_ONE, "ipfs://bafybeieofpy37lbg2mzjhsgmymhshrj5m7xesahk23d4da3dolewegy6iq/",
                                  MintConfig(0.01 ether, 3, 3, 0, 0x0e10dCF27b681533aC67CE64a1546B8D8452a94B, false, false, false)) {}
}