var SnarkStorage = artifacts.require("SnarkStorage");

contract('SnarkStorage', async (accounts) => {

    it("get size of the SnarkStorage contract", async () => {
        const instance = await SnarkStorage.deployed();
        const bytecode = instance.constructor._json.bytecode;
        const deployed = instance.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("test artworks functions", async () => {
        const instance = await SnarkStorage.deployed();

        // make sure that an array is empty
        let value = await instance.getArtworksAmount.call();
        assert.equal(value.toNumber(), 0, "length of array before adding an artwork is not equal 0");

        // declare variables
        const hashOfArtwork = "!q@w#e4r";
        const limitedEdition = 5;
        const editionNumber = 1;
        const lastPrice = 12;
        const profitShareSchemaId = 1;
        const profitShareFromSecondarySale = 15;
        const artworkUrl = "ipfs://blablabla";

        // add an artwork to the array artworks
        value = await instance.addArtwork( //sendTransaction
            accounts[5],
            hashOfArtwork,
            limitedEdition,
            editionNumber,
            lastPrice,
            profitShareSchemaId,
            profitShareFromSecondarySale,
            artworkUrl
        );

        // const event = instance.ArtworkAdded({ _sender: instance.address }, { fromBlock: 0, toBlock: 'latest' });
        // event.watch(function (error, result) {
        //     assert.equal(result.args._tokenId.toNumber(), 0, "Token Id is not equal 0");
        // });
        // event.stopWatching();

        // make sure that the array has one element
        value = await instance.getArtworksAmount.call();
        assert.equal(value.toNumber(), 1, "Length of artworks array after adding the artwork is not equal 1");

        // make sure that all values are the same like an original
        value = await instance.getArtworkDescription.call(0);
        assert.equal(value[0], accounts[5], "Artists don't match");
        assert.equal(value[1].toNumber(), limitedEdition, "limitedEdition is not equal");
        assert.equal(value[2].toNumber(), editionNumber, "editionNumber is not equal");
        assert.equal(value[3].toNumber(), lastPrice, "lastPrice is not equal");

        await instance.updateArtworkLastPrice(0, 40);
        await instance.updateArtworkProfitShareSchemaId(0, 3);
        await instance.updateArtworkProfitShareFromSecondarySale(0, 20);
        value = await instance.getArtworkDetails.call(0);
        assert.equal(value[1].toNumber(), 3, "profitShareSchemaId is not equal");
        assert.equal(value[2].toNumber(), 20, "profitShareFromSecondarySale is not equal");
    });

    it("test ProfitShareScheme functions", async () => {
        const instance = await SnarkStorage.deployed();

        const addresses = [accounts[1], accounts[2]];
        const percents = [60, 40];

        let result = await instance.getProfitShareSchemesTotalAmount.call();
        assert.equal(result, 0);

        await instance.addProfitShareScheme(addresses, percents);

        result = await instance.getProfitShareSchemesTotalAmount.call();
        assert.equal(result.toNumber(), 1, "Amount of profit share schemes is not equal 1");

        result = await instance.getProfitShareSchemeParticipantsAmount.call(0);
        assert.equal(result.toNumber(), 2, "Participants amount is not equal 2");

        for (let i = 0; i < result; i++) {
            val  = await instance.getProfitShareSchemeForParticipant.call(0, i);
            assert.equal(val[0], addresses[i], "Participants are not equal");
            assert.equal(val[1].toNumber(), percents[i], "Profits are not equal");    
        }
    });

});
