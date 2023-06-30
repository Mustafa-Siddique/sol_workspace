// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./SafeMath.sol";

// Token Distribution:
// Total Supply: 99,999,999 SDTC

// 15% of tokens allocated to team and investors (vesting period of 9 months)
// 15% of tokens allocated to team and advisors (vesting of 6 months)
// 6-month vesting period for team and advisors (weekly release of vested tokens)

contract SDTCVesting {
    using SafeMath for uint256;
    IERC20 public token;

    address payable public owner;
    address payable public teamAndInvestors;
    address payable public teamAndAdvisors;

    uint256 public teamAndInvestorsAmount = 14999999 * 10 ** 18;
    uint256 public teamAndAdvisorsAmount = 14999999 * 10 ** 18;

    uint256 public teamAndInvestorsVestingPeriod = 9 * 30 days;
    uint256 public teamAndAdvisorsVestingPeriod = 6 * 30 days;

    uint256 public teamAndInvestorsVestingStartTime;
    uint256 public teamAndAdvisorsVestingStartTime;

    uint256 public teamAndInvestorsVestingEndTime =
        teamAndInvestorsVestingStartTime.add(teamAndInvestorsVestingPeriod);
    uint256 public teamAndAdvisorsVestingEndTime =
        teamAndAdvisorsVestingStartTime.add(teamAndAdvisorsVestingPeriod);

    uint256 public teamAndInvestorsReleasedAmount;
    uint256 public teamAndAdvisorsReleasedAmount;

    uint256 public teamAndAdvisorsWeeklyReleaseAmount =
        teamAndAdvisorsAmount.div(26);

    event Lock(address indexed _from, uint256 _value);
    event Release(address indexed _to, uint256 _value);
    event WalletChanged(address indexed _from, address indexed _to);

    constructor() {
        owner = payable(msg.sender);
        teamAndInvestors = payable(0x0);
        teamAndAdvisors = payable(0x0);
        teamAndInvestorsVestingStartTime = block.timestamp;
        teamAndAdvisorsVestingStartTime = block.timestamp;
        // token = IERC20(0x0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function setTeamAndInvestors(
        address payable _teamAndInvestors
    ) external onlyOwner {
        require(
            teamAndInvestors != address(0),
            "Team and Investors address not set"
        );

        teamAndInvestors = _teamAndInvestors;
        emit WalletChanged(msg.sender, _teamAndInvestors);
    }

    function setTeamAndAdvisors(
        address payable _teamAndAdvisors
    ) external onlyOwner {
        require(
            teamAndAdvisors != address(0),
            "Team and Advisors address not set"
        );

        teamAndAdvisors = _teamAndAdvisors;
        emit WalletChanged(msg.sender, _teamAndAdvisors);
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function lockTeamAndInvestorsTokens() external onlyOwner {
        require(
            teamAndInvestors != address(0),
            "Team and Investors address not set"
        );
        require(
            token.balanceOf(msg.sender) >= teamAndInvestorsAmount,
            "Insufficient balance"
        );
        require(
            token.allowance(msg.sender, address(this)) >=
                teamAndInvestorsAmount,
            "Insufficient allowance"
        );

        token.transferFrom(msg.sender, address(this), teamAndInvestorsAmount);
        emit Lock(msg.sender, teamAndInvestorsAmount);
    }

    function lockTeamAndAdvisorsTokens() external onlyOwner {
        require(
            teamAndAdvisors != address(0),
            "Team and Advisors address not set"
        );
        require(
            token.balanceOf(msg.sender) >= teamAndAdvisorsAmount,
            "Insufficient balance"
        );
        require(
            token.allowance(msg.sender, address(this)) >= teamAndAdvisorsAmount,
            "Insufficient allowance"
        );

        token.transferFrom(msg.sender, address(this), teamAndAdvisorsAmount);
        emit Lock(msg.sender, teamAndAdvisorsAmount);
    }

    function releaseTeamAndInvestorsTokens() external onlyOwner {
        require(
            teamAndInvestors != address(0),
            "Team and Investors address not set"
        );
        require(
            block.timestamp > teamAndInvestorsVestingEndTime,
            "Vesting period not started yet"
        );
        require(
            teamAndInvestorsReleasedAmount < teamAndInvestorsAmount,
            "All tokens released"
        );

        uint256 releasableAmount = teamAndInvestorsAmount;
        require(releasableAmount > 0, "No tokens to release");

        token.transfer(teamAndInvestors, releasableAmount);
        teamAndInvestorsReleasedAmount = teamAndInvestorsReleasedAmount.add(
            releasableAmount
        );
        emit Release(teamAndInvestors, releasableAmount);
    }

    function releaseTeamAndAdvisorsTokens() external onlyOwner {
        require(
            teamAndAdvisors != address(0),
            "Team and Advisors address not set"
        );
        require(
            block.timestamp > teamAndAdvisorsVestingStartTime,
            "Vesting period not started yet"
        );
        require(
            teamAndAdvisorsReleasedAmount < teamAndAdvisorsAmount,
            "All tokens released"
        );

        uint256 weeksPassed = (
            block.timestamp.sub(teamAndAdvisorsVestingStartTime)
        ).div(7 days);
        uint256 releasableAmount = weeksPassed.mul(
            teamAndAdvisorsWeeklyReleaseAmount
        );
        if (releasableAmount > teamAndAdvisorsAmount) {
            releasableAmount = teamAndAdvisorsAmount;
        }
        releasableAmount = releasableAmount.sub(teamAndAdvisorsReleasedAmount);
        require(releasableAmount > 0, "No tokens to release");
        token.transfer(teamAndAdvisors, releasableAmount);
        teamAndAdvisorsReleasedAmount = teamAndAdvisorsReleasedAmount.add(
            releasableAmount
        );
        emit Release(teamAndAdvisors, releasableAmount);
    }
}
