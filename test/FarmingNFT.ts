import chai, {expect} from "chai";

import { ethers } from "hardhat";
import { Signer } from "ethers";
import { solidity } from "ethereum-waffle";

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

        nft = await SeqchainAlphaGeneration.deploy();
        await nft.deployed()

        await nft.setOperator(OWNER, true)
    });

    describe('General tests', () => {

        beforeEach(async () => {
            const FarmingNFT = await ethers.getContractFactory("FarmingNFT");

            farm = await FarmingNFT.deploy(

            );
            await farm.deployed()
        })
    })

});