import chai, { expect } from "chai";

import { ethers } from "hardhat";
import { Signer } from "ethers";
import { solidity } from "ethereum-waffle";

const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

chai.use(solidity);

const { assert } = chai;

describe.skip("SequoiaXUSDMarket", function () {
  let accounts: Signer[];

  let OWNER_SIGNER: any;
  let DEV_SIGNER: any;
  let ALICE_SIGNER: any;
  let BOB_SIGNER: any;
  let DAVE_SIGNER: any;

  let OWNER: any;
  let DEV: any;
  let ALICE: any;
  let BOB: any;
  let DAVE: any;

  let nft: any;
  let market: any;

  before(async () => {
    accounts = await ethers.getSigners();

    OWNER_SIGNER = accounts[0];
    DEV_SIGNER = accounts[1];
    ALICE_SIGNER = accounts[2];
    BOB_SIGNER = accounts[3];
    DAVE_SIGNER = accounts[4];

    OWNER = await OWNER_SIGNER.getAddress();
    DEV = await DEV_SIGNER.getAddress();
    ALICE = await ALICE_SIGNER.getAddress();
    BOB = await BOB_SIGNER.getAddress();
    DAVE = await DAVE_SIGNER.getAddress();

    const SeqchainAlphaGeneration = await ethers.getContractFactory(
      "SeqchainAlphaGeneration"
    );
    const SequoiaXUSDMarket = await ethers.getContractFactory(
      "SequoiaXUSDMarket"
    );

    nft = await SeqchainAlphaGeneration.deploy();
    await nft.deployed();

    market = await SequoiaXUSDMarket.deploy(nft.address, DEV);
    await market.deployed();

    await nft.setOperator(market.address, true);
    await market.setPrice(1);
  });

  describe("General tests", () => {
    it("#mint", async () => {
      await market.setStatus(2);

      let priceBoxId0 = 1;
      let amount = 1;
      let deposit = amount * priceBoxId0;
      let token = "";

      await market
        .connect(ALICE_SIGNER)
        .mint(amount, token, { value: deposit });
    });

    it("#mintPresale", async () => {
      await market.setStatus(1);

      let priceBoxId0 = 1;

      const wl = [DAVE, ALICE, BOB];
      const leaves = wl.map((v) => keccak256(v));
      const tree = new MerkleTree(leaves, keccak256, { sort: true });
      const root = tree.getHexRoot();
      const leaf: any = keccak256(ALICE);
      const proof = tree.getHexProof(leaf);

      await market.setWhitelistMerkleRoot(root);

      const verified = await market.verify(root, leaf, proof);
      assert.equal(verified, true, "On contract");

      let amount = 1;
      let deposit = amount * priceBoxId0;

      await market
        .connect(ALICE_SIGNER)
        .mintPresale(amount, proof, { value: deposit });

      await market
        .connect(BOB_SIGNER)
        .mintPresale(amount, proof, { value: deposit });

      await market
        .connect(DAVE_SIGNER)
        .mintPresale(amount, proof, { value: deposit });

      // has one chance
      expect(
        market
          .connect(ALICE_SIGNER)
          .mintPresale(amount, proof, { value: deposit })
      ).revertedWith("NFT is already claimed by this wallet");
    });
  });
});
