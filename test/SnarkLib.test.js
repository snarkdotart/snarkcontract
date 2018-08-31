var SnarkBase = artifacts.require("SnarkBase");

contract('SnarkBase', async (accounts) => {

    let instance = null;
    // const variableName = "testvariable";

    before(async () => {
        instance = await SnarkBase.deployed();
    });

    it("1. get size of the SnarkBase library", async () => {
        const bytecode = instance.constructor._json.bytecode;
        const deployed = instance.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("2. test SnarkWalletAddress functions", async () => {
        const val = '0xC04691B99EB731536E35F375ffC85249Ec713597'.toUpperCase();

        let retval = await instance.getSnarkWalletAddress();
        assert.equal(retval, 0);

        await instance.setSnarkWalletAddress(val);

        retval = await instance.getSnarkWalletAddress();
        assert.equal(retval.toUpperCase(), val);
    });

    it("3. test PlatformProfitShare functions", async () => {
        const val = 5;

        let retval = await instance.getPlatformProfitShare();
        assert.equal(retval.toNumber(), 0);

        await instance.setPlatformProfitShare(val);

        retval = await instance.getPlatformProfitShare();
        assert.equal(retval.toNumber(), val);
    });

    it("4. test addArtwork | totalNumberOfArtworks functions", async () => {
        const artistAddress = "0xC04691B99EB731536E35F375ffC85249Ec713597".toUpperCase();
        const artworkHash = web3.sha3("artworkHash");
        const limitedEdition = 10;
        const editionNumber = 2;
        const lastPrice = 5000;
        const profitShareSchemeId = 1;
        const profitShareFromSecondarySale = 20;
        const artworkUrl = "http://snark.art";

        let retval = await instance.getTotalNumberOfArtworks();
        assert.equal(retval.toNumber(), 0);

        const event = instance.ArtworkCreated({ fromBlock: 0, toBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                tokenId = result.args._tokenId.toNumber();
                assert.equal(tokenId, 1, "Token Id is not equal 1");
            }
        });

        retval = await instance.addArtwork(
            artistAddress,
            artworkHash,
            limitedEdition,
            editionNumber,
            lastPrice,
            profitShareSchemeId,
            profitShareFromSecondarySale,
            artworkUrl
        );

        tokenId = await instance.getTotalNumberOfArtworks();
        tokenId = tokenId.toNumber();
        assert.equal(tokenId, 1);

        retval = await instance.getArtwork(tokenId);
        assert.equal(retval[0].toUpperCase(), artistAddress.toUpperCase());
        assert.equal(retval[1].toUpperCase(), artworkHash.toUpperCase());
        assert.equal(retval[2].toNumber(), limitedEdition);
        assert.equal(retval[3].toNumber(), editionNumber);
        assert.equal(retval[4].toNumber(), lastPrice);
        assert.equal(retval[5].toNumber(), profitShareSchemeId);
        assert.equal(retval[6].toNumber(), profitShareFromSecondarySale);
        assert.equal(retval[7], artworkUrl);
    });

    it("5. test ArtworkArtist functions", async () => {
        const val = '0xC04691B99EB731536E35F375ffC85249Ec713597'.toUpperCase();
        const key = 2;

        let retval = await instance.getArtworkArtist(key);
        assert.equal(retval, 0);

        await instance.setArtworkArtist(key, val);
        retval = await instance.getArtworkArtist(key);
        assert.equal(retval.toUpperCase(), val);
    });

    it("6. test ArtworkLimitedEdition functions", async () => {
        const key1 = 3;
        const val1 = 45;

        let retval = await instance.getArtworkLimitedEdition(key1);
        assert.equal(retval, 0);

        await instance.setArtworkLimitedEdition(key1, val1);
        retval = await instance.getArtworkLimitedEdition(key1);
        assert.equal(retval, val1);
    });

    it("7. test ArtworkEditionNumber functions", async () => {
        const key1 = 4;
        const key2 = 5;
        const val1 = 1;
        const val2 = 5;

        let retval = await instance.getArtworkEditionNumber(key1);
        assert.equal(retval, 0);

        retval = await instance.getArtworkEditionNumber(key2)
        assert.equal(retval, 0);

        await instance.setArtworkEditionNumber(key1, val1);
        await instance.setArtworkEditionNumber(key2, val2);

        retval = await instance.getArtworkEditionNumber(key1);
        assert.equal(retval, val1);

        retval = await instance.getArtworkEditionNumber(key2)
        assert.equal(retval, val2);
    });

    it("8. test ArtworkLastPrice functions", async () => {
        const key1 = 6;
        const key2 = 7;
        const val1 = 34;
        const val2 = 98;

        let retval = await instance.getArtworkLastPrice(key1);
        assert.equal(retval, 0);

        retval = await instance.getArtworkLastPrice(key2);
        assert.equal(retval, 0);

        await instance.setArtworkLastPrice(key1, val1);
        await instance.setArtworkLastPrice(key2, val2);

        retval = await instance.getArtworkLastPrice(key1);
        assert.equal(retval, val1);

        retval = await instance.getArtworkLastPrice(key2);
        assert.equal(retval, val2);
    });

    it("9. test ArtworkHash functions", async () => {
        const key = 8;
        const val = web3.sha3("test_hash_of_artwork");

        let retval = await instance.getArtworkHash(key);
        assert.equal(retval, 0);

        await instance.setArtworkHash(key, val);

        retval = await instance.getArtworkHash(key);
        assert.equal(retval, val);
    });

    it("10. test ArtworkProfitShareSchemeId functions", async () => {
        const key = 9;
        const val = 2;

        let retval = await instance.getArtworkProfitShareSchemeId(key);
        assert.equal(retval, 0);

        await instance.setArtworkProfitShareSchemeId(key, val);

        retval = await instance.getArtworkProfitShareSchemeId(key);
        assert.equal(retval, val);
    });

    it("11. test ArtworkProfitShareFromSecondarySale functions", async () => {
        const key = 10;
        const val = 20;

        let retval = await instance.getArtworkProfitShareFromSecondarySale(key);
        assert.equal(retval, 0);

        await instance.setArtworkProfitShareFromSecondarySale(key, val);

        retval = await instance.getArtworkProfitShareFromSecondarySale(key);
        assert.equal(retval.toNumber(), val);
    });

    it("12. test ArtworkURL functions", async () => {
        const key = 11;
        const val = "http://snark.art";

        let retval = await instance.getArtworkURL(key);
        assert.isEmpty(retval);

        await instance.setArtworkURL(key, val);

        retval = await instance.getArtworkURL(key);
        assert.equal(retval, val);
    });

    it("13. test ProftShareScheme functions", async () => {
        const participants = [
            '0xC04691B99EB731536E35F375ffC85249Ec713597', 
            '0xB94691B99EB731536E35F375ffC85249Ec717233'
        ];
        const profits = [ 20, 80 ];

        let retval = await instance.getTotalNumberOfProfitShareSchemes();
        assert.equal(retval, 0);

        retval = await instance.getNumberOfProfitShareSchemesForOwner();
        assert.equal(retval, 0);

        const event = instance.ProfitShareSchemeCreated({ fromBlock: 0, toBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                schemeId = result.args._profitShareSchemeId.toNumber();
                assert.equal(schemeId, 1, "Token Id is not equal 1");
            }
        });

        await instance.addProfitShareScheme(participants, profits);

        retval = await instance.getTotalNumberOfProfitShareSchemes();
        assert.equal(retval, 1);

        retval = await instance.getNumberOfProfitShareSchemesForOwner();
        assert.equal(retval, 1);

        schemeId = await instance.getProfitShareSchemeIdForOwner(0);
        assert.equal(schemeId, 1);

        retval = await instance.getNumberOfParticipantsForProfitShareScheme(schemeId);
        assert.equal(retval, participants.length);

        retval = await instance.getParticipantOfProfitShareScheme(schemeId, 0);
        assert.equal(retval[0].toUpperCase(), participants[0].toUpperCase());
        assert.equal(retval[1], profits[0]);

        retval = await instance.getParticipantOfProfitShareScheme(schemeId, 1);
        assert.equal(retval[0].toUpperCase(), participants[1].toUpperCase());
        assert.equal(retval[1], profits[1]);
    });

    // it("", async () => {});
    // it("", async () => {});
    // it("", async () => {});

    // it("test arrayNameToItemsCount functions", async () => {
    //     let cnt = await instance.getArrayNameToItemsCount(variableName);
    //     assert.equal(cnt, 0);

    //     await instance.increaseArrayNameToItemsCount(variableName);
    //     cnt = await instance.getArrayNameToItemsCount(variableName);
    //     assert.equal(cnt, 1);
    // });

    // it("test storageBytes32ToBool functions", async () => {
    //     const key = 0x123456789;

    //     let cnt = await instance.getStorageBytes32ToBool(variableName, key);
    //     assert.isFalse(cnt);

    //     await instance.setStorageBytes32ToBool(variableName, key, true);

    //     cnt = await instance.getStorageBytes32ToBool(variableName, key);
    //     assert.isTrue(cnt);
    // });

    // it("test storageUint8ToUint256Array functions", async () => {
    //     const key = 5;
    //     let val = 7;
        
    //     let cnt = await instance.getStorageUint8ToUint256ArrayLength(variableName, key);
    //     assert.equal(cnt, 0);

    //     await instance.addStorageUint8ToUint256Array(variableName, key, val);
    //     cnt = await instance.getStorageUint8ToUint256ArrayLength(variableName, key);
    //     assert.equal(cnt, 1);

    //     await instance.addStorageUint8ToUint256Array(variableName, key, val + 1);
    //     cnt = await instance.getStorageUint8ToUint256ArrayLength(variableName, key);
    //     assert.equal(cnt, 2);

    //     cnt = await instance.getStorageUint8ToUint256Array(variableName, key, 0);
    //     assert.equal(cnt, val);

    //     cnt = await instance.getStorageUint8ToUint256Array(variableName, key, 1);
    //     assert.equal(cnt, val + 1);

    //     await instance.setStorageUint8ToUint256Array(variableName, key, 1, val + 9);
    //     cnt = await instance.getStorageUint8ToUint256Array(variableName, key, 1);
    //     assert.equal(cnt, val + 9);

    //     await instance.deleteStorageUint8ToUint256Array(variableName, key, 0);
    //     cnt = await instance.getStorageUint8ToUint256ArrayLength(variableName, key);
    //     assert.equal(cnt, 1);

    //     cnt = await instance.getStorageUint8ToUint256Array(variableName, key, 0);
    //     assert.equal(cnt, val + 9);
    // });

    // it("test storageUint256ToBytes32Array functions", async () => {
    //     const key = 5;
    //     const val1 = 0x123;
    //     const val2 = 0x987;

    //     let cnt = await instance.getStorageUint256ToBytes32ArrayLength(variableName, key);
    //     assert.equal(cnt, 0);

    //     await instance.addStorageUint256ToBytes32Array(variableName, key, val1);
    //     await instance.addStorageUint256ToBytes32Array(variableName, key, val2);

    //     cnt = await instance.getStorageUint256ToBytes32ArrayLength(variableName, key);
    //     assert.equal(cnt, 2);

    //     cnt = await instance.getStorageUint256ToBytes32Array(variableName, key, 0);
    //     cnt = cutZeros(cnt);
    //     assert.equal(web3.fromDecimal(cnt), web3.fromDecimal(val1));

    //     cnt = await instance.getStorageUint256ToBytes32Array(variableName, key, 1);
    //     cnt = cutZeros(cnt);
    //     assert.equal(web3.fromDecimal(cnt), web3.fromDecimal(val2));

    //     await instance.setStorageUint256ToBytes32Array(variableName, key, 0, val2);
    //     cnt = await instance.getStorageUint256ToBytes32Array(variableName, key, 0);
    //     cnt = cutZeros(cnt);
    //     assert.equal(web3.fromDecimal(cnt), web3.fromDecimal(val2));

    //     await instance.deleteStorageUint256ToBytes32Array(variableName, key, 0);
    //     cnt = await instance.getStorageUint256ToBytes32ArrayLength(variableName, key);
    //     assert.equal(cnt, 1);

    //     cnt = await instance.getStorageUint256ToBytes32Array(variableName, key, 0);
    //     cnt = cutZeros(cnt);
    //     assert.equal(web3.fromDecimal(cnt), web3.fromDecimal(val2));
    // });

    // function cutZeros(str) {
    //     var indexFrom = str.length;
    //     for (var i = str.length - 1; i > 0; i--) {
    //         if (str[i] == "0") indexFrom = i;
    //         else break;
    //     }
    //     str = str.substr(0, indexFrom);
    //     return str;
    // }

    // it("test storageUint256ToUint8Array functions", async () => {
    //     const key = 2;

    //     let cnt = await instance.getStorageUint256ToUint8ArrayLength(variableName, key);
    //     assert(cnt, 0);

    //     await instance.addStorageUint256ToUint8Array(variableName, key, 4);
    //     await instance.addStorageUint256ToUint8Array(variableName, key, 6);

    //     cnt = await instance.getStorageUint256ToUint8ArrayLength(variableName, key);
    //     assert(cnt, 2);

    //     await instance.setStorageUint256ToUint8Array(variableName, key, 1, 9);
    //     cnt = await instance.getStorageUint256ToUint8Array(variableName, key, 1);
    //     assert(cnt, 9);

    //     await instance.deleteStorageUint256ToUint8Array(variableName, key, 1);
    //     cnt = await instance.getStorageUint256ToUint8ArrayLength(variableName, key);
    //     assert(cnt, 1);

    //     cnt = await instance.getStorageUint256ToUint8Array(variableName, key, 0);
    //     assert(cnt, 4);
    // });

    // it("test storageUint256ToUint16Array functions", async () => {
    //     const key = 2;

    //     let cnt = await instance.getStorageUint256ToUint16ArrayLength(variableName, key);
    //     assert(cnt, 0);

    //     await instance.addStorageUint256ToUint16Array(variableName, key, 4);
    //     await instance.addStorageUint256ToUint16Array(variableName, key, 6);

    //     cnt = await instance.getStorageUint256ToUint16ArrayLength(variableName, key);
    //     assert(cnt, 2);

    //     await instance.setStorageUint256ToUint16Array(variableName, key, 1, 9);
    //     cnt = await instance.getStorageUint256ToUint16Array(variableName, key, 1);
    //     assert(cnt, 9);

    //     await instance.deleteStorageUint256ToUint16Array(variableName, key, 1);
    //     cnt = await instance.getStorageUint256ToUint16ArrayLength(variableName, key);
    //     assert(cnt, 1);

    //     cnt = await instance.getStorageUint256ToUint16Array(variableName, key, 0);
    //     assert(cnt, 4);
    // });

    // it("test storageUint256ToUint64Array functions", async () => {
    //     const key = 2;

    //     let cnt = await instance.getStorageUint256ToUint64ArrayLength(variableName, key);
    //     assert(cnt, 0);

    //     await instance.addStorageUint256ToUint64Array(variableName, key, 4);
    //     await instance.addStorageUint256ToUint64Array(variableName, key, 6);

    //     cnt = await instance.getStorageUint256ToUint64ArrayLength(variableName, key);
    //     assert(cnt, 2);

    //     await instance.setStorageUint256ToUint64Array(variableName, key, 1, 9);
    //     cnt = await instance.getStorageUint256ToUint64Array(variableName, key, 1);
    //     assert(cnt, 9);

    //     await instance.deleteStorageUint256ToUint64Array(variableName, key, 1);
    //     cnt = await instance.getStorageUint256ToUint64ArrayLength(variableName, key);
    //     assert(cnt, 1);

    //     cnt = await instance.getStorageUint256ToUint64Array(variableName, key, 0);
    //     assert(cnt, 4);
    // });

    // it("test storageUint256ToUint256Array functions", async () => {
    //     const key = 2;

    //     let cnt = await instance.getStorageUint256ToUint256ArrayLength(variableName, key);
    //     assert(cnt, 0);

    //     await instance.addStorageUint256ToUint256Array(variableName, key, 4);
    //     await instance.addStorageUint256ToUint256Array(variableName, key, 6);

    //     cnt = await instance.getStorageUint256ToUint256ArrayLength(variableName, key);
    //     assert(cnt, 2);

    //     await instance.setStorageUint256ToUint256Array(variableName, key, 1, 9);
    //     cnt = await instance.getStorageUint256ToUint256Array(variableName, key, 1);
    //     assert(cnt, 9);

    //     await instance.deleteStorageUint256ToUint256Array(variableName, key, 1);
    //     cnt = await instance.getStorageUint256ToUint256ArrayLength(variableName, key);
    //     assert(cnt, 1);

    //     cnt = await instance.getStorageUint256ToUint256Array(variableName, key, 0);
    //     assert(cnt, 4);
    // });

    // it("test storageUint256ToAddressArray functions", async () => {
    //     const key = 3;
    //     const val1 = '0xC04691B99EB731536E35F375ffC85249Ec713597';
    //     const val2 = '0xC04691B99EB731536E35F375ffC85249Ec713733';

    //     let cnt = await instance.getStorageUint256ToAddressArrayLength(variableName, key);
    //     assert(cnt, 0);

    //     await instance.addStorageUint256ToAddressArray(variableName, key, val1);
    //     await instance.addStorageUint256ToAddressArray(variableName, key, val2);

    //     cnt = await instance.getStorageUint256ToAddressArrayLength(variableName, key);
    //     assert(cnt, 2);

    //     await instance.setStorageUint256ToAddressArray(variableName, key, 1, val1);
    //     cnt = await instance.getStorageUint256ToAddressArray(variableName, key, 1);
    //     assert(cnt, val1);

    //     await instance.deleteStorageUint256ToAddressArray(variableName, key, 1);
    //     cnt = await instance.getStorageUint256ToAddressArrayLength(variableName, key);
    //     assert(cnt, val1);

    //     cnt = await instance.getStorageUint256ToAddressArray(variableName, key, 0);
    //     assert(cnt, val1);
    // });

    // it("test storageUint256ToString functions", async () => {
    //     const key = 2;
    //     const val1 = "test1";
    //     const val2 = "test2";

    //     let cnt = await instance.getStorageUint256ToString(variableName, key);
    //     assert.equal(cnt, "");

    //     await instance.setStorageUint256ToString(variableName, key, val1);
    //     cnt = await instance.getStorageUint256ToString(variableName, key);
    //     assert.equal(cnt, val1);

    //     await instance.setStorageUint256ToString(variableName, key, val2);
    //     cnt = await instance.getStorageUint256ToString(variableName, key);
    //     assert.equal(cnt, val2);

    //     await instance.deleteStorageUint256ToString(variableName, key);
    //     cnt = await instance.getStorageUint256ToString(variableName, key);
    //     assert.equal(cnt, "");
    // });

    // it("test storageAddressToAddressArray functions", async () => {
    //     const key = '0xc04691b99eb731536e35f375ffc85249ec713597';
    //     const val1 = "0xc05691b99eb731536e35f375ffc85249ec713756";
    //     const val2 = "0xc09991b99eb731536e35f375ffc85249ec711234";

    //     let cnt = await instance.getStorageAddressToAddressArrayLength(variableName, key);
    //     assert.equal(cnt, 0);

    //     await instance.addStorageAddressToAddressArray(variableName, key, val1);
    //     await instance.addStorageAddressToAddressArray(variableName, key, val2);

    //     cnt = await instance.getStorageAddressToAddressArrayLength(variableName, key);
    //     assert.equal(cnt, 2);

    //     await instance.setStorageAddressToAddressArray(variableName, key, 1, val1);
    //     cnt = await instance.getStorageAddressToAddressArray(variableName, key, 1);
    //     assert.equal(cnt, val1);

    //     await instance.deleteStorageAddressToAddressArray(variableName, key, 1);
    //     cnt = await instance.getStorageAddressToAddressArrayLength(variableName, key);
    //     assert.equal(cnt, 1);
    // });

    // it("test storageAddressToUint256Array functions", async () => {
    //     const key = '0xc04691b99eb731536e35f375ffc85249ec713597';
    //     let val = 7;
        
    //     let cnt = await instance.getStorageAddressToUint256ArrayLength(variableName, key);
    //     assert.equal(cnt, 0);

    //     await instance.addStorageAddressToUint256Array(variableName, key, val);
    //     await instance.addStorageAddressToUint256Array(variableName, key, val + 1);
    //     cnt = await instance.getStorageAddressToUint256ArrayLength(variableName, key);
    //     assert.equal(cnt, 2);

    //     await instance.setStorageAddressToUint256Array(variableName, key, 1, val + 3);

    //     cnt = await instance.getStorageAddressToUint256Array(variableName, key, 0);
    //     assert.equal(cnt, val);

    //     cnt = await instance.getStorageAddressToUint256Array(variableName, key, 1);
    //     assert.equal(cnt, val + 3);

    //     await instance.deleteStorageAddressToUint256Array(variableName, key, 0);
    //     cnt = await instance.getStorageAddressToUint256ArrayLength(variableName, key);
    //     assert.equal(cnt, 1);

    //     cnt = await instance.getStorageAddressToUint256Array(variableName, key, 0);
    //     assert.equal(cnt, val + 3);
    // });

    // it("test storageAddressToBool functions", async () => {
    //     const key = '0xc04691b99eb731536e35f375ffc85249ec713597';

    //     let cnt = await instance.getStorageAddressToBool(variableName, key);
    //     assert.equal(cnt, false);

    //     await instance.setStorageAddressToBool(variableName, key, true);
    //     cnt = await instance.getStorageAddressToBool(variableName, key);
    //     assert.equal(cnt, true);
    // });

    // it("test tokenToParticipantApprovingMap functions", async () => {});

});
