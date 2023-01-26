import { Staking__factory } from "../typechain-types";

async function main() {
  const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
  const staking = await new Staking__factory().deploy(USDT,);
  await staking.deployed();
  console.log(`Staking deployed to ${staking.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});