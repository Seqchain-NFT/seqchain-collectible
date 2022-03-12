import chai from "chai";

import { ethers } from "hardhat";
import { BigNumber, Signer } from "ethers";
import { solidity } from "ethereum-waffle";
import { expectRevert, increaseTime, increaseBlockNumber } from "./helper";

chai.use(solidity);

const { assert } = chai;

describe("FarmingNFT", function () {
  let accounts: Signer[];

  let OWNER_SIGNER: any;
  let DEV_SIGNER: any;
  let ALICE_SIGNER: any;
  let BOB_SIGNER: any;
  let DAVE_SIGNER: any;
  let JANE_SIGNER: any;

  let OWNER: any;
  let DEV: any;
  let ALICE: any;
  let BOB: any;
  let DAVE: any;
  let JANE: any;

  let nft: any;
  let farm: any;
  let registry: any;
  let token: any;

  const countReward = async function (
    tokenId: string | number,
    blocks: number
  ): Promise<BigNumber> {
    let { rarity } = await registry.get(tokenId);
    let reward = await farm.rewardsPerBlock(rarity);
    return reward.mul(blocks);
  };

  before(async () => {
    accounts = await ethers.getSigners();

    OWNER_SIGNER = accounts[0];
    DEV_SIGNER = accounts[1];
    ALICE_SIGNER = accounts[2];
    BOB_SIGNER = accounts[3];
    DAVE_SIGNER = accounts[4];
    JANE_SIGNER = accounts[5];

    OWNER = await OWNER_SIGNER.getAddress();
    DEV = await DEV_SIGNER.getAddress();
    ALICE = await ALICE_SIGNER.getAddress();
    BOB = await BOB_SIGNER.getAddress();
    DAVE = await DAVE_SIGNER.getAddress();
    JANE = await JANE_SIGNER.getAddress();

    const AlphaGenerationRegistry = await ethers.getContractFactory(
      "AlphaGenerationRegistry"
    );

    registry = await AlphaGenerationRegistry.deploy();
    await registry.deployed();

    await registry.setOperator(OWNER, true);
    await registry.setBatch(
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
      [
        {
          rarity: 1,
        },
        {
          rarity: 4,
        },
        {
          rarity: 2,
        },
        {
          rarity: 1,
        },
        {
          rarity: 1,
        },
        {
          rarity: 3,
        },
        {
          rarity: 2,
        },
        {
          rarity: 1,
        },
        {
          rarity: 1,
        },
        {
          rarity: 1,
        },
      ]
    );
  });

  describe("General tests", () => {
    beforeEach(async () => {
      const SeqchainAlphaGeneration = await ethers.getContractFactory(
        "SeqchainAlphaGeneration"
      );
      const FarmingNFT = await ethers.getContractFactory("FarmingNFT");
      const ERC20Mock = await ethers.getContractFactory("ERC20Mock");

      nft = await SeqchainAlphaGeneration.deploy();
      await nft.deployed();

      token = await ERC20Mock.deploy();
      await token.deployed();

      await nft.setOperator(OWNER, true);

      farm = await FarmingNFT.deploy(
        registry.address,
        nft.address,
        token.address,
        6500,
        [
          (15e18).toString(),
          (25e18).toString(),
          (35e18).toString(),
          (50e18).toString(),
        ]
      );
      await farm.deployed();
    });

    it("#enable success", async () => {
      await nft.mint(ALICE, 2);
      await farm.connect(ALICE_SIGNER).enable([0, 1]);
    });

    it("#enable fail", async () => {
      await nft.mint(ALICE, 2);
      await expectRevert(
        farm.connect(ALICE_SIGNER).enable([1, 1]),
        "Duplicates in token list"
      );
      await expectRevert(
        farm.connect(BOB_SIGNER).enable([0, 1]),
        "Ownership not approved"
      );
      await expectRevert(
        farm.connect(BOB_SIGNER).enable([2]),
        "ERC721: owner query for nonexistent token"
      );
    });

    it("#pendingReward", async () => {
      await nft.mint(ALICE, 1);
      await farm.connect(ALICE_SIGNER).enable([0]);

      await increaseBlockNumber(10);
      assert.notEqual(Number(await farm.pendingReward(0)), 0, "Empty reward");
    });

    it("#pendingRewardBatch", async () => {
      await nft.mint(ALICE, 2);
      await farm.connect(ALICE_SIGNER).enable([0, 1]);

      await increaseBlockNumber(10);
      assert.notEqual(
        Number(await farm.pendingRewardBatch([0, 1])),
        0,
        "Empty reward"
      );
    });

    it("#earn", async () => {
      await nft.mint(ALICE, 1);
      await farm.setFeeTo(DEV);
      await farm.connect(ALICE_SIGNER).enable([0]);

      await increaseBlockNumber(10);
      // + 1 block for earn call
      let expectedReward = await countReward(0, 10 + 1); // await farm.pendingReward(0)
      await farm.connect(ALICE_SIGNER).earn(0);

      let acceptedReward = await token.balanceOf(ALICE);
      assert.equal(
        String(acceptedReward),
        String(expectedReward),
        "Incorrect reward"
      );

      expectedReward = await farm.pendingReward(0);
      assert.equal(Number(expectedReward), 0, "Why not zero?");
    });

    it("#earnBatch", async () => {
      await nft.mint(ALICE, 2);
      await farm.setFeeTo(DEV);
      await farm.connect(ALICE_SIGNER).enable([0, 1]);

      await increaseBlockNumber(10);
      // + 1 block for earn call
      let expectedReward = await countReward(0, 10 + 1); // await farm.pendingReward(0)
      expectedReward = expectedReward.add(await countReward(1, 10 + 1));
      await farm.connect(ALICE_SIGNER).earnBatch([0, 1]);

      let acceptedReward = await token.balanceOf(ALICE);
      assert.equal(
        String(acceptedReward),
        String(expectedReward),
        "Incorrect reward"
      );

      expectedReward = await farm.pendingReward(0);
      assert.equal(Number(expectedReward), 0, "Why not zero?");
    });
  });
});
