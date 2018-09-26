var SnarkLoan = artifacts.require("SnarkLoan");
var SnarkBase = artifacts.require("SnarkBase");

contract('SnarkLoan', async (accounts) => {

    let instance = null;

    before(async () => {
        instance = await SnarkLoan.deployed();
        instance_snarkbase = await SnarkBase.deployed();
    });

    it("1. get size of the SnarkLoan library", async () => {
        const bytecode = instance.constructor._json.bytecode;
        const deployed = instance.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("2. test createLoan function", async () => {
        const eventLoanCreated = instance.LoanCreated({ fromBlock: 'latest' });
        eventLoanCreated.watch(function (error, result) {
            if (!error) {
                const retLoanId = result.args.loanId.toNumber();
                const retLoanOwner = result.args.loanBidOwner;
                const retArray = result.args.unacceptedArtworks;
                const retNumberOfElements = result.args.numberOfUnaccepted.toNumber();
                console.log(`event LoanCreated:`);
                console.log(`owner - ${retLoanOwner}`);
                console.log(`loan Id - ${retLoanId}`);
                console.log(`count unaccepted - ${retNumberOfElements}`);
                console.log(`array - ${retArray}`);
            }
        });

        /// START preparing
        const artworkOwner = web3.eth.accounts[0];
        const artworkHash = web3.sha3("artworkHash");
        const limitedEdition = 3;
        const profitShareFromSecondarySale = 20;
        const artworkUrl = "http://snark.art";
        const profitShareSchemeId = 1;

        await instance_snarkbase.addArtwork(
            artworkHash,
            limitedEdition,
            profitShareFromSecondarySale,
            artworkUrl,
            profitShareSchemeId,
            false,
            false
        );

        let retval = await instance_snarkbase.getTokensCountByOwner(artworkOwner);
        assert.equal(retval.toNumber(), 3, "error on step 1");
        /// END preparing
        
        const borrower = web3.eth.accounts[1];
        const loanCost = 1000000000;
        const startDateTimestamp = (new Date()).getTime() / 1000;
        const duration = 3;
        const artworksIds = [1, 2, 3];

        await instance.createLoan(artworksIds, startDateTimestamp, duration, { from: borrower, value: loanCost });

        retval = await instance.getArtworkListForLoan(1);
        assert.equal(retval.length, 3, "error on step 2");
        assert.equal(retval[0], 1, "error on step 3");
        assert.equal(retval[1], 2, "error on step 4");
        assert.equal(retval[2], 3, "error on step 5");
    });

    it("3. test acceptLoan function", async () => {
        const eventLoanAccepted = instance.LoanAccepted({ fromBlock: 'latest' });
        eventLoanAccepted.watch(function (error, result) {
            if (!error) {
                const retLoanId = result.args.loanId.toNumber();
                const retArtworkOwner = result.args.artworkOwner;
                const retArtworkId = result.args.artworkId.toNumber();
                console.log(`event LoanCreated: owner - ${retArtworkOwner}, 
                    loan Id - ${retLoanId}, artwork Id - ${retArtworkId}`);
            }
        });
        
        let retval = await instance.getArtworkListForLoan(1);
        assert.equal(retval.length, 3, "error on step 2");

        retval = await instance.getArtworkAcceptedStatusListForLoan(1);
        assert.equal(retval.length, 3, "error on step 3");
        assert.equal(retval[0], false, "error on step 4");
        assert.equal(retval[1], false, "error on step 5");
        assert.equal(retval[2], false, "error on step 6");
        
        await instance.acceptLoan([1,2]);

        retval = await instance.getArtworkAcceptedStatusListForLoan(1);
        assert.equal(retval.length, 3, "error on step 3");
        assert.equal(retval[0], true, "error on step 4");
        assert.equal(retval[1], true, "error on step 5");
        assert.equal(retval[2], false, "error on step 6");
    });

    // it("4. test startLoan function", async () => {

    //     let retval = await instance.getArtworkListForLoan(1);
    //     assert.equal(retval.length, 3, "error on step 2");

    // });

});
