var TestSnarkBaseLib = artifacts.require("TestSnarkBaseLib");

contract('TestSnarkBaseLib', async (accounts) => {

    let instance = null;

    before(async () => {
        instance = await TestSnarkBaseLib.deployed();
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

    it("4. test addToken | totalNumberOfTokens functions", async () => {
        const artistAddress = "0xC04691B99EB731536E35F375ffC85249Ec713597".toUpperCase();
        const tokenHash = web3.sha3("tokenHash");
        const limitedEdition = 1;
        const lastPrice = 5000;
        const profitShareSchemeId = 1;
        const profitShareFromSecondarySale = 20;
        const tokenUrl = "http://snark.art";

        let retval = await instance.getTotalNumberOfTokens();
        assert.equal(retval.toNumber(), 0);

        const event = instance.TokenCreated({ fromBlock: 'latest' });
        event.watch(function (error, result) {
            if (!error) {
                tokenId = result.args._tokenId.toNumber();
                // assert.equal(tokenId, 1, "Token Id is not equal 1");
                // console.log(`Token Id ${tokenId}`);
            }
        });

        await instance.addToken(
            artistAddress,
            tokenHash,
            limitedEdition,
            lastPrice,
            profitShareSchemeId,
            profitShareFromSecondarySale,
            tokenUrl,
            false,
            false
        );

        retval = await instance.getTotalNumberOfTokens();
        assert.equal(retval.toNumber(), 1);

        retval = await instance.getTokenDetails(1);
        assert.equal(retval[0].toUpperCase(), artistAddress.toUpperCase());
        assert.equal(retval[1].toUpperCase(), tokenHash.toUpperCase());
        assert.equal(retval[2].toNumber(), limitedEdition);
        assert.equal(retval[3].toNumber(), 1);
        assert.equal(retval[4].toNumber(), lastPrice);
        assert.equal(retval[5].toNumber(), profitShareSchemeId);
        assert.equal(retval[6].toNumber(), profitShareFromSecondarySale);
        assert.equal(retval[7], tokenUrl);
    });

    it("5. test TokenArtist functions", async () => {
        const val = '0xC04691B99EB731536E35F375ffC85249Ec713597'.toUpperCase();
        const key = 2;

        let retval = await instance.getTokenArtist(key);
        assert.equal(retval, 0);

        await instance.setTokenArtist(key, val);
        retval = await instance.getTokenArtist(key);
        assert.equal(retval.toUpperCase(), val);
    });

    it("6. test TokenLimitedEdition functions", async () => {
        const key1 = 3;
        const val1 = 45;

        let retval = await instance.getTokenLimitedEdition(key1);
        assert.equal(retval, 0);

        await instance.setTokenLimitedEdition(key1, val1);
        retval = await instance.getTokenLimitedEdition(key1);
        assert.equal(retval, val1);
    });

    it("7. test TokenEditionNumber functions", async () => {
        const key1 = 4;
        const key2 = 5;
        const val1 = 1;
        const val2 = 5;

        let retval = await instance.getTokenEditionNumber(key1);
        assert.equal(retval, 0);

        retval = await instance.getTokenEditionNumber(key2)
        assert.equal(retval, 0);

        await instance.setTokenEditionNumber(key1, val1);
        await instance.setTokenEditionNumber(key2, val2);

        retval = await instance.getTokenEditionNumber(key1);
        assert.equal(retval, val1);

        retval = await instance.getTokenEditionNumber(key2)
        assert.equal(retval, val2);
    });

    it("8. test TokenLastPrice functions", async () => {
        const key1 = 6;
        const key2 = 7;
        const val1 = 34;
        const val2 = 98;

        let retval = await instance.getTokenLastPrice(key1);
        assert.equal(retval, 0);

        retval = await instance.getTokenLastPrice(key2);
        assert.equal(retval, 0);

        await instance.setTokenLastPrice(key1, val1);
        await instance.setTokenLastPrice(key2, val2);

        retval = await instance.getTokenLastPrice(key1);
        assert.equal(retval, val1);

        retval = await instance.getTokenLastPrice(key2);
        assert.equal(retval, val2);
    });

    it("9. test TokenHash functions", async () => {
        const key = 8;
        const val = web3.sha3("test_hash_of_token");

        let retval = await instance.getTokenHash(key);
        assert.equal(retval, 0);

        await instance.setTokenHash(key, val);

        retval = await instance.getTokenHash(key);
        assert.equal(retval, val);
    });

    it("10. test TokenProfitShareSchemeId functions", async () => {
        const key = 9;
        const val = 2;

        let retval = await instance.getTokenProfitShareSchemeId(key);
        assert.equal(retval, 0);

        await instance.setTokenProfitShareSchemeId(key, val);

        retval = await instance.getTokenProfitShareSchemeId(key);
        assert.equal(retval, val);
    });

    it("11. test TokenProfitShareFromSecondarySale functions", async () => {
        const key = 10;
        const val = 20;

        let retval = await instance.getTokenProfitShareFromSecondarySale(key);
        assert.equal(retval, 0);

        await instance.setTokenProfitShareFromSecondarySale(key, val);

        retval = await instance.getTokenProfitShareFromSecondarySale(key);
        assert.equal(retval.toNumber(), val);
    });

    it("12. test TokenURL functions", async () => {
        const key = 11;
        const val = "http://snark.art";

        let retval = await instance.getTokenURL(key);
        assert.isEmpty(retval);

        await instance.setTokenURL(key, val);

        retval = await instance.getTokenURL(key);
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

        const event = instance.ProfitShareSchemeCreated({ fromBlock: 'latest' });
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

    it("14. test TokenToOwner functions", async () => {
        const key = 14;

        let retval = await instance.getOwnedTokensCount(web3.eth.accounts[0]);
        assert.equal(retval.toNumber(), 1, "getOwnedTokensCount must be empty");

        await instance.setTokenToOwner(web3.eth.accounts[0], key);

        retval = await instance.getOwnedTokensCount(web3.eth.accounts[0]);
        assert.equal(retval.toNumber(), 2, "getOwnedTokensCount must return 2 element");

        retval = await instance.getTokenIdOfOwner(web3.eth.accounts[0], 1);
        assert.equal(retval.toNumber(), key, "getTokenIdOfOwner returned not a expected token id");

        await instance.deleteTokenFromOwner(0);

        retval = await instance.getOwnedTokensCount(web3.eth.accounts[0]);
        assert.equal(retval.toNumber(), 1, "getOwnedTokensCount must be empty after deleting");
    });

    it("15. test OwnerOfToken functions", async () => {
        const tokenId = 11;
        const emptyOwner = '0x0000000000000000000000000000000000000000';
        const owner1 = '0xC04691B99EB731536E35F375ffC85249Ec713597';
        const owner2 = '0xB94691B99EB731536E35F375ffC85249Ec717233';

        let retval = await instance.getOwnerOfToken(tokenId);
        assert.equal(retval, emptyOwner);

        await instance.setOwnerOfToken(tokenId, owner1);

        retval = await instance.getOwnerOfToken(tokenId);
        assert.equal(retval.toUpperCase(), owner1.toUpperCase());

        await instance.setOwnerOfToken(tokenId, owner2);

        retval = await instance.getOwnerOfToken(tokenId);
        assert.equal(retval.toUpperCase(), owner2.toUpperCase());
    });

    it("16. test TokenToArtist functions", async () => {
        const tokenId = 11;
        const owner1 = '0xC04691B99EB731536E35F375ffC85249Ec713597';
        const owner2 = '0xB94691B99EB731536E35F375ffC85249Ec717233';

        let numberOfTokensForOwner1 = await instance.getNumberOfArtistTokens(owner1);
        numberOfTokensForOwner1 = numberOfTokensForOwner1.toNumber();

        let numberOfTokensForOwner2 = await instance.getNumberOfArtistTokens(owner2);
        numberOfTokensForOwner2 = numberOfTokensForOwner2.toNumber();

        await instance.addTokenToArtistList(tokenId, owner1);

        let retval = await instance.getNumberOfArtistTokens(owner1);
        assert.equal(retval.toNumber(), numberOfTokensForOwner1 + 1, "error on step 3");

        retval = await instance.getNumberOfArtistTokens(owner2);
        assert.equal(retval.toNumber(), numberOfTokensForOwner2, "error on step 4");

        retval = await instance.getTokenIdForArtist(owner1, numberOfTokensForOwner1);
        assert.equal(retval.toNumber(), tokenId, "error on step 5");
    });

    it("17. test TokenHashAsInUse functions", async () => {
        const tokenHash = web3.sha3("TokenHashAsInUse");

        let retval = await instance.getTokenHashAsInUse(tokenHash);
        assert.isFalse(retval);

        await instance.setTokenHashAsInUse(tokenHash, true);

        retval = await instance.getTokenHashAsInUse(tokenHash);
        assert.isTrue(retval);

        await instance.setTokenHashAsInUse(tokenHash, false);
        
        retval = await instance.getTokenHashAsInUse(tokenHash);
        assert.isFalse(retval);
    });

    it("18. test ApprovalsToOperator functions", async () => {
        const owner1 = '0xC04691B99EB731536E35F375ffC85249Ec713597';
        const owner2 = '0xB94691B99EB731536E35F375ffC85249Ec717233';

        let retval = await instance.getApprovalsToOperator(owner1, owner2);
        assert.isFalse(retval);

        await instance.setApprovalsToOperator(owner1, owner2, true);

        retval = await instance.getApprovalsToOperator(owner1, owner2);
        assert.isTrue(retval);

        await instance.setApprovalsToOperator(owner1, owner2, false);

        retval = await instance.getApprovalsToOperator(owner1, owner2);
        assert.isFalse(retval);
    });

    it("19. test ApprovalsToToken functions", async () => {
        const tokenId = 11;
        const owner = '0xC04691B99EB731536E35F375ffC85249Ec713597';
        const operator = web3.eth.accounts[1];

        let retval = await instance.getApprovalsToToken(owner, tokenId);
        assert.equal(retval, 0);

        await instance.setApprovalsToToken(owner, tokenId, operator);

        retval = await instance.getApprovalsToToken(owner, tokenId);
        assert.equal(retval.toUpperCase(), operator.toUpperCase());
    });

    it("20. test TokenToParticipantApproving functions", async () => {
        const tokenId = 11;
        const participant = '0xC04691B99EB731536E35F375ffC85249Ec713597';

        let retval = await instance.getTokenToParticipantApproving(tokenId, participant);
        assert.isFalse(retval);

        await instance.setTokenToParticipantApproving(tokenId, participant, true);

        retval = await instance.getTokenToParticipantApproving(tokenId, participant);
        assert.isTrue(retval);

        await instance.setTokenToParticipantApproving(tokenId, participant, false);

        retval = await instance.getTokenToParticipantApproving(tokenId, participant);
        assert.isFalse(retval);
    });

    it("21. test PendingWithdrawals functions", async () => {
        const balance = 100500;
        const owner = '0xC04691B99EB731536E35F375ffC85249Ec713597';
 
        let retval = await instance.getPendingWithdrawals(owner);
        assert.equal(retval.toNumber(), 0);

        await instance.addPendingWithdrawals(owner, balance);

        retval = await instance.getPendingWithdrawals(owner);
        assert.equal(retval.toNumber(), 100500);

        await instance.subPendingWithdrawals(owner, 500);

        retval = await instance.getPendingWithdrawals(owner);
        assert.equal(retval.toNumber(), 100000);
    });

    it("22. test SaleTypeToToken functions", async () => {
        const tokenId = 12;
        const saleType = 1;

        let retval = await instance.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 0);

        await instance.setSaleTypeToToken(tokenId, saleType);

        retval = await instance.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), saleType);
    });

    it("23. test SaleStatusToToken functions", async () => {
        const tokenId = 1;
        const saleStatus = 2;

        let retval = await instance.getSaleStatusToToken(tokenId);
        assert.equal(retval.toNumber(), 0);

        await instance.setSaleStatusToToken(tokenId, saleStatus);

        retval = await instance.getSaleStatusToToken(tokenId);
        assert.equal(retval.toNumber(), saleStatus);
    });
});
