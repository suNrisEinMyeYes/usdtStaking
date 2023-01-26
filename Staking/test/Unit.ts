import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

import { Staking, TTToken } from "../typechain-types"
const SECONDS_IN_A_DAY = 86400
const SECONDS_IN_A_YEAR = 31449600
const SECONDS_IN_A_HOUR = 3600
describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const RewardToken = await ethers.getContractFactory("TTToken");
    const rewardToken = await RewardToken.deploy();
    await rewardToken.deployed();

    const StakingToken = await ethers.getContractFactory("TTToken");
    const stakingToken = await StakingToken.deploy();
    await stakingToken.deployed();

    await stakingToken.mintTo(owner.address, ethers.utils.parseEther("10000000"));
    await stakingToken.mintTo(otherAccount.address, ethers.utils.parseEther("1000000"))

    const Staking = await ethers.getContractFactory("Staking");
    const staking = await Staking.deploy(stakingToken.address, rewardToken.address);
    await staking.deployed();
    await rewardToken.mintToStaking(staking.address)

    return { stakingToken, rewardToken, staking, owner, otherAccount };
  }

  describe("Staking", function () {
    it("Simple stake check", async function () {
      const { stakingToken, rewardToken, staking, owner, otherAccount } = await loadFixture(deployOneYearLockFixture);
      const stakeAmount = ethers.utils.parseEther("100")
      await stakingToken.approve(staking.address, stakeAmount)
      await staking.stake(stakeAmount)
      await time.increase(SECONDS_IN_A_HOUR)
      let reward = await staking.getReward()
      let expectedReward = "41"
      expect(reward.toString()).to.equal(expectedReward)
    });
    it("Hard stake check", async function () {
      const { stakingToken, rewardToken, staking, owner, otherAccount } = await loadFixture(deployOneYearLockFixture);
      const stakeAmount = ethers.utils.parseEther("100")
      await stakingToken.approve(staking.address, stakeAmount)
      await stakingToken.connect(otherAccount).approve(staking.address, stakeAmount)
      await staking.stake(stakeAmount)
      await time.increase(SECONDS_IN_A_HOUR + 1)
      await staking.connect(otherAccount).stake(stakeAmount)
      await time.increase(SECONDS_IN_A_HOUR + 1)
      await time.increase(SECONDS_IN_A_HOUR + 1)
      let reward = await staking.getReward()
      let reward2 = await staking.connect(otherAccount).getReward()
      let expectedReward = "82"
      let expectedReward2 = "41"
      expect(reward.toString()).to.equal(expectedReward)
      expect(reward2.toString()).to.equal(expectedReward2)
    });
  });

  describe("withdraw", () => {
    it("Moves tokens from the staking contract to the user", async () => {
      const { stakingToken, rewardToken, staking, owner, otherAccount } = await loadFixture(deployOneYearLockFixture);
      const stakeAmount = ethers.utils.parseEther("100")
      await stakingToken.approve(staking.address, stakeAmount)
      await staking.stake(stakeAmount)
      await time.increase(SECONDS_IN_A_DAY)
      const balanceBefore = await stakingToken.balanceOf(owner.address)
      await staking.withdraw(stakeAmount)
      const balanceAfter = await stakingToken.balanceOf(owner.address)
      const expectedEarned = "1000"
      expect(await staking.connect(owner).getReward()).to.equal(expectedEarned)
      expect(balanceAfter.toString()).to.equal(balanceBefore.add(stakeAmount).toString())
    })
  })

  describe("claimReward", () => {
    it("Users can claim their rewards", async () => {
      const { stakingToken, rewardToken, staking, owner, otherAccount } = await loadFixture(deployOneYearLockFixture);
      const stakeAmount = ethers.utils.parseEther("100")
      await stakingToken.approve(staking.address, stakeAmount)
      await staking.stake(stakeAmount)
      await time.increase(SECONDS_IN_A_DAY)
      const expectedEarned = "1000"
      const balanceBefore = await rewardToken.balanceOf(owner.address)
      await staking.claimReward()
      const balanceAfter = await rewardToken.balanceOf(owner.address)
      expect(balanceAfter.toString()).to.equal(balanceBefore.add(expectedEarned).toString())
    })
  })
});
