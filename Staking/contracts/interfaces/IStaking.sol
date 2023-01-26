// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./errors/IStakingErrors.sol";
import "./events/IStakingEvents.sol";

interface IStaking is IStakingErrors, IStakingEvents {}
