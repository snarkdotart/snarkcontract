var SnarkStorage = artifacts.require("SnarkStorage");

contract('SnarkStorage', async (accounts) => {

    let instance = null;

    before(async () => {
        instance = await SnarkStorage.deployed();
    });

    it("get size of the SnarkBaseStorage contract", async () => {
        // const instance = await SnarkStorage.deployed();
        const bytecode = instance.constructor._json.bytecode;
        const deployed = instance.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    // it("test artworks functions", async () => {
    //     // make sure that an array is empty
    //     let value = await instance.get_artworks_length.call();
    //     assert.equal(value.toNumber(), 0, "length of array before adding an artwork is not equal 0");

    //     // declare variables
    //     const hashOfArtwork = "!q@w#e4r";
    //     const limitedEdition = 5;
    //     const editionNumber = 1;
    //     const lastPrice = 12;
    //     const profitShareSchemaId = 1;
    //     const profitShareFromSecondarySale = 15;
    //     const artworkUrl = "ipfs://blablabla";

    //     // add an artwork to the array artworks
    //     value = await instance.add_artwork( //sendTransaction
    //         accounts[5],
    //         hashOfArtwork,
    //         limitedEdition,
    //         editionNumber,
    //         lastPrice,
    //         profitShareSchemaId,
    //         profitShareFromSecondarySale,
    //         artworkUrl
    //     );

    //     // const event = instance.ArtworkAdded({ _sender: instance.address }, { fromBlock: 0, toBlock: 'latest' });
    //     // event.watch(function (error, result) {
    //     //     assert.equal(result.args._tokenId.toNumber(), 0, "Token Id is not equal 0");
    //     // });
    //     // event.stopWatching();

    //     // make sure that the array has one element
    //     value = await instance.get_artworks_length.call();
    //     assert.equal(value.toNumber(), 1, "Length of artworks array after adding the artwork is not equal 1");

    //     // make sure that all values are the same like an original
    //     value = await instance.get_artwork_description.call(0);
    //     assert.equal(value[0], accounts[5], "Artists don't match");
    //     assert.equal(value[1].toNumber(), limitedEdition, "limitedEdition is not equal");
    //     assert.equal(value[2].toNumber(), editionNumber, "editionNumber is not equal");
    //     assert.equal(value[3].toNumber(), lastPrice, "lastPrice is not equal");

    //     await instance.update_artworks_lastPrice(0, 40);
    //     await instance.update_artworks_profitShareSchemaId(0, 3);
    //     await instance.update_artworks_profitShareFromSecondarySale(0, 20);
    //     value = await instance.get_artwork_details.call(0);
    //     assert.equal(value[1].toNumber(), 3, "profitShareSchemaId is not equal");
    //     assert.equal(value[2].toNumber(), 20, "profitShareFromSecondarySale is not equal");
    // });

    // it("test ProfitShareScheme functions", async () => {
    //     const addresses = [accounts[1], accounts[2]];
    //     const percents = [60, 40];

    //     let result = await instance.get_profitShareSchemes_length.call();
    //     assert.equal(result, 0);

    //     await instance.add_profitShareSchemes(addresses, percents);

    //     result = await instance.get_profitShareSchemes_length.call();
    //     assert.equal(result.toNumber(), 1, "count of profit share schemes is not equal 1");

    //     result = await instance.get_profitShareSchemes_participants_length.call(0);
    //     assert.equal(result.toNumber(), 2, "Participants count is not equal 2");

    //     for (let i = 0; i < result; i++) {
    //         val  = await instance.get_profitShareSchemes.call(0, i);
    //         assert.equal(val[0], addresses[i], "Participants are not equal");
    //         assert.equal(val[1].toNumber(), percents[i], "Profits are not equal");    
    //     }
    // });

    // it("test ownerToTokensMap functions", async () => {
    //     let size = await instance.get_ownerToTokensMap_length(accounts[1]);
    //     assert.equal(size, 0, "size of ownerToTokensMap is not equal zero");

    //     await instance.add_ownerToTokensMap(accounts[1], 1);
    //     await instance.add_ownerToTokensMap(accounts[1], 2);
    //     await instance.add_ownerToTokensMap(accounts[1], 3);
    //     await instance.add_ownerToTokensMap(accounts[1], 4);
    //     await instance.add_ownerToTokensMap(accounts[1], 5);

    //     size = await instance.get_ownerToTokensMap_length(accounts[1]);
    //     assert.equal(size, 5, "size of ownerToTokensMap is not equal 5");

    //     let tokenId = await instance.get_ownerToTokensMap(accounts[1], 0);
    //     assert.equal(tokenId, 1, "tokenId of ownerToTokensMap is not equal 1");

    //     tokenId = await instance.get_ownerToTokensMap(accounts[1], 1);
    //     assert.equal(tokenId, 2, "tokenId of ownerToTokensMap is not equal 2");

    //     tokenId = await instance.get_ownerToTokensMap(accounts[1], 2);
    //     assert.equal(tokenId, 3, "tokenId of ownerToTokensMap is not equal 3");

    //     tokenId = await instance.get_ownerToTokensMap(accounts[1], 3);
    //     assert.equal(tokenId, 4, "tokenId of ownerToTokensMap is not equal 4");

    //     tokenId = await instance.get_ownerToTokensMap(accounts[1], 4);
    //     assert.equal(tokenId, 5, "tokenId of ownerToTokensMap is not equal 5");

    //     await instance.delete_ownerToTokensMap(accounts[1], 4);

    //     size = await instance.get_ownerToTokensMap_length(accounts[1]);
    //     assert.equal(size, 4, "size of ownerToTokensMap is not equal 4");

    //     tokenId = await instance.get_ownerToTokensMap(accounts[1], 3);
    //     assert.equal(tokenId, 4, "tokenId of ownerToTokensMap is not equal 4");

    //     await instance.delete_ownerToTokensMap(accounts[1], 0);

    //     size = await instance.get_ownerToTokensMap_length(accounts[1]);
    //     assert.equal(size, 3, "size of ownerToTokensMap is not equal 3");

    //     tokenId = await instance.get_ownerToTokensMap(accounts[1], 0);
    //     assert.equal(tokenId, 4, "tokenId of ownerToTokensMap is not equal 4");

    //     tokenId = await instance.get_ownerToTokensMap(accounts[1], 2);
    //     assert.equal(tokenId, 3, "tokenId of ownerToTokensMap is not equal 3");

    //     await instance.delete_ownerToTokensMap(accounts[1], 1);

    //     size = await instance.get_ownerToTokensMap_length(accounts[1]);
    //     assert.equal(size, 2, "size of ownerToTokensMap is not equal 2");

    //     tokenId = await instance.get_ownerToTokensMap(accounts[1], 0);
    //     assert.equal(tokenId, 4, "tokenId of ownerToTokensMap is not equal 4");

    //     tokenId = await instance.get_ownerToTokensMap(accounts[1], 1);
    //     assert.equal(tokenId, 3, "tokenId of ownerToTokensMap is not equal 3");
    // });

});
