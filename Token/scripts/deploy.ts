import { TTToken__factory } from "../typechain-types";

async function main() {
  const token = await new TTToken__factory().deploy("");
  await token.deployed();
  console.log(`TTToken deployed to ${token.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
