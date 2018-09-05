var TestSnarkCommonLib = artifacts.require("TestSnarkCommonLib");
var TestSnarkBaseLib = artifacts.require("TestSnarkBaseLib");

contract('TestSnarkCommonLib', async (accounts) => {

    let instance = null;
    // let baseLibInstance = null;

    before(async () => {
        instance = await TestSnarkCommonLib.deployed();
        // baseLibInstance = await TestSnarkBaseLib.deployed();
    });

    it("1. get size of the TestSnarkBaseLib library", async () => {
        const bytecode = instance.constructor._json.bytecode;
        const deployed = instance.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("2. test transferArtwork function", async () => {
        const artworkId = 1;
        const owner1 = '0xC04691B99EB731536E35F375ffC85249Ec713597'.toUpperCase();
        const owner2 = '0xB94691B99EB731536E35F375ffC85249Ec717233'.toUpperCase();
        const artworkHash = web3.sha3("artworkHash");
        const limitedEdition = 10;
        const editionNumber = 2;
        const lastPrice = 5000;
        const profitShareSchemeId = 1;
        const profitShareFromSecondarySale = 20;
        const artworkUrl = "http://snark.art";

        await instance.addArtwork(
            owner1,
            artworkHash,
            limitedEdition,
            editionNumber,
            lastPrice,
            profitShareSchemeId,
            profitShareFromSecondarySale,
            artworkUrl
        );

        let retval = await instance.getTotalNumberOfArtworks();
        assert.equal(retval.toNumber(), 1, "error on step 0");

        retval = await instance.getNumberOfOwnerArtworks(owner1);
        assert.equal(retval.toNumber(), 0, "error on step 1");
        retval = await instance.getNumberOfOwnerArtworks(owner2);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        await instance.setOwnerOfArtwork(artworkId, owner1);
        await instance.setArtworkToOwner(owner1, artworkId);

        retval = await instance.getNumberOfOwnerArtworks(owner1);
        assert.equal(retval.toNumber(), 1, "error on step 3");
        retval = await instance.getNumberOfOwnerArtworks(owner2);
        assert.equal(retval.toNumber(), 0, "error on step 4");
        retval = await instance.getArtworkIdOfOwner(owner1, 0);
        assert.equal(retval.toNumber(), artworkId, "error on step 5");

        await instance.transferArtwork(artworkId, owner1, owner2);

        retval = await instance.getNumberOfOwnerArtworks(owner1);
        assert.equal(retval.toNumber(), 0, "error on step 6");
        retval = await instance.getNumberOfOwnerArtworks(owner2);
        assert.equal(retval.toNumber(), 1, "error on step 7");
        retval = await instance.getArtworkIdOfOwner(owner2, 0);
        assert.equal(retval.toNumber(), artworkId, "error on step 8");
    });

});
