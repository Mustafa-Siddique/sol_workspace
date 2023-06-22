// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SaveTheDogsToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    uint256 private constant MAX_SUPPLY = 99999999 * 10 ** 18; // 99,999,999 tokens
    uint256 private constant ICO_TOKENS = MAX_SUPPLY * 40 / 100; // 40% of tokens for sale to the general public
    uint256 private constant MARKETING_TOKENS = MAX_SUPPLY * 20 / 100; // 20% of tokens for marketing/community
    uint256 private constant CHARITY_TOKENS = MAX_SUPPLY * 10 / 100; // 10% of tokens for charity

    uint256 private constant TEAM_INVESTOR_TOKENS = MAX_SUPPLY * 30 / 100; // 30% of tokens for team and investors
    uint256 private constant TEAM_VESTING_PERIOD = 9 * 30 days; // Vesting period of 9 months
    uint256 private constant TEAM_RELEASE_INTERVAL = TEAM_VESTING_PERIOD / 4; // Weekly release for team and investors
    uint256 private constant TEAM_INITIAL_LOCKUP = 3 months; // 3-month lock-up period for investors
    uint256 private constant TEAM_LOCKUP_RELEASE_AMOUNT = TEAM_INVESTOR_TOKENS / 1000; // Can sell up to 0.1% of total supply

    uint256 private constant LP_AMOUNT = 100000 * 10 ** 6; // 100,000 USDC equivalent for liquidity pool

    uint256 private tokenPrice = 2; // $0.002 per token
    uint256 private constant MIN_INVESTMENT = 100; // Minimum investment: $100
    uint256 private constant MAX_INVESTMENT = 100000; // Maximum investment: $100,000

    address private teamWallet;
    address private marketingWallet;
    address private charityWallet;
    address private lpWallet;

    enum Phase {
        Phase1,
        Phase2,
        Phase3,
        Phase4,
        Phase5,
        Phase6,
        Phase7
    }

    Phase private currentPhase;
    uint256 private constant PHASE_DURATION = 3 months; // Duration of each phase
    uint256 private constant PHASE_TOKENS = ICO_TOKENS / 7; // Token allocation per phase

    constructor(
        address _teamWallet,
        address _marketingWallet,
        address _charityWallet,
        address _lpWallet
    ) {
        name = "Save the Dogs";
        symbol = "STDC";
        totalSupply = MAX_SUPPLY;

        teamWallet = _teamWallet;
        marketingWallet = _marketingWallet;
        charityWallet = _charityWallet;
        lpWallet = _lpWallet;

        balances[_teamWallet] = TEAM_INVESTOR_TOKENS;
        balances[_marketingWallet] = MARKETING_TOKENS;
        balances[_charityWallet] = CHARITY_TOKENS;
        balances[lpWallet] = LP_AMOUNT;

        emit Transfer(address(0), _teamWallet, TEAM_INVESTOR_TOKENS);
        emit Transfer(address(0), _marketingWallet, MARKETING_TOKENS);
        emit Transfer(address(0), _charityWallet, CHARITY_TOKENS);
        emit Transfer(address(0), lpWallet, LP_AMOUNT);

        currentPhase = Phase.Phase1;
    }

    modifier onlyDuringPhase(Phase phase) {
        require(currentPhase == phase, "Invalid phase");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == teamWallet, "Unauthorized");
        _;
    }

    function buyTokens() external payable {
        require(msg.value >= MIN_INVESTMENT, "Below minimum investment");
        require(msg.value <= MAX_INVESTMENT, "Exceeds maximum investment");

        uint256 tokensToBuy = msg.value / tokenPrice;
        require(tokensToBuy <= getPhaseTokensRemaining(), "Insufficient tokens for sale in this phase");

        balances[msg.sender] += tokensToBuy;
        balances[teamWallet] -= tokensToBuy;

        emit Transfer(teamWallet, msg.sender, tokensToBuy);

        if (currentPhase == Phase.Phase7 && tokensToBuy == getPhaseTokensRemaining()) {
            // Move to next phase if all tokens are sold in the current phase
            currentPhase = Phase(uint256(currentPhase) + 1);
        }

        if (tokensToBuy > 0) {
            uint256 ethAmount = tokensToBuy * tokenPrice;
            if (msg.value > ethAmount) {
                // Refund any excess ether sent
                payable(msg.sender).transfer(msg.value - ethAmount);
            }
        }
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Insufficient allowance");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        emit Approval(sender, msg.sender, allowances[sender][msg.sender]);
        return true;
    }

    function getPhaseTokensRemaining() public view returns (uint256) {
        return PHASE_TOKENS - getTotalTokensSoldInPhase(currentPhase);
    }

    function getTotalTokensSoldInPhase(Phase phase) private view returns (uint256) {
        uint256 phaseIndex = uint256(phase);
        if (phaseIndex == 0) {
            return 0;
        } else {
            return ICO_TOKENS - (getPhaseTokensRemaining() * (7 - phaseIndex));
        }
    }

    function unlockTeamTokens() external onlyTeam {
        require(block.timestamp >= TEAM_INITIAL_LOCKUP, "Tokens are still locked");

        uint256 releaseAmount = TEAM_INVESTOR_TOKENS / TEAM_VESTING_PERIOD * TEAM_RELEASE_INTERVAL;
        require(releaseAmount > 0, "Tokens already released");

        balances[teamWallet] += releaseAmount;

        emit Transfer(address(0), teamWallet, releaseAmount);

        TEAM_INVESTOR_TOKENS -= releaseAmount;
    }

    function sellTeamTokens(uint256 amount) external onlyTeam {
        require(amount <= TEAM_LOCKUP_RELEASE_AMOUNT, "Exceeds allowed sell amount");
        require(TEAM_INVESTOR_TOKENS >= amount, "Insufficient team tokens");

        balances[teamWallet] -= amount;
        balances[address(0)] += amount;

        emit Transfer(teamWallet, address(0), amount);

        TEAM_INVESTOR_TOKENS -= amount;
    }

    function getCurrentPhase() external view returns (Phase) {
        return currentPhase;
    }

    function getPhaseDuration() external pure returns (uint256) {
        return PHASE_DURATION;
    }

    function getTeamWallet() external view returns (address) {
        return teamWallet;
    }

    function getMarketingWallet() external view returns (address) {
        return marketingWallet;
    }

    function getCharityWallet() external view returns (address) {
        return charityWallet;
    }

    function getLpWallet() external view returns (address) {
        return lpWallet;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
