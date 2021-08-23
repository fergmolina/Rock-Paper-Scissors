const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RockPaperScissors tests", function () {

    let owner, playerOne, playerTwo;
    
    beforeEach(async function () {
        [owner, playerOne, playerTwo] = await ethers.getSigners();
        
        DummyUBI = await ethers.getContractFactory("DummyUBI");
        dummyUBIToken = await DummyUBI.deploy();

        RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
        rockPaperScissors = await RockPaperScissors.deploy(dummyUBIToken.address);

    });

    it("Check DummyUBI Token", async function () {
        expect(await dummyUBIToken.name()).to.equal("Universal Basic Income");
    });

    it("Check balance of Player One", async function () {
        selection = await rockPaperScissors.getHash(0, "test"); // Player One Selects Rock
        await expect(rockPaperScissors.connect(playerOne).startGame(10, false, playerTwo.address, selection)).to.be.revertedWith("The allowance is not enough for this bet. Please rise");
    });

    it("Create a free game", async function () {
        selection = await rockPaperScissors.getHash(0, "test"); // Player One Selects Rock
        await expect(rockPaperScissors.connect(playerOne).startGame(0, false, playerTwo.address, selection)).to.emit(rockPaperScissors, 'StartGame')
        .withArgs(playerOne.address, playerTwo.address, 0);
    });

});