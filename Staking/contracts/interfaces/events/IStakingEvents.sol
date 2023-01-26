// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStakingEvents {
    /**
     * @notice Event for successfull stake
     */
    event Staked(address indexed user, uint256 indexed amount);
    /**
     * @notice Event for successfull withdrawal
     */
    event WithdrewStake(address indexed user, uint256 indexed amount);
    /**
     * @notice Event for successfull claim
     */
    event RewardsClaimed(address indexed user, uint256 indexed amount);
}
