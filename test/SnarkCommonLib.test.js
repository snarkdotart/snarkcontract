var TestSnarkCommonLib = artifacts.require("TestSnarkCommonLib");
// var TestSnarkBaseLib = artifacts.require("TestSnarkBaseLib");

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

    it("2. test incomeDistribution function", async () => {
        ///////// change internal to public for testing /////////
        const from_account = web3.eth.accounts[0];
        // const to_account = '0xC04691B99EB731536E35F375ffC85249Ec713222';
        const price = 1000;
        const tokenId = 1;

        const participants = [
            '0xC04691B99EB731536E35F375ffC85249Ec713222', 
            '0xB94691B99EB731536E35F375ffC85249Ec717777',
            '0xB94691B99EB731536E35F375ffC85249Ec717999'
        ];
        const profits = [ 30, 60, 10 ];

        await instance.createProfitShareScheme(participants, profits);
        
        let retval = await instance.getProfitShareSchemesTotalCount();
        assert.equal(retval.toNumber(), 1, "error on step 2");

        await instance.changeProfitShareSchemeForToken(1, 1);

        retval = await instance.getArtworkProfitShareSchemeId(tokenId);
        const schemeId = retval.toNumber();
        assert.equal(schemeId, 1, "schemeId. step 1");

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

        await instance.incomeDistribution(price, tokenId, from_account);

        retval = await instance.getWithdrawBalance(participant_1_info[0]);
        assert.equal(retval.toNumber(), 300, "withdraw balance. step 4");

        retval = await instance.getWithdrawBalance(participant_2_info[0]);
        assert.equal(retval.toNumber(), 600, "withdraw balance. step 5");

        retval = await instance.getWithdrawBalance(participant_3_info[0]);
        assert.equal(retval.toNumber(), 100, "withdraw balance. step 6");

    });

    it("3. test calculatePlatformProfitShare function", async () => {
        const income = 1000;
        const profitShare = 5;

        await instance.setPlatformProfitShare(profitShare);
        let retval = await instance.calculatePlatformProfitShare(income);
        assert.equal(retval[0].toNumber(), 50);
        assert.equal(retval[1].toNumber(), 950);
    });

    it("4. test transfer function", async () => {
        const to_account = '0xC04691B99EB731536E35F375ffC85249Ec713222';
        const artist = web3.eth.accounts[0];
        const artworkHash = web3.sha3("artworkHash");
        const limitedEdition = 10;
        const lastPrice = 5000;
        const profitShareSchemeId = 1;
        const profitShareFromSecondarySale = 20;
        const artworkUrl = "http://snark.art";

        await instance.addArtwork(
            artist,
            artworkHash,
            limitedEdition,
            lastPrice,
            profitShareSchemeId,
            profitShareFromSecondarySale,
            artworkUrl,
            true,
            true
        );

        let retval = await instance.getTotalNumberOfArtworks();
        assert.equal(retval.toNumber(), 10, "error on step 0");

        retval = await instance.getNumberOfOwnerArtworks(artist);
        assert.equal(retval.toNumber(), 10, "error on step 1");

        await instance.transferArtwork(1, artist, to_account);

        retval = await instance.getNumberOfOwnerArtworks(artist);
        assert.equal(retval.toNumber(), 9, "error on step 4");

        retval = await instance.getNumberOfOwnerArtworks(to_account);
        assert.equal(retval.toNumber(), 1, "error on step 5");
    });

});
