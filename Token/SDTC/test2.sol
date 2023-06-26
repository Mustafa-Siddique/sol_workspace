// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";

contract SaveTheDogsToken is ERC20 {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Constants
    uint256 public constant TOTAL_SUPPLY = 99999999 * 10 ** 18; // 99,999,999 tokens
    uint256 public constant VESTING_DURATION = 9 * 30 days; // 9 months
    uint256 public constant LOCKUP_DURATION = 3 * 30 days; // 3 months
    uint256 public constant PHASE_DURATION = 3 * 30 days; // 3 months
    uint256 public constant MAX_SELLABLE_PERCENTAGE = 0.1 * 10 ** 18; // 0.1%
    uint256 public constant MAX_PHASE_SELLABLE_PERCENTAGE = 1 * 10 ** 18; // 1%

    // Addresses
    address public teamAndInvestorAddress;
    address public marketingAddress;
    address public publicSaleAddress;
    address public charityAddress;
    address public liquidityPoolAddress;

    // Vesting
    uint256 public teamAndInvestorVestingStartTime;
    uint256 public teamAndInvestorVestingEndTime;
    mapping(address => uint256) public vestedBalance;

    // Sale
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public phaseStartTime;
    uint256 public phaseEndTime;
    mapping(address => uint256) public purchaseAmount;
    mapping(address => uint256) public salePhase;

    // Modifiers
    modifier onlyPublicSale() {
        require(
            msg.sender == publicSaleAddress,
            "Caller is not the public sale address"
        );
        _;
    }

    modifier onlyDuringSale() {
        require(
            block.timestamp >= saleStartTime && block.timestamp <= saleEndTime,
            "Sale is not active"
        );
        _;
    }

    // Constructor
    constructor(
        address _teamAndInvestorAddress,
        address _marketingAddress,
        address _publicSaleAddress,
        address _charityAddress,
        address _liquidityPoolAddress
    ) ERC20("Save the Dogs", "STDC") {
        teamAndInvestorAddress = _teamAndInvestorAddress;
        marketingAddress = _marketingAddress;
        publicSaleAddress = _publicSaleAddress;
        charityAddress = _charityAddress;
        liquidityPoolAddress = _liquidityPoolAddress;

        // Token Distribution
        uint256 teamAndInvestorTokens = TOTAL_SUPPLY.mul(30).div(100);
        uint256 marketingTokens = TOTAL_SUPPLY.mul(20).div(100);
        uint256 publicSaleTokens = TOTAL_SUPPLY.mul(40).div(100);
        uint256 charityTokens = TOTAL_SUPPLY.mul(10).div(100);

        // Mint Tokens
        _mint(teamAndInvestorAddress, teamAndInvestorTokens);
        _mint(marketingAddress, marketingTokens);
        _mint(publicSaleAddress, publicSaleTokens);
        _mint(charityAddress, charityTokens);

        // Vesting Setup
        teamAndInvestorVestingStartTime = block.timestamp;
        teamAndInvestorVestingEndTime = teamAndInvestorVestingStartTime.add(
            VESTING_DURATION
        );

        // Sale Setup
        saleStartTime = block.timestamp;
        saleEndTime = saleStartTime.add(
            LOCKUP_DURATION.add(PHASE_DURATION.mul(7))
        );
        phaseStartTime = saleStartTime.add(LOCKUP_DURATION);
        phaseEndTime = phaseStartTime.add(PHASE_DURATION);
    }

    // Public Sale
    function buyTokens() external payable onlyDuringSale {
        require(
            msg.value >= 100 * 10 ** 18 && msg.value <= 100000 * 10 ** 18,
            "Invalid investment amount"
        );

        uint256 tokensToBuy = msg.value.div(0.002 * 10 ** 18);

        require(
            balanceOf(publicSaleAddress) >= tokensToBuy,
            "Insufficient token balance for sale"
        );

        purchaseAmount[msg.sender] = purchaseAmount[msg.sender].add(
            tokensToBuy
        );

        uint256 currentPhase = getCurrentSalePhase();

        require(
            salePhase[msg.sender] <= currentPhase,
            "Tokens can only be bought in the current phase"
        );

        uint256 tokensPurchased = purchaseAmount[msg.sender].sub(
            vestedBalance[msg.sender]
        );

        require(
            tokensPurchased <= MAX_PHASE_SELLABLE_PERCENTAGE,
            "Exceeded maximum phase sellable percentage"
        );

        _transfer(publicSaleAddress, msg.sender, tokensToBuy);

        if (currentPhase < 7) {
            if (tokensPurchased.add(tokensToBuy) > MAX_SELLABLE_PERCENTAGE) {
                salePhase[msg.sender] = currentPhase.add(1);
            }
        }
    }

    // Vesting Release
    function releaseVestedTokens() external {
        require(
            msg.sender == teamAndInvestorAddress,
            "Caller is not the team and investor address"
        );
        require(
            block.timestamp > teamAndInvestorVestingStartTime,
            "Vesting has not started"
        );

        uint256 currentBalance = balanceOf(teamAndInvestorAddress);
        uint256 vestedAmount = currentBalance
            .mul(block.timestamp.sub(teamAndInvestorVestingStartTime))
            .div(VESTING_DURATION);
        uint256 unreleasedAmount = vestedAmount.sub(
            vestedBalance[teamAndInvestorAddress]
        );

        require(unreleasedAmount > 0, "No vested tokens available for release");

        vestedBalance[teamAndInvestorAddress] = vestedAmount;

        _transfer(
            teamAndInvestorAddress,
            teamAndInvestorAddress,
            unreleasedAmount
        );
    }

    // Internal Transfer
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (sender == teamAndInvestorAddress) {
            require(
                block.timestamp >= teamAndInvestorVestingEndTime,
                "Tokens are still vesting"
            );
        }

        super._transfer(sender, recipient, amount);
    }

    // Get current sale phase
    function getCurrentSalePhase() public view returns (uint256) {
        if (block.timestamp < phaseStartTime) {
            return 0;
        } else if (
            block.timestamp >= phaseStartTime && block.timestamp <= saleEndTime
        ) {
            uint256 timeSincePhaseStart = block.timestamp.sub(phaseStartTime);
            uint256 phase = timeSincePhaseStart.div(PHASE_DURATION).add(1);
            if (phase > 7) {
                return 7;
            } else {
                return phase;
            }
        } else {
            return 7;
        }
    }

    // Withdraw ETH from the contract
    function withdrawETH() external {
        require(
            msg.sender == marketingAddress,
            "Caller is not the marketing address"
        );
        payable(marketingAddress).transfer(address(this).balance);
    }
}