import chai, {expect} from "chai";

import { ethers } from "hardhat";
import { Signer } from "ethers";
import { solidity } from "ethereum-waffle";

const { MerkleTree } = require('merkletreejs')
const keccak256 = require('keccak256')

chai.use(solidity);

const { assert } = chai;

describe("SequoiaMarket", function () {
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
    let market: any;

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

        const SeqchainAlphaGeneration = await ethers.getContractFactory("SeqchainAlphaGeneration");
        const SequoiaMarket = await ethers.getContractFactory("SequoiaMarket");

        nft = await SeqchainAlphaGeneration.deploy();
        await nft.deployed()

        market = await SequoiaMarket.deploy(nft.address, DEV);
        await market.deployed()

        await nft.setOperator(market.address, true)
        await market.setPrice(1)
    });

    describe('General tests', () => {
        it('#mint', async () => {
            await market.setStatus(2)

            let priceBoxId0 = 1;
            let amount = 1
            let deposit = amount * priceBoxId0

            await market.connect(ALICE_SIGNER).mint(
                amount,
                { value: deposit }
            )
        })

        it('#mintPresale', async () => {
            await market.setStatus(1)

            let priceBoxId0 = 1;
            let amount = 1
            let deposit = amount * priceBoxId0

            const wl = [ALICE, BOB, DAVE, DEV, JANE]
            const leaves = wl.map(v => keccak256(v))
            const tree = new MerkleTree(leaves, keccak256, { sort: true })
            const root = tree.getHexRoot()

            await market.setWhitelistMerkleRoot(root)

            // ALICE
            let leaf: any = keccak256(ALICE)
            let proof: Array<string> = tree.getHexProof(leaf)

            let verified = await market.verify(root, leaf, proof)
            assert.equal(verified, true, 'ALICE')

            await market.connect(ALICE_SIGNER).mintPresale(
                amount,
                proof,
                { value: deposit }
            )

            // has one chance
            expect(
                market.connect(ALICE_SIGNER).mintPresale(
                    amount,
                    proof,
                    { value: deposit }
                )
            ).revertedWith('NFT is already claimed by this wallet')

            // BOB
            leaf = keccak256(BOB)
            proof = tree.getHexProof(leaf)

            verified = await market.verify(root, leaf, proof)
            assert.equal(verified, true, 'BOB')

            await market.connect(BOB_SIGNER).mintPresale(
                amount,
                proof,
                { value: deposit }
            )
        })
    })

});