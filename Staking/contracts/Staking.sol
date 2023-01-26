// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStaking.sol";

contract Staking is IStaking, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @notice Simple check if user send 0
     */
    modifier isStakeGraterThanZero(uint256 _amount) {
        if (_amount == 0) revert Staking__StakeEqZero(msg.sender);
        _;
    }

    /**
     * @notice Modifier that update user stake time and recalculate reward due to stake/restake/withdraw
     */
    modifier updateUserInfo() {
        if (s_stakeTimestamp[msg.sender] != 0) {
            s_rewards[msg.sender] += recalculateRewards();
        }
        s_stakeTimestamp[msg.sender] = block.timestamp;
        _;
    }

    /**
     * @notice Update maps with dayly events
     */
    modifier updateTradeLines(uint256 amount, bool totalSupplyEffect) {
        uint256 curDate = (block.timestamp - s_startDate) / 24 / 3600;

        if (curDate - s_curDate >= 1 days) {
            uint256[] memory a;
            uint256[] memory b;
            uint256[] memory c;
            s_curDate += 1;
            s_opHistory[s_curDate] = TradeLine(a, b, c);
        }

        s_totalSupply = totalSupplyEffect
            ? s_totalSupply + amount
            : s_totalSupply - amount;
        uint256 lastUpdated = s_opHistory[curDate].timestamps.length > 0
            ? s_opHistory[curDate].timestamps[
                s_opHistory[curDate].timestamps.length - 1
            ]
            : 0;
        if (block.timestamp - lastUpdated > 1 hours) {
            s_opHistory[curDate].timestamps.push(block.timestamp);
            s_opHistory[curDate].supplys.push(s_totalSupply);
            if (lastUpdated == 0) {
                s_opHistory[curDate].hoursGone.push(
                    curDate == 0
                        ? 0
                        : block.timestamp -
                            s_opHistory[curDate - 1].timestamps[
                                s_opHistory[curDate - 1].timestamps.length - 1
                            ] /
                            3600
                );
            } else {
                s_opHistory[curDate].hoursGone.push(
                    (block.timestamp - lastUpdated) / 3600
                );
            }
        }
        _;
    }

    /**
     * @notice Check if contract is not ended
     */
    modifier isContractActive() {
        if (s_endDate < block.timestamp) revert Staking__NotActive(s_endDate);
        _;
    }

    /**
     * @notice Struct that allows us to save all events like withdraw/stake
     */
    struct TradeLine {
        uint256[] timestamps;
        uint256[] supplys;
        uint256[] hoursGone;
    }

    IERC20 public s_rewardToken;
    IERC20 public s_stakingToken;

    /**
     * @notice Balances of staking tokens
     */
    mapping(address => uint256) public s_balances;
    /**
     * @notice Balances of reward token
     */
    mapping(address => uint256) public s_rewards;
    /**
     * @notice This mapping save information in a way day -> event that happened during this day
     */
    mapping(uint256 => TradeLine) s_opHistory;
    /**
     * @notice Users stake start time
     */
    mapping(address => uint256) private s_stakeTimestamp;

    uint256 public constant REWARD_RATE_PER_DATE = 1000;
    /**
     * @notice TVL
     */
    uint256 public s_totalSupply;
    uint256 public s_startDate;
    uint256 public s_endDate;
    uint256 public s_curDate;

    constructor(address _stakingToken, address _rewardToken) {
        s_stakingToken = IERC20(_stakingToken);
        s_rewardToken = IERC20(_rewardToken);
        s_curDate = 0;
        s_startDate = block.timestamp;
        s_endDate = s_startDate + 30 days;
    }

    /**
     * @notice Deposit tokens into this contract
     * @param amount | How much to stake
     */
    function stake(
        uint256 amount
    )
        external
        isContractActive
        updateTradeLines(amount, true)
        isStakeGraterThanZero(amount)
        updateUserInfo
        nonReentrant
    {
        s_balances[msg.sender] += amount;
        emit Staked(msg.sender, amount);
        bool success = s_stakingToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) {
            revert Staking__TransferFailed(msg.sender, amount);
        }
    }

    /**
     * @notice Withdraw tokens from this contract
     * @param amount | How much to withdraw
     */
    function withdraw(
        uint256 amount
    ) external updateUserInfo updateTradeLines(amount, false) nonReentrant {
        s_balances[msg.sender] -= amount;
        emit WithdrewStake(msg.sender, amount);
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if (!success) {
            revert Staking__TransferFailed(msg.sender, amount);
        }
    }

    /**
     * @notice User claims their tokens
     */
    function claimReward() external updateUserInfo nonReentrant {
        uint256 reward = s_rewards[msg.sender];
        s_rewards[msg.sender] = 0;
        emit RewardsClaimed(msg.sender, reward);
        bool success = s_rewardToken.transfer(msg.sender, reward);
        if (!success) {
            revert Staking__TransferFailed(msg.sender, reward);
        }
    }

    /**
     * @notice View function that allows us to calculate rewards through all days
     */
    function recalculateRewards() internal view returns (uint256 reward) {
        uint256 lastSupply;
        for (uint i = 0; i <= s_curDate; i++) {
            for (uint j = 0; j < s_opHistory[i].timestamps.length; j++) {
                if (
                    s_opHistory[i].timestamps[j] <= s_stakeTimestamp[msg.sender]
                ) {
                    lastSupply = s_opHistory[i].supplys[j];
                    continue;
                }
                reward +=
                    (((s_opHistory[i].hoursGone[j] * REWARD_RATE_PER_DATE) /
                        24) * s_balances[msg.sender]) /
                    lastSupply;

                lastSupply = s_opHistory[i].supplys[j];
            }
        }
        reward +=
            (((((block.timestamp -
                s_opHistory[s_curDate].timestamps[
                    s_opHistory[s_curDate].timestamps.length - 1
                ]) / 3600) * REWARD_RATE_PER_DATE) / 24) *
                s_balances[msg.sender]) /
            lastSupply;
    }

    /**
     * @notice Simple getter that returns rewards of a client
     */
    function getReward() external view returns (uint256) {
        if (s_balances[msg.sender] == 0) {
            return s_rewards[msg.sender];
        }
        return s_rewards[msg.sender] + recalculateRewards();
    }
}
