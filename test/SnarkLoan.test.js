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
            false,
            { from: artworkOwner }
        );

        let retval = await instance_snarkbase.getOwnerOfArtwork(1);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error: there isn't any owner for the first artwork");
        console.log(`owner of 1 artwork after run addArtwork: ${retval}`)

        retval = await instance_snarkbase.getOwnerOfArtwork(2);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error: there isn't any owner for the second artwork");
        console.log(`owner of 2 artwork after run addArtwork: ${retval}`)

        retval = await instance_snarkbase.getOwnerOfArtwork(3);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error: there isn't any owner for the third artwork");
        console.log(`owner of 3 artwork after run addArtwork: ${retval}`)

        retval = await instance_snarkbase.getTokensCountByOwner(artworkOwner);
        assert.equal(retval.toNumber(), 3, "error on step 1");
        /// END preparing
        
        const borrower = web3.eth.accounts[1];
        const loanCost = 9000000000;
        const startDateTimestamp = (new Date()).getTime() / 1000;
        const duration = 3;
        const artworksIds = [1, 2, 3];

        retval = await instance.getSaleTypeToArtwork(1);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance.getSaleTypeToArtwork(2);
        assert.equal(retval.toNumber(), 0, "error on step 3");

        retval = await instance.getSaleTypeToArtwork(3);
        assert.equal(retval.toNumber(), 0, "error on step 4");

        await instance.createLoan(artworksIds, startDateTimestamp, duration, { from: borrower, value: loanCost });

        retval = await instance.getArtworkListForLoan(1);
        assert.equal(retval.length, 3, "error on step 5");
        assert.equal(retval[0], 1, "error on step 6");
        assert.equal(retval[1], 2, "error on step 7");
        assert.equal(retval[2], 3, "error on step 8");

        retval = await instance.getSaleTypeToArtwork(1);
        assert.equal(retval.toNumber(), 0, "error on step 9");

        retval = await instance.getSaleTypeToArtwork(2);
        assert.equal(retval.toNumber(), 0, "error on step 10");

        retval = await instance.getSaleTypeToArtwork(3);
        assert.equal(retval.toNumber(), 0, "error on step 11");
    });

    it("3. test acceptLoan function", async () => {
        const artworkOwner = web3.eth.accounts[0];
        const borrower = web3.eth.accounts[1];

        const eventLoanAccepted = instance.LoanAccepted({ fromBlock: 'latest' });
        eventLoanAccepted.watch(function (error, result) {
            if (!error) {
                const retLoanId = result.args.loanId.toNumber();
                const retArtworkOwner = result.args.artworkOwner;
                const retArtworkId = result.args.artworkId.toNumber();
                console.log(`event LoanAccepted: owner - ${retArtworkOwner}, 
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
        
        retval = await instance.getSaleTypeToArtwork(1);
        assert.equal(retval.toNumber(), 0, "error on step 7");

        retval = await instance.getSaleTypeToArtwork(2);
        assert.equal(retval.toNumber(), 0, "error on step 8");

        retval = await instance.getSaleTypeToArtwork(3);
        assert.equal(retval.toNumber(), 0, "error on step 9");

        retval = await instance_snarkbase.getOwnerOfArtwork(1);
        console.log(`real owner of artwork (before accept): ${retval}`);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error on step 10");

        retval = await instance.getCurrentArtworkOwnerForLoan(1, 1);
        console.log(`current artwork owner is (before accept): ${retval}`);
        assert.equal(retval, 0, "error on step 11");

        await instance.acceptLoan([1,2], { from: artworkOwner });

        retval = await instance_snarkbase.getOwnerOfArtwork(1);
        console.log(`real owner of artwork (before accept): ${retval}`);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error on step 12");

        retval = await instance.getCurrentArtworkOwnerForLoan(1, 1);
        console.log(`current artwork owner is (after accept): ${retval}`);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error on step 13");

        retval = await instance.getArtworkAcceptedStatusListForLoan(1);
        assert.equal(retval.length, 3, "error on step 14");
        assert.equal(retval[0], true, "error on step 15");
        assert.equal(retval[1], true, "error on step 16");
        assert.equal(retval[2], false, "error on step 17");

        retval = await instance.getSaleTypeToArtwork(1);
        assert.equal(retval.toNumber(), 3, "error on step 18");

        retval = await instance.getSaleTypeToArtwork(2);
        assert.equal(retval.toNumber(), 3, "error on step 19");

        retval = await instance.getSaleTypeToArtwork(3);
        assert.equal(retval.toNumber(), 0, "error on step 20");
    });

    it("4. test startLoan function", async () => {
        const loanId = 1;
        const artworkOwner = web3.eth.accounts[0];
        const borrower = web3.eth.accounts[1];

        let retval = await instance.getArtworkListForLoan(loanId);
        assert.equal(retval.length, 3, "error on step 1");

        retval = await instance.getArtworkAcceptedStatusListForLoan(loanId);
        assert.equal(retval.length, 3, "error on step 3");
        assert.equal(retval[0], true, "error on step 4");
        assert.equal(retval[1], true, "error on step 5");
        assert.equal(retval[2], false, "error on step 6");

        retval = await instance.getLoanSaleStatus(loanId);
        assert.equal(retval.toNumber(), 1, "error on step 7");

        retval = await instance_snarkbase.getWithdrawBalance(artworkOwner);
        assert.equal(retval.toNumber(), 0, "error on step 8");

        retval = await instance_snarkbase.getWithdrawBalance(borrower);
        assert.equal(retval.toNumber(), 0, "error on step 9");

        retval = await instance_snarkbase.getOwnerOfArtwork(1);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error on step 10");

        retval = await instance.getCurrentArtworkOwnerForLoan(loanId, 1);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error on step 11");

        await instance.startLoan(loanId);

        retval = await instance_snarkbase.getOwnerOfArtwork(1);
        assert.equal(retval.toUpperCase(), borrower.toUpperCase(), "error on step 12");

        retval = await instance.getCurrentArtworkOwnerForLoan(loanId, 1);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error on step 13");

        retval = await instance.getArtworkListForLoan(loanId);
        assert.equal(retval.length, 2, "error on step 14");

        retval = await instance.getLoanSaleStatus(loanId);
        assert.equal(retval.toNumber(), 2, "error on step 15");

        retval = await instance_snarkbase.getWithdrawBalance(artworkOwner);
        console.log('pendingWithdrawals of token Owner:', retval.toNumber());
        assert.equal(retval.toNumber(), 6000000000, "error on step 16");

        retval = await instance_snarkbase.getWithdrawBalance(borrower);
        console.log('pendingWithdrawals of Borrower:', retval.toNumber());
        assert.equal(retval.toNumber(), 3000000000, "error on step 17");
    });

    it("5. test cancelLoanArtwork function", async () => {
        const loanId = 1;
        const artworkOwner = web3.eth.accounts[0];
        const borrower = web3.eth.accounts[1];

        let retval = await instance.getArtworkListForLoan(loanId);
        assert.equal(retval.length, 2, "error on step 1");

        retval = await instance.getLoanSaleStatus(loanId);
        assert.equal(retval.toNumber(), 2, "error on step 2");

        retval = await instance_snarkbase.getWithdrawBalance(artworkOwner);
        assert.equal(retval.toNumber(), 6000000000, "error on step 3");

        retval = await instance_snarkbase.getWithdrawBalance(borrower);
        assert.equal(retval.toNumber(), 3000000000, "error on step 4");

        retval = await instance_snarkbase.getOwnerOfArtwork(1);
        assert.equal(retval.toUpperCase(), borrower.toUpperCase(), "error on step 5");

        retval = await instance.getCurrentArtworkOwnerForLoan(loanId, 1);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error on step 6");

        await instance.cancelLoanArtwork(1, { from: artworkOwner, value: 3000000000 });

        retval = await instance_snarkbase.getWithdrawBalance(artworkOwner);
        console.log('pendingWithdrawals of token Owner:', retval.toNumber());
        assert.equal(retval.toNumber(), 6000000000, "error on step 7");

        retval = await instance_snarkbase.getWithdrawBalance(borrower);
        console.log('pendingWithdrawals of Borrower:', retval.toNumber());
        assert.equal(retval.toNumber(), 6000000000, "error on step 8");

        retval = await instance.getArtworkListForLoan(loanId);
        assert.equal(retval.length, 1, "error on step 9");
    });

    it("6. test stopLoan function", async () => {
        const loanId = 1;
        const artworkOwner = web3.eth.accounts[0];
        const borrower = web3.eth.accounts[1];

        let retval = await instance.getLoanSaleStatus(loanId);
        assert.equal(retval.toNumber(), 2, "error on step 1");
        
        retval = await instance.getArtworkListForLoan(loanId);
        assert.equal(retval.length, 1, "error on step 2");
        const artworkId = retval[0].toNumber();

        retval = await instance_snarkbase.getOwnerOfArtwork(artworkId);
        assert.equal(retval.toUpperCase(), borrower.toUpperCase(), "error on step 3");

        retval = await instance.getCurrentArtworkOwnerForLoan(loanId, artworkId);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error on step 4");

        retval = await instance.getSaleTypeToArtwork(artworkId);
        assert.equal(retval.toNumber(), 3, "error on step 5");

        await instance.stopLoan(loanId);

        retval = await instance.getLoanSaleStatus(loanId);
        assert.equal(retval.toNumber(), 3, "error on step 6");

        retval = await instance.getSaleTypeToArtwork(artworkId);
        assert.equal(retval.toNumber(), 0, "error on step 7");
        
        retval = await instance.getCurrentArtworkOwnerForLoan(loanId, artworkId);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error on step 8");

        retval = await instance_snarkbase.getOwnerOfArtwork(artworkId);
        assert.equal(retval.toUpperCase(), artworkOwner.toUpperCase(), "error on step 9");
    });
});
