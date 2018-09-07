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
                schemeId = result.args._profitShareSchemeId.toNumber();
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

    it("3. test addArtwork function", async () => {
        const artworkHash = web3.sha3("artworkHash");
        const limitedEdition = 10;
        const profitShareFromSecondarySale = 20;
        const artworkUrl = "http://snark.art";
        const profitShareSchemeId = 1;

        let retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 1);

        retval = await instance.getTokensCount();
        assert.equal(retval.toNumber(), 0);

        const event = instance.TokenCreatedEvent({ fromBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                tokenId = result.args._tokenId.toNumber();
                console.log("event TokenCreatedEvent: tokenId = ", tokenId);
                // assert.equal(tokenId, 1, "SchemeId is not equal 1");
            }
        });

        await instance.addArtwork(
            artworkHash,
            limitedEdition,
            profitShareFromSecondarySale,
            artworkUrl,
            profitShareSchemeId
        );

        retval = await instance.getTokensCount();
        assert.equal(retval.toNumber(), 10);

        retval = await instance.getTokensCountByOwner(web3.eth.accounts[0]);
        assert.equal(retval.toNumber(), 10);

        retval = await instance.getTokensCountByArtist(web3.eth.accounts[0]);
        assert.equal(retval.toNumber(), 10);
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

        retval = await instance.getTokensCountByOwner(web3.eth.accounts[0]);
        assert.equal(retval.toNumber(), 10, "error on step 4");

        await instance.changeProfitShareSchemeForToken(1, 2);

        retval = await instance.getProfitShareParticipantsCount();
        assert.equal(retval.toNumber(), 2, "error on step 5");

        retval = await instance.getTokenDetails(1);
        assert.equal(retval[5].toNumber(), 2, "error on step 6");
    });

    it("5. test _transfer function", async () => {
        ///////// change internal to public for testing /////////
        const to_account = '0xC04691B99EB731536E35F375ffC85249Ec713222';

        const event = instance.Transfer({ fromBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                _from = result.args._from;
                _to = result.args._to;
                _tokenId = result.args._tokenId.toNumber();
                // console.log(`event Transfer: tokenId = ${_tokenId}; from: ${_from}; to: ${_to}`);
                // assert.equal(tokenId, 1, "SchemeId is not equal 1");
            }
        });

        retval = await instance.getTokensCountByOwner(web3.eth.accounts[0]);
        assert.equal(retval.toNumber(), 10, "error on step 7");

        await instance._transfer(web3.eth.accounts[0], to_account, 1);

        retval = await instance.getTokensCountByOwner(web3.eth.accounts[0]);
        assert.equal(retval.toNumber(), 9, "error on step 8");

        retval = await instance.getTokensCountByOwner(to_account);
        assert.equal(retval.toNumber(), 1, "error on step 9");
    });

    it("6. test _incomeDistribution function", async () => {
        ///////// change internal to public for testing /////////
        const from_account = web3.eth.accounts[0];
        const to_account = '0xC04691B99EB731536E35F375ffC85249Ec713222';
        const price = 1000;
        const tokenId = 1;

        let retval = await instance.getTokenDetails(tokenId);
        const schemeId = retval[5].toNumber();
        assert.equal(schemeId, 2, "schemeId. step 1");

        retval = await instance.getWithdrawBalance(from_account);
        assert.equal(retval.toNumber(), 0, "withdraw balance. step 2");

        retval = await instance.getNumberOfParticipantsForProfitShareScheme(schemeId);
        assert.equal(retval.toNumber(), 3, "participants number. step 3");

        const participant_1_info = await instance.getParticipantOfProfitShareScheme(schemeId, 0);
        const participant_2_info = await instance.getParticipantOfProfitShareScheme(schemeId, 1);
        const participant_3_info = await instance.getParticipantOfProfitShareScheme(schemeId, 2);

        retval = await instance.getWithdrawBalance(participant_1_info[0]);
        assert.equal(retval.toNumber(), 0, "withdraw balance. step 4");

        retval = await instance.getWithdrawBalance(participant_2_info[0]);
        assert.equal(retval.toNumber(), 0, "withdraw balance. step 5");

        retval = await instance.getWithdrawBalance(participant_3_info[0]);
        assert.equal(retval.toNumber(), 0, "withdraw balance. step 6");

        await instance._incomeDistribution(price, tokenId, from_account);

        retval = await instance.getWithdrawBalance(participant_1_info[0]);
        assert.equal(retval.toNumber(), 300, "withdraw balance. step 4");

        retval = await instance.getWithdrawBalance(participant_2_info[0]);
        assert.equal(retval.toNumber(), 600, "withdraw balance. step 5");

        retval = await instance.getWithdrawBalance(participant_3_info[0]);
        assert.equal(retval.toNumber(), 100, "withdraw balance. step 6");

    });

    it("7. test _calculatePlatformProfitShare function", async () => {
        const income = 1000;
        const profitShare = 5;

        await instance.setPlatformProfitShare(profitShare);
        retval = await instance._calculatePlatformProfitShare(income);
        assert.equal(retval[0].toNumber(), 50);
        assert.equal(retval[1].toNumber(), 950);

    });

});
