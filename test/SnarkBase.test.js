var SnarkBase = artifacts.require("SnarkBase");

contract('SnarkBase', async (accounts) => {

    let instance = null;

    before(async () => {
        instance = await SnarkBase.deployed();
    });

    it("1. get size of the SnarkBase contract", async () => {
        const bytecode = instance.constructor._json.bytecode;
        const deployed = instance.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("2. test ProfitShareScheme's functions", async () => {
        const participants = [
            '0xC04691B99EB731536E35F375ffC85249Ec713597', 
            '0xB94691B99EB731536E35F375ffC85249Ec717233'
        ];
        const profits = [ 20, 80 ];

        let retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 0);

        const event = instance.ProfitShareSchemeAdded({ fromBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                schemeId = result.args.profitShareSchemeId.toNumber();
                // console.log("SchemeId = ", schemeId);
                // assert.equal(schemeId, 1, "SchemeId is not equal 1");
            }
        });

        await instance.createProfitShareScheme(participants, profits);

        retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 1);

        retval = await instance.getProfitShareSchemeCountByAddress();
        assert.equal(retval.toNumber(), 1);

        retval = await instance.getProfitShareSchemeIdByIndex(0);
        assert.equal(retval.toNumber(), 1);

        retval = await instance.getProfitShareParticipantsCount();
        assert.equal(retval.toNumber(), 1);
    });

    it("3. test addToken function", async () => {
        const tokenHash = web3.sha3("tokenHash");
        const limitedEdition = 10;
        const profitShareFromSecondarySale = 20;
        const tokenUrl = "http://snark.art";
        const profitShareSchemeId = 1;

        let retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 1, "error on step 1");

        retval = await instance.getTokensCount();
        assert.equal(retval.toNumber(), 0, "error on step 2");

        const event = instance.TokenCreated({ fromBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                tokenId = result.args.tokenId.toNumber();
                console.log("event TokenCreatedEvent: tokenId = ", tokenId);
                // assert.equal(tokenId, 1, "SchemeId is not equal 1");
            }
        });

        await instance.addToken(
            tokenHash,
            limitedEdition,
            profitShareFromSecondarySale,
            tokenUrl,
            profitShareSchemeId,
            true,
            true
        );

        retval = await instance.getTokensCount();
        assert.equal(retval.toNumber(), 10, "error on step 3");

        retval = await instance.getTokensCountByOwner(accounts[0]);
        assert.equal(retval.toNumber(), 10, "error on step 4");

        retval = await instance.getTokensCountByArtist(accounts[0]);
        assert.equal(retval.toNumber(), 10, "error on step 5");
    });

    it("4. test changeProfitShareSchemeForToken function", async () => {
        const participants = [
            '0xC04691B99EB731536E35F375ffC85249Ec713222', 
            '0xB94691B99EB731536E35F375ffC85249Ec717777',
            '0xB94691B99EB731536E35F375ffC85249Ec717999'
        ];
        const profits = [ 30, 60, 10 ];

        retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 1, "error on step 1");

        await instance.createProfitShareScheme(participants, profits);

        retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 2, "error on step 2");

        retval = await instance.getProfitShareSchemeCountByAddress();
        assert.equal(retval.toNumber(), 2, "error on step 3");

        retval = await instance.getTokensCountByOwner(accounts[0]);
        assert.equal(retval.toNumber(), 10, "error on step 4");

        await instance.changeProfitShareSchemeForToken(1, 2);

        retval = await instance.getProfitShareParticipantsCount();
        assert.equal(retval.toNumber(), 2, "error on step 5");

        retval = await instance.getTokenDetails(1);
        assert.equal(retval[5].toNumber(), 2, "error on step 6");
    });

});
