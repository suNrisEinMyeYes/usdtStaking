// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TTToken is ERC20, Ownable {
    constructor() ERC20("TestTaskToken", "TTT") {}

    function mintToStaking(address _stakingContract) public onlyOwner {
        _mint(_stakingContract, 3000000000000000);
    }
}
