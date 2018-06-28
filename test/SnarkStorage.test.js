var SnarkStorage = artifacts.require("SnarkStorage");

contract('SnarkStorage', async (accounts) => {

    it("get size of the SnarkStorage contract", async () => {
        let sstorage = await SnarkStorage.deployed();
        let bytecode = sstorage.constructor._json.bytecode;
        let deployed = sstorage.constructor._json.deployedBytecode;
        let sizeOfB  = bytecode.length / 2;
        let sizeOfD  = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("test artworks functions", async () => {
        let sstorage = await SnarkStorage.deployed();

        // make sure that an array is empty
        let retval = await sstorage.getArtworksAmount.call();
        assert.equal(retval.toNumber(), 0, "length of array before adding an artwork is not equal 0");

        // declare variables
        let hashOfArtwork = "!q@w#e4r";
        let limitedEdition = 5;
        let editionNumber = 1;
        let lastPrice = 12;
        let profitShareSchemaId = 1;
        let profitShareFromSecondarySale = 15;
        let artworkUrl = "ipfs://blablabla";

        // add an artwork to the array artworks
        let tokenId = await sstorage.addArtwork.sendTransaction(
                            hashOfArtwork, 
                            limitedEdition, 
                            editionNumber, 
                            lastPrice, 
                            profitShareSchemaId, 
                            profitShareFromSecondarySale, 
                            artworkUrl
                        );
        console.log(tokenId);
        // assert.equal(tokenId.toNumber(), 1, "Token Id is not equal 1");

        // make sure that the array has one element
        retval = await sstorage.getArtworksAmount.call();
        assert.equal(retval.toNumber(), 1, "Length of artworks array after adding the artwork is not equal 1");

        // make sure that all values are the same like an original
        let value = await sstorage.getArtwork.call(1);
        assert.equal(value[1].toNumber(), limitedEdition, "limitedEdition is not equal");
        assert.equal(value[2].toNumber(), editionNumber, "editionNumber is not equal");
        assert.equal(value[3].toNumber(), lastPrice, "lastPrice is not equal");
        assert.equal(value[4].toNumber(), profitShareSchemaId, "profitShareSchemaId is not equal");
        assert.equal(value[5].toNumber(), profitShareFromSecondarySale, "profitShareFromSecondarySale is not equal");
        assert.equal(value[6], artworkUrl, "artworkUrl is not equal");

        await sstorage.updateArtworkLastPrice.sendTransaction(1, 40);
        await sstorage.updateArtworkProfitShareSchemaId.sendTransaction(1, 3);
        await sstorage.updateArtworkProfitShareFromSecondarySale.sendTransaction(1, 20);
        value = await sstorage.getArtwork.call(1);
        assert.equal(value[3].toNumber(), 40, "lastPrice is not equal");
        assert.equal(value[4].toNumber(), 3, "profitShareSchemaId is not equal");
        assert.equal(value[5].toNumber(), 20, "profitShareFromSecondarySale is not equal");
    });    
});


// contract('SnarkStorage', function(accounts) {

//     var hashOfArtwork = "!q@w#e4r";
//     var limitedEdition = 5;
//     var editionNumber = 1;
//     var lastPrice = 12;
//     var profitShareSchemaId = 1;
//     var profitShareFromSecondarySale = 15;
//     var artworkUrl = "ipfs://blablabla.jpg";

//     it("get size of the SnarkStorage contract", function() {
//         return SnarkStorage.deployed().then(function(instance) {
//             var bytecode = instance.constructor._json.bytecode;
//             var deployed = instance.constructor._json.deployedBytecode;
//             var sizeOfB  = bytecode.length / 2;
//             var sizeOfD  = deployed.length / 2;
//             console.log("size of bytecode in bytes = ", sizeOfB);
//             console.log("size of deployed in bytes = ", sizeOfD);
//             console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
//         });
//     });

//     it("test functions for artworks", function() {
//         var sstorage;
//         return SnarkStorage.deployed().then(function(instance) {
//             sstorage = instance;
//             return sstorage.getArtworksAmount.call();
//         }).then(function(retval) {
//             assert.equal(retval.toNumber(), 0, "length of array before adding an artwork to array is not equal 0");
//             return sstorage.addArtwork.call(
//                 hashOfArtwork, 
//                 limitedEdition, 
//                 editionNumber, 
//                 lastPrice, 
//                 profitShareSchemaId, 
//                 profitShareFromSecondarySale, 
//                 artworkUrl
//             );
//         }).then(function(retval) {
//             assert.equal(retval.toNumber(), 1, "Token Id is not equal 1");
//             return sstorage.getArtworksAmount.call();
//         }).then(function(retval) {
//             assert.equal(retval.toNumber(), 1, "length of array after adding an artwork to array is not equal 1");
//             return sstorage.getArtwork(retval.toNumber());
//         }).then(function(retval) {
//             assert.equal(retval[1].toNumber(), limitedEdition, "limitedEdition is not equal");
//             assert.equal(retval[2].toNumber(), editionNumber, "editionNumber is not equal");
//             assert.equal(retval[3].toNumber(), lastPrice, "lastPrice is not equal");
//             assert.equal(retval[4].toNumber(), profitShareSchemaId, "profitShareSchemaId is not equal");
//             assert.equal(retval[5].toNumber(), profitShareFromSecondarySale, "profitShareFromSecondarySale is not equal");
//             assert.equal(retval[6], artworkUrl, "artworkUrl is not equal");
//         });        
//     });

// });
    

