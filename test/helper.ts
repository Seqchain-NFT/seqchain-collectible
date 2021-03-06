import { expect } from "chai";
import { network } from "hardhat";

export function getTimestamp() {
  return Math.floor(Date.now() / 1000);
}

export async function expectRevert(condition: any, message: string) {
  await expect(condition).to.revertedWith(message);
}

export async function increaseTime(forSeconds: number) {
  await network.provider.send("evm_increaseTime", [forSeconds]);
  await network.provider.send("evm_mine");
}

export async function setNextBlockTimestamp(timestamp: number) {
  await network.provider.send("evm_setNextBlockTimestamp", [timestamp]);
  await network.provider.send("evm_mine");
}

export async function increaseBlockNumber(blocks: number) {
  for (let i = 0; i < blocks; i++) {
    await network.provider.send("evm_mine");
  }
}
