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
        const badProfits1 = [ 0, 90 ];
        const badProfits2 = [ 20, 50 ];
        const badProfits3 = [ 60, 70 ];

        let retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 0, "error on step 1");

        const event = instance.ProfitShareSchemeAdded({ fromBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                schemeId = result.args.profitShareSchemeId.toNumber();
                // console.log("SchemeId = ", schemeId);
                // assert.equal(schemeId, 1, "SchemeId is not equal 1");
            }
        });

        try { await instance.createProfitShareScheme(accounts[0], participants, badProfits1); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Percent value has to be greater than zero');
        }

        try { await instance.createProfitShareScheme(accounts[0], participants, badProfits2); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Sum of all percentages has to be equal 100');
        }

        try { await instance.createProfitShareScheme(accounts[0], participants, badProfits3); } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Sum of all percentages has to be equal 100');
        }
        
        await instance.createProfitShareScheme(accounts[0], participants, profits);

        retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 1, "error on step 2");

        retval = await instance.getProfitShareSchemeCountByAddress(accounts[0]);
        assert.equal(retval.toNumber(), 1, "error on step 3");

        retval = await instance.getProfitShareSchemeIdByIndex(accounts[0], 0);
        assert.equal(retval.toNumber(), 1, "error on step 4");

        retval = await instance.getProfitShareParticipantsCount(accounts[0]);
        assert.equal(retval.toNumber(), 2, "error on step 5");
    });

    it("3. test addToken function", async () => {
        const artist = '0x7Af26b6056713AbB900f5dD6A6C45a38F1F70Bc5';
        const tokenHash = web3.sha3("tokenHash");
        const limitedEdition = 10;
        const profitShareFromSecondarySale = 20;
        const tokenUrl = "QmXDeiDv96osHCBdgJdwK2sRD66CfPYmVo4KzS9e9E7Eni";
        const participants = [
            '0xC04691B99EB731536E35F375ffC85249Ec713597', 
            '0xB94691B99EB731536E35F375ffC85249Ec717233'
        ];
        const profits = [ 20, 80 ];
        let profitShareSchemeId = 1;

        let retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 1, "error on step 1");

        retval = await instance.getTokensCount();
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance.getTokensCountByOwner(artist);
        assert.equal(retval.toNumber(), 0, "error on step 3");

        retval = await instance.getNumberOfProfitShareSchemesForOwner(artist);
        assert.equal(retval.toNumber(), 0, "error on step 4");

        const event = instance.TokenCreated({ fromBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                tokenId = result.args.tokenId.toNumber();
                console.log("event TokenCreatedEvent: tokenId = ", tokenId);
                // assert.equal(tokenId, 1, "SchemeId is not equal 1");
            }
        });

        try {
            await instance.addToken(
                artist,
                tokenHash,
                limitedEdition,
                profitShareFromSecondarySale,
                tokenUrl,
                profitShareSchemeId,
                true,
                true
            );
        } catch(e) {
            assert.equal(e.message, 'VM Exception while processing transaction: revert Artist has to have the profit share schemeId');
        }

        await instance.createProfitShareScheme(artist, participants, profits);

        retval = await instance.getNumberOfProfitShareSchemesForOwner(artist);
        assert.equal(retval.toNumber(), 1, "error on step 5");

        profitShareSchemeId = await instance.getProfitShareSchemeIdForOwner(artist, 0);

        await instance.addToken(
            artist,
            tokenHash,
            limitedEdition,
            profitShareFromSecondarySale,
            tokenUrl,
            profitShareSchemeId,
            true,
            true
        );

        retval = await instance.getTokensCount();
        assert.equal(retval.toNumber(), 10, "error on step 6");

        retval = await instance.getTokensCountByOwner(artist);
        assert.equal(retval.toNumber(), 10, "error on step 7");

        retval = await instance.getTokensCountByArtist(artist);
        assert.equal(retval.toNumber(), 10, "error on step 8");
    });

    it("4. test changeProfitShareSchemeForToken function", async () => {
        const participants_prev = [
            '0xC04691B99EB731536E35F375ffC85249Ec713597', 
            '0xB94691B99EB731536E35F375ffC85249Ec717233'
        ];
        const participants = [
            '0xC04691B99EB731536E35F375ffC85249Ec713222', 
            '0xB94691B99EB731536E35F375ffC85249Ec717777',
            '0xB94691B99EB731536E35F375ffC85249Ec717999'
        ];
        const profits = [ 30, 60, 10 ];
        const participants_2 = [
            '0xC04691B99EB731536E35F375ffC85249Ec713228', 
            '0xB94691B99EB731536E35F375ffC85249Ec717779'
        ];
        const profits_2 = [ 70, 30 ];
        const artist = '0x7Af26b6056713AbB900f5dD6A6C45a38F1F70Bc5';

        retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 2, "error on step 1");

        await instance.createProfitShareScheme(artist, participants, profits);
        await instance.createProfitShareScheme(artist, participants_2, profits_2);

        retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 4, "error on step 2");

        retval = await instance.getProfitShareSchemeCountByAddress(artist);
        assert.equal(retval.toNumber(), 3, "error on step 3");

        retval = await instance.getTokensCountByOwner(artist);
        assert.equal(retval.toNumber(), 10, "error on step 4");

        await instance.changeProfitShareSchemeForToken(1, 3, { from: artist });

        retval = await instance.getProfitShareParticipantsCount(artist);
        assert.equal(retval.toNumber(), 7, "error on step 5");

        retval = await instance.getTokenDetail(1);
        assert.equal(retval[6].toNumber(), 3, "error on step 6");

        retval = await instance.getProfitShareParticipantsList(artist);
        assert.equal(retval.length, 7, "error on step 7");
        assert.equal(retval[0].toLowerCase(), participants_prev[0].toLowerCase(), "error on step 8");
        assert.equal(retval[1].toLowerCase(), participants_prev[1].toLowerCase(), "error on step 9");
        assert.equal(retval[2].toLowerCase(), participants[0].toLowerCase(), "error on step 10");
        assert.equal(retval[3].toLowerCase(), participants[1].toLowerCase(), "error on step 11");
        assert.equal(retval[4].toLowerCase(), participants[2].toLowerCase(), "error on step 12");
        assert.equal(retval[5].toLowerCase(), participants_2[0].toLowerCase(), "error on step 13");
        assert.equal(retval[6].toLowerCase(), participants_2[1].toLowerCase(), "error on step 14");
    });

    it("5. test of getListOfAllArtists function", async () => {
        const artist1 = accounts[0];
        const artist2 = accounts[1];
        const artist3 = accounts[2];

        const tokenHash1 = web3.sha3("tokenHash1");
        const tokenHash2 = web3.sha3("tokenHash2");
        const tokenHash3 = web3.sha3("tokenHash3");

        const tokenUrl1 = "QmXDeiDv96osHCBdgJdwK2sRD66CfPYmVo4KzS9e9E7En1";
        const tokenUrl2 = "QmXDeiDv96osHCBdgJdwK2sRD66CfPYmVo4KzS9e9E7En2";
        const tokenUrl3 = "QmXDeiDv96osHCBdgJdwK2sRD66CfPYmVo4KzS9e9E7En3";
        
        const participants1 = [
            '0xC04691B99EB731536E35F375ffC85249Ec713597', 
            '0xB94691B99EB731536E35F375ffC85249Ec717233'
        ];
        const participants2 = [
            '0xC04691B99EB731536E35F375ffC85249Ec713222', 
            '0xB94691B99EB731536E35F375ffC85249Ec717777',
            '0xB94691B99EB731536E35F375ffC85249Ec717999'
        ];
        const participants3 = [
            '0xC04691B99EB731536E35F375ffC85249Ec713222', 
            '0xB94691B99EB731536E35F375ffC85249Ec717744',
            '0xB94691B99EB731536E35F375ffC85249Ec717911'
        ];
        const profits2 = [ 70, 30 ];
        const profits3 = [ 30, 60, 10 ];

        const limitedEdition = 1;
        const profitShareFromSecondarySale = 20;

        let retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 4, "error on step 1");

        retval = await instance.getProfitShareSchemeCountByAddress(artist1);
        assert.equal(retval.toNumber(), 1, "error on step 2");

        retval = await instance.getProfitShareSchemeCountByAddress(artist2);
        assert.equal(retval.toNumber(), 0, "error on step 3");

        retval = await instance.getProfitShareSchemeCountByAddress(artist3);
        assert.equal(retval.toNumber(), 0, "error on step 4");

        await instance.createProfitShareScheme(artist1, participants1, profits2);
        await instance.createProfitShareScheme(artist2, participants2, profits3);
        await instance.createProfitShareScheme(artist3, participants3, profits3);

        retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 7, "error on step 5");

        retval = await instance.getProfitShareSchemeCountByAddress(artist1);
        assert.equal(retval.toNumber(), 2, "error on step 6"); // 5

        retval = await instance.getProfitShareSchemeCountByAddress(artist2);
        assert.equal(retval.toNumber(), 1, "error on step 7"); // 6

        retval = await instance.getProfitShareSchemeCountByAddress(artist3);
        assert.equal(retval.toNumber(), 1, "error on step 8"); // 7

        retval = await instance.getListOfAllArtists();
        const numberOfArtists = retval.length;

        retval = await instance.getTokensCount();
        assert.equal(retval.toNumber(), 10, "error on step 9");

        retval = await instance.getTokensCountByArtist(artist1);
        assert.equal(retval.toNumber(), 0, "error on step 10");

        retval = await instance.getTokensCountByArtist(artist2);
        assert.equal(retval.toNumber(), 0, "error on step 11");

        retval = await instance.getTokensCountByArtist(artist3);
        assert.equal(retval.toNumber(), 0, "error on step 12");

        await instance.addToken(
            artist1,
            tokenHash1,
            limitedEdition,
            profitShareFromSecondarySale,
            tokenUrl1,
            5,
            true,
            true
        );

        await instance.addToken(
            artist2,
            tokenHash2,
            limitedEdition,
            profitShareFromSecondarySale,
            tokenUrl2,
            6,
            true,
            true
        );

        await instance.addToken(
            artist3,
            tokenHash3,
            limitedEdition,
            profitShareFromSecondarySale,
            tokenUrl3,
            7,
            true,
            true
        );

        retval = await instance.getTokensCount();
        assert.equal(retval.toNumber(), 13, "error on step 5");

        retval = await instance.getTokensCountByArtist(artist1);
        assert.equal(retval.toNumber(), 1, "error on step 6");

        retval = await instance.getTokensCountByArtist(artist2);
        assert.equal(retval.toNumber(), 1, "error on step 7");

        retval = await instance.getTokensCountByArtist(artist3);
        assert.equal(retval.toNumber(), 1, "error on step 8");

        retval = await instance.getListOfAllArtists();
        assert.equal(retval.length, numberOfArtists + 3, "error on step 9");
        console.log(retval);

    });

});
