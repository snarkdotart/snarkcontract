var SnarkBase = artifacts.require("SnarkBase");

contract('SnarkBase', async (accounts) => {

    it("get the size of the SnarkBase contract", async () => {
        let instance = await SnarkBase.deployed();
        let bytecode = instance.constructor._json.bytecode;
        let deployed = instance.constructor._json.deployedBytecode;
        let sizeOfB = bytecode.length / 2;
        let sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("test platform profit share functions", async () => {
        let instance = await SnarkBase.deployed();
        let value = await instance.platformProfitShare.call();
        assert.equal(value.toNumber(), 5);
        await instance.setPlatformProfitShare(34);
        value = await instance.platformProfitShare.call();
        assert.equal(value.toNumber(), 34);
    });

    it("test createProfitShareScheme function", async () => {
        let instance = await SnarkBase.deployed();
        const addresses = [accounts[1], accounts[2]];
        const percents = [60, 40];

        let result = await instance.getProfitShareSchemesTotalCount.call();
        assert.equal(result.toNumber(), 0, "Array of profits is not empty")

        const event = instance.ProfitShareSchemeAdded({ fromBlock: 0, toBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                let val_schemeId = result.args._profitShareSchemeId.toNumber();
                assert.equal(val_schemeId, 0, "ProfitShare Id is not equal 0");
            }
        });

        await instance.createProfitShareScheme(addresses, percents);

        result = await instance.getProfitShareSchemesTotalCount.call();
        assert.equal(result.toNumber(), 1, "Array of profits has a wrong length")
    });

    it("test deleting of profit share from secondary sale function", async () => {
        let instance = await SnarkBase.deployed();

        // const addresses = [accounts[1], accounts[2]];
        // const percents = [60, 40];

        // let result = await instance.getProfitShareSchemesTotalCount.call();
        // console.log(result);
        // assert.equal(result.toNumber(), 0, "Array of profits is not empty")

        // const event = instance.ProfitShareSchemeAdded({ fromBlock: 0, toBlock: 'latest' });
        // let val_schemeId;
        // event.watch(function (error, result) {
        //     if (!error) {
        //         val_schemeId = result.args._profitShareSchemeId.toNumber();
        //         assert.equal(val_schemeId, 0, "ProfitShare Id is not equal 0");
        //     }
        // });

        // await instance.createProfitShareScheme(addresses, percents);

        // 2. создаем цифровую работу и назначаем ей созданную схему распределения
        let tokens_count = await instance.getTokensCount.call();
        assert.equal(tokens_count, 0, "tokens count is more than 0");

        const event2 = instance.TokenCreatedEvent({ fromBlock: 0, toBlock: 'latest' });
        let val_tokenId;
        event2.watch(function (error, result) {
            if (!error) {
                let val_artist = result.args._owner;
                val_tokenId = result.args._tokenId;
                assert.equal(val_artist, accounts[0], "Artists don't match");
                assert.equal(val_tokenId, 0, "Token Id is not equal 0");
            }
        });

        const hashOfArtwork = "2324343434";
        const limitedEdition = 1;
        const profitShareForSecondSale = 20;
        const artworkUrl = "ipfs://test.jpg";
        const profitShareSchemeId = 0;

        await instance.addArtwork(
            hashOfArtwork,
            limitedEdition,
            profitShareForSecondSale,
            artworkUrl,
            profitShareSchemeId
        );

        tokens_count = await instance.getTokensCount.call();
        assert.equal(tokens_count, 1, "tokens count is not 1");

        const event3 = instance.NeedApproveProfitShareRemoving({ fromBlock: 0, toBlock: 'latest' });
        event3.watch(function (error, result) {
            if (!error) {
                let val_participant = result.args._participant;
                instance.approveRemovingProfitShareFromSecondarySale(0, {from: val_participant});                
            }
        });

        await instance.sendRequestForApprovalOfProfitShareRemovalForSecondarySale(0, {from: accounts[0]});

        const result = await instance.getTokenDetails(0);
        assert.equal(result[2].toNumber(), 0, "Didn't remove a profit share for secondary sale");
    });
});
