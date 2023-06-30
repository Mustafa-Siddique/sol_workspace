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
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// Name: Save the Dogs
// Symbol: STDC
// Supply: 99,999,999 tokens (fixed supply)

// Token Distribution:

// 15% of tokens allocated to team and investors (vesting period of 9 months)
// 15% of tokens allocated to team and advisors (vesting of 6 months)

// Tax:
// 5% tax on every transaction to an operational wallet

// Token Sale:
// Minimum investment: 50 SDTC
// Maximum investment: 100000 SDTC
// 6-month vesting period for team and advisors (weekly release of vested tokens)

contract SaveTheDogsToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    // Addresses
    address payable public teamAndInvestorsAddress;
    address payable public teamAndAdvisorsAddress;
    address payable public marketingAddress;

    // Token
    string private _name = "Save the Dogs";
    string private _symbol = "STDC";
    uint256 private decimal = 10 ** 18;
    uint256 private _totalSupply = 99999999 * decimal;

    // Investment limits
    uint256 public minInvestment = 500 * decimal;
    uint256 public maxInvestment = 50000000 * decimal;

    // 15% of tokens allocated to team and investors (vesting period of 9 months)
    uint256 public teamAndInvestorsAllocation = _totalSupply.mul(15).div(100);
    // 15% of tokens allocated to team and advisors (vesting of 6 months)
    uint256 public teamAndAdvisorsAllocation = _totalSupply.mul(15).div(100);

    // Vesting
    uint256 public teamAndInvestorsVestingTime = block.timestamp + 9 * 30 days;
    uint256 public teamAndAdvisorsVestingTime = block.timestamp + 6 * 30 days;

    uint256 public teamAndInvestorsClaimed;
    uint256 public teamAndAdvisorsClaimed;

    uint256 public teamAndInvestorsVestingClaimPeriod = 30 days;
    uint256 public teamAndAdvisorsVestingClaimPeriod = 7 days;

    // Mapping
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public whitelist;

    // Constructor
    constructor() {
        teamAndInvestorsAddress = payable(0x0);
        teamAndAdvisorsAddress = payable(0x0);
        marketingAddress = payable(0x0);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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
            sender != address(0),
            "BEP20: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "BEP20: transfer to the zero address"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            _balances[sender] >= amount,
            "BEP20: transfer amount exceeds balance"
        );

        if (sender == teamAndInvestorsAddress) {
            require(
                block.timestamp >= teamAndInvestorsVestingTime,
                "Tokens are locked"
            );
            uint256 availableTokens = getAvailableTokensForTeamAndInvestors();
            require(
                availableTokens >= amount,
                "BEP20: transfer amount exceeds available tokens"
            );
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            teamAndInvestorsClaimed = teamAndInvestorsClaimed.add(amount);
            emit Transfer(sender, recipient, amount);
        } else if (sender == teamAndAdvisorsAddress) {
            require(
                block.timestamp >= teamAndAdvisorsVestingTime,
                "Tokens are locked"
            );
            uint256 availableTokens = getAvailableTokensForTeamAndAdvisors();
            require(
                availableTokens >= amount,
                "BEP20: transfer amount exceeds available tokens"
            );
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            teamAndAdvisorsClaimed = teamAndAdvisorsClaimed.add(amount);
            emit Transfer(sender, recipient, amount);
        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    // Internal function to approve tokens
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(
            owner != address(0),
            "BEP20: approve from the zero address"
        );
        require(
            spender != address(0),
            "BEP20: approve to the zero address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Function to get available tokens for team and investors
    function getAvailableTokensForTeamAndInvestors()
        public
        view
        returns (uint256)
    {
        uint256 currentBalance = balanceOf(teamAndInvestorsAddress);
        uint256 availableTokens = currentBalance.sub(teamAndInvestorsClaimed);
        if (block.timestamp >= teamAndInvestorsVestingTime) {
            return availableTokens;
        } else {
            uint256 totalVestingTime = teamAndInvestorsVestingTime.sub(
                block.timestamp
            );
            uint256 timePassed = totalVestingTime.sub(
                getTeamAndInvestorsVestingTimeLeft()
            );
            uint256 vestedTokens = teamAndInvestorsAllocation.mul(timePassed).div(
                totalVestingTime
            );
            return vestedTokens.sub(teamAndInvestorsClaimed);
        }
    }

    // Function to get available tokens for team and advisors
    function getAvailableTokensForTeamAndAdvisors()
        public
        view
        returns (uint256)
    {
        uint256 currentBalance = balanceOf(teamAndAdvisorsAddress);
        uint256 availableTokens = currentBalance.sub(teamAndAdvisorsClaimed);
        if (block.timestamp >= teamAndAdvisorsVestingTime) {
            return availableTokens;
        } else {
            uint256 totalVestingTime = teamAndAdvisorsVestingTime.sub(
                block.timestamp
            );
            uint256 timePassed = totalVestingTime.sub(
                getTeamAndAdvisorsVestingTimeLeft()
            );
            uint256 vestedTokens = teamAndAdvisorsAllocation.mul(timePassed).div(
                totalVestingTime
            );
            return vestedTokens.sub(teamAndAdvisorsClaimed);
        }
    }

    // Function to get vesting time left
    function getVestingTimeLeft(address _wallet) public view returns (uint256) {
        if (_wallet == teamAndInvestorsAddress) {
            return getTeamAndInvestorsVestingTimeLeft();
        } else if (_wallet == teamAndAdvisorsAddress) {
            return getTeamAndAdvisorsVestingTimeLeft();
        } else {
            return 0;
        }
    }

    // Function to get claim tokens
    function claimTokens() public {
        require(
            msg.sender == teamAndInvestorsAddress ||
                msg.sender == teamAndAdvisorsAddress,
            "You are not allowed to claim tokens"
        );
        if (msg.sender == teamAndInvestorsAddress) {
            require(
                block.timestamp >= teamAndInvestorsVestingTime,
                "Tokens are locked"
            );
            uint256 availableTokens = getAvailableTokensForTeamAndInvestors();
            require(
                availableTokens > 0,
                "There are no available tokens to claim"
            );
            uint256 tokensToClaim = availableTokens.mul(10).div(1000);
            require(
                tokensToClaim > 0,
                "There are no available tokens to claim"
            );
            _balances[teamAndInvestorsAddress] = _balances[teamAndInvestorsAddress].sub(
                tokensToClaim
            );
            _balances[msg.sender] = _balances[msg.sender].add(tokensToClaim);
            teamAndInvestorsClaimed = teamAndInvestorsClaimed.add(tokensToClaim);
            emit Transfer(teamAndInvestorsAddress, msg.sender, tokensToClaim);
        } else if (msg.sender == teamAndAdvisorsAddress) {
            require(
                block.timestamp >= teamAndAdvisorsVestingTime,
                "Tokens are locked"
            );
            uint256 availableTokens = getAvailableTokensForTeamAndAdvisors();
            require(
                availableTokens > 0,
                "There are no available tokens to claim"
            );
            uint256 tokensToClaim = availableTokens.mul(10).div(1000);
            require(
                tokensToClaim > 0,
                "There are no available tokens to claim"
            );
            _balances[teamAndAdvisorsAddress] = _balances[teamAndAdvisorsAddress].sub(
                tokensToClaim
            );
            _balances[msg.sender] = _balances[msg.sender].add(tokensToClaim);
            teamAndAdvisorsClaimed = teamAndAdvisorsClaimed.add(tokensToClaim);
            emit Transfer(teamAndAdvisorsAddress, msg.sender, tokensToClaim);
        }
    }

    // Function to get team and investors vesting time left
    function getTeamAndInvestorsVestingTimeLeft()
        public
        view
        returns (uint256)
    {
        if (block.timestamp >= teamAndInvestorsVestingTime) {
            return 0;
        } else {
            return teamAndInvestorsVestingTime.sub(block.timestamp);
        }
    }

    // Function to get team and advisors vesting time left
    function getTeamAndAdvisorsVestingTimeLeft()
        public
        view
        returns (uint256)
    {
        if (block.timestamp >= teamAndAdvisorsVestingTime) {
            return 0;
        } else {
            return teamAndAdvisorsVestingTime.sub(block.timestamp);
        }
    }

    // Function to set team and investors vesting time
    function setTeamAndInvestorsAddress(address payable _wallet)
        public
        onlyOwner
    {
        teamAndInvestorsAddress = _wallet;
    }

    // Function to set team and advisors vesting time
    function setTeamAndAdvisorsAddress(address payable _wallet)
        public
        onlyOwner
    {
        teamAndAdvisorsAddress = _wallet;
    }

    // Function to set marketing address
    function setMarketingAddress(address payable _wallet) public onlyOwner {
        marketingAddress = _wallet;
    }

    // Function to withdraw marketing funds
    function withdrawMarketingFunds() public onlyOwner {
        require(
            marketingAddress != address(0),
            "Marketing address is not set"
        );
        uint256 balance = address(this).balance;
        marketingAddress.transfer(balance);
    }

    // Function to withdraw BEP20 tokens
    function withdrawBEP20Tokens(address _tokenAddress, uint256 _amount)
        public
        onlyOwner
    {
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
}
