// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MyERC1155 {
    // Total supply of NFTs
    uint256 public constant TOTAL_SUPPLY = 1111;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from token ID to token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Mapping from account to whether it has an NFT
    mapping(address => bool) private _hasNFT;

    // Owner of the contract
    address public _owner;

    // Constructor
    constructor() {
        _owner = msg.sender;
        _mint(msg.sender, 0, TOTAL_SUPPLY);
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    // Balance function
    function balanceOf(address account, uint256 id) external view returns (uint256) {
        return _balances[id][account];
    }

    // Set approval function
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
    }

    // Approval function
    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    // Transfer function
    function transferNFT(address recipient, uint256 id) external onlyOwner {
        require(recipient != address(0), "Transfer to the zero address");
        require(!_hasNFT[recipient], "Recipient already has an NFT");

        _transfer(msg.sender, recipient, id);
        _hasNFT[recipient] = true;
    }

    // Mint function
    function mint(address account, uint256 id, uint256 amount) external onlyOwner {
        require(account != address(0), "Mint to the zero address");

        if (id == 0) {
            require(!_hasNFT[account], "Account already has an NFT");
            _hasNFT[account] = true;
        }

        _mint(account, id, amount);
    }

    // Update total supply function of NFTs id onlyOwner
    function updateTotalSupply(uint256 id, uint256 newTotalSupply) external onlyOwner {
        require(newTotalSupply > _balances[id][msg.sender], "New total supply must be greater than current balance");

        _mint(msg.sender, id, newTotalSupply - _balances[id][msg.sender]);
    }

    // Burn function
    function burn(address account, uint256 id, uint256 amount) external onlyOwner {
        require(account != address(0), "Burn from the zero address");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        _balances[id][account] = accountBalance - amount;
    }

    // URI functions
    function setURI(uint256 id, string memory newURI) external onlyOwner {
        _tokenURIs[id] = newURI;
    }

    function uri(uint256 id) external view returns (string memory) {
        return _tokenURIs[id];
    }

    // Owner functions
    function owner() external view returns (address) {
        return _owner;
    }

    // Transfer ownership function
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Transfer ownership to the zero address");
        _owner = newOwner;
    }

    // Renounce ownership function
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
    }

    // Internal functions
    function _transfer(address from, address to, uint256 id) internal {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(!_hasNFT[to], "Recipient already has an NFT");

        _balances[id][from] = 0;
        _balances[id][to] = 1;
        _hasNFT[from] = false;
        _hasNFT[to] = true;
    }

    function _mint(address account, uint256 id, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        _balances[id][account] += amount;
    }

    // Check if account has an NFT
    function hasNFT(address account) external view returns (bool) {
        return _hasNFT[account];
    }
}