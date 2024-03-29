// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Context {
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract SaveTheDogsToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    // Addresses
    address payable public marketingAddress;
    address payable public operationalWallet;

    // Launch date
    uint256 private marketActiveAt;
    bool public marketActive = false;

    // Token
    string private _name = "Save the Dogs";
    string private _symbol = "STDC";
    uint256 private decimal = 10 ** 18;
    uint256 private _totalSupply = 99999999 * decimal;

    // Investment limits
    uint256 public minInvestment = 500 * decimal;
    uint256 public maxInvestment = 50000000 * decimal;

    // 5% tax on every transaction to an operational wallet
    uint256 public tax = 5;
    uint256 private taxDivisor = 100;

    // Mapping
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromTax;

    // Constructor
    constructor() {
        marketingAddress = payable(0x0);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        isExcludedFromTax[address(this)] = true;
        isExcludedFromTax[owner()] = true;
        isExcludedFromTax[marketingAddress] = true;
        isExcludedFromTax[operationalWallet] = true;
    }

    // Function to get token name
    function name() public view returns (string memory) {
        return _name;
    }

    // Function to get token symbol
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Function to get token decimals
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    // Function to get total supply
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // Function to get token balance of an address
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Function to transfer tokens
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Function to get owner
    function getOwner() external view override returns (address) {
        return owner();
    }

    // Function to get allowance
    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Function to approve tokens
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // Function to transfer tokens from an address to another address
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(
            _allowances[sender][_msgSender()] >= amount,
            "BEP20: transfer amount exceeds allowance"
        );
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    // Function to increase allowance
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    // Function to decrease allowance
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    // Internal function to transfer tokens
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            sender != address(0) && recipient != address(0),
            "BEP20: transfer from or to the zero address"
        );
        require(
            _balances[sender] >= amount,
            "BEP20: transfer amount exceeds balance"
        );
        if (
            sender != owner() &&
            recipient != owner() &&
            sender != address(this) &&
            recipient != address(this) &&
            sender != marketingAddress &&
            recipient != marketingAddress &&
            sender != operationalWallet &&
            recipient != operationalWallet
        ) {
            require(
                amount > minInvestment,
                "Amount is less than min investment"
            );
            require(marketActive, "Market is not active");
            require(
                block.timestamp > marketActiveAt + 5,
                "You cannot buy at launch"
            );
            require(
                amount < maxInvestment,
                "Amount is more than max investment"
            );
            uint256 taxAmount = amount.mul(tax).div(taxDivisor);
            uint256 tokensToTransfer = amount.sub(taxAmount);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tokensToTransfer);
            _balances[operationalWallet] = _balances[operationalWallet].add(
                taxAmount
            );
            emit Transfer(sender, recipient, tokensToTransfer);
            emit Transfer(sender, operationalWallet, taxAmount);
        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    // Internal function to approve tokens
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Function to set marketing address
    function setMarketingAddress(address payable _wallet) public onlyOwner {
        marketingAddress = _wallet;
    }

    // Function to set operational wallet
    function setOperationalWallet(address payable _wallet) public onlyOwner {
        operationalWallet = _wallet;
    }

    // Function to withdraw BNB funds
    function withdrawBNB() public onlyOwner {
        marketingAddress.transfer(address(this).balance);
    }

    // Function to withdraw BEP20 tokens
    function withdrawBEP20Tokens(
        address _tokenAddress,
        uint256 _amount
    ) public onlyOwner {
        IBEP20 token = IBEP20(_tokenAddress);
        require(
            _amount <= token.balanceOf(address(this)),
            "Amount exceeds available tokens"
        );
        token.transfer(msg.sender, _amount);
    }

    // Function to set min investment
    function setMinInvestment(uint256 _amount) public onlyOwner {
        minInvestment = _amount;
    }

    // Function to set max investment
    function setMaxInvestment(uint256 _amount) public onlyOwner {
        maxInvestment = _amount;
    }

    // Function to burn tokens
    function burn(uint256 _amount) public onlyOwner {
        require(
            _balances[msg.sender] >= _amount,
            "BEP20: burn amount exceeds balance"
        );
        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

    // Function to exclude address from tax
    function excludeFromTax(address _address) public onlyOwner {
        isExcludedFromTax[_address] = true;
    }

    // Function to include address in tax
    function includeInTax(address _address) public onlyOwner {
        isExcludedFromTax[_address] = false;
    }

    // Function to set tax
    function setTax(uint256 _tax) public onlyOwner {
        tax = _tax;
    }

    // Function to set market launch date
    function setMarketActiveTime(uint256 _marketActiveAt) public onlyOwner {
        marketActiveAt = _marketActiveAt;
    }

    // Function to set market active
    function setMarketActive(bool _marketActive) public onlyOwner {
        marketActive = _marketActive;
    }
}
