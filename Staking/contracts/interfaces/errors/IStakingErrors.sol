// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStakingErrors {
    /**
     * @notice Error for unsuccessfull call transfers
     */
    error Staking__TransferFailed(address, uint256);
    /**
     * @notice Error for 0 amount of stake
     */
    error Staking__StakeEqZero(address);
    /**
     * @notice Error if contract is not active anymore
     */
    error Staking__NotActive(uint256);
}
