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
                const retArray = result.args.unacceptedTokens;
                const retNumberOfElements = result.args.numberOfUnaccepted.toNumber();
                console.log(`event LoanCreated:`);
                console.log(`owner - ${retLoanOwner}`);
                console.log(`loan Id - ${retLoanId}`);
                console.log(`count unaccepted - ${retNumberOfElements}`);
                console.log(`array - ${retArray}`);
            }
        });

        /// START preparing
        const tokenOwner = web3.eth.accounts[0];
        const tokenHash = web3.sha3("tokenHash");
        const limitedEdition = 3;
        const profitShareFromSecondarySale = 20;
        const tokenUrl = "http://snark.art";
        const profitShareSchemeId = 1;

        await instance_snarkbase.addToken(
            tokenHash,
            limitedEdition,
            profitShareFromSecondarySale,
            tokenUrl,
            profitShareSchemeId,
            false,
            false,
            { from: tokenOwner }
        );

        let retval = await instance_snarkbase.getOwnerOfToken(1);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error: there isn't any owner for the first token");
        console.log(`owner of 1 token after run addToken: ${retval}`)

        retval = await instance_snarkbase.getOwnerOfToken(2);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error: there isn't any owner for the second token");
        console.log(`owner of 2 token after run addToken: ${retval}`)

        retval = await instance_snarkbase.getOwnerOfToken(3);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error: there isn't any owner for the third token");
        console.log(`owner of 3 token after run addToken: ${retval}`)

        retval = await instance_snarkbase.getTokensCountByOwner(tokenOwner);
        assert.equal(retval.toNumber(), 3, "error on step 1");
        /// END preparing
        
        const borrower = web3.eth.accounts[1];
        const loanCost = 9000000000;
        const startDateTimestamp = (new Date()).getTime() / 1000;
        const duration = 3;
        const tokensIds = [1, 2, 3];

        retval = await instance.getSaleTypeToToken(1);
        assert.equal(retval.toNumber(), 0, "error on step 2");

        retval = await instance.getSaleTypeToToken(2);
        assert.equal(retval.toNumber(), 0, "error on step 3");

        retval = await instance.getSaleTypeToToken(3);
        assert.equal(retval.toNumber(), 0, "error on step 4");

        await instance.createLoan(tokensIds, startDateTimestamp, duration, { from: borrower, value: loanCost });

        retval = await instance.getTokenListForLoan(1);
        assert.equal(retval.length, 3, "error on step 5");
        assert.equal(retval[0], 1, "error on step 6");
        assert.equal(retval[1], 2, "error on step 7");
        assert.equal(retval[2], 3, "error on step 8");

        retval = await instance.getSaleTypeToToken(1);
        assert.equal(retval.toNumber(), 0, "error on step 9");

        retval = await instance.getSaleTypeToToken(2);
        assert.equal(retval.toNumber(), 0, "error on step 10");

        retval = await instance.getSaleTypeToToken(3);
        assert.equal(retval.toNumber(), 0, "error on step 11");
    });

    it("3. test acceptLoan function", async () => {
        const tokenOwner = web3.eth.accounts[0];
        const borrower = web3.eth.accounts[1];

        const eventLoanAccepted = instance.LoanAccepted({ fromBlock: 'latest' });
        eventLoanAccepted.watch(function (error, result) {
            if (!error) {
                const retLoanId = result.args.loanId.toNumber();
                const retTokenOwner = result.args.tokenOwner;
                const retTokenId = result.args.tokenId.toNumber();
                console.log(`event LoanAccepted: owner - ${retTokenOwner}, 
                    loan Id - ${retLoanId}, token Id - ${retTokenId}`);
            }
        });
        
        let retval = await instance.getTokenListForLoan(1);
        assert.equal(retval.length, 3, "error on step 2");

        retval = await instance.getTokenAcceptedStatusListForLoan(1);
        assert.equal(retval.length, 3, "error on step 3");
        assert.equal(retval[0], false, "error on step 4");
        assert.equal(retval[1], false, "error on step 5");
        assert.equal(retval[2], false, "error on step 6");
        
        retval = await instance.getSaleTypeToToken(1);
        assert.equal(retval.toNumber(), 0, "error on step 7");

        retval = await instance.getSaleTypeToToken(2);
        assert.equal(retval.toNumber(), 0, "error on step 8");

        retval = await instance.getSaleTypeToToken(3);
        assert.equal(retval.toNumber(), 0, "error on step 9");

        retval = await instance_snarkbase.getOwnerOfToken(1);
        console.log(`real owner of token (before accept): ${retval}`);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error on step 10");

        retval = await instance.getCurrentTokenOwnerForLoan(1, 1);
        console.log(`current token owner is (before accept): ${retval}`);
        assert.equal(retval, 0, "error on step 11");

        await instance.acceptLoan([1,2], { from: tokenOwner });

        retval = await instance_snarkbase.getOwnerOfToken(1);
        console.log(`real owner of token (before accept): ${retval}`);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error on step 12");

        retval = await instance.getCurrentTokenOwnerForLoan(1, 1);
        console.log(`current token owner is (after accept): ${retval}`);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error on step 13");

        retval = await instance.getTokenAcceptedStatusListForLoan(1);
        assert.equal(retval.length, 3, "error on step 14");
        assert.equal(retval[0], true, "error on step 15");
        assert.equal(retval[1], true, "error on step 16");
        assert.equal(retval[2], false, "error on step 17");

        retval = await instance.getSaleTypeToToken(1);
        assert.equal(retval.toNumber(), 3, "error on step 18");

        retval = await instance.getSaleTypeToToken(2);
        assert.equal(retval.toNumber(), 3, "error on step 19");

        retval = await instance.getSaleTypeToToken(3);
        assert.equal(retval.toNumber(), 0, "error on step 20");
    });

    it("4. test startLoan function", async () => {
        const loanId = 1;
        const tokenOwner = web3.eth.accounts[0];
        const borrower = web3.eth.accounts[1];

        let retval = await instance.getTokenListForLoan(loanId);
        assert.equal(retval.length, 3, "error on step 1");

        retval = await instance.getTokenAcceptedStatusListForLoan(loanId);
        assert.equal(retval.length, 3, "error on step 3");
        assert.equal(retval[0], true, "error on step 4");
        assert.equal(retval[1], true, "error on step 5");
        assert.equal(retval[2], false, "error on step 6");

        retval = await instance.getLoanSaleStatus(loanId);
        assert.equal(retval.toNumber(), 1, "error on step 7");

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        assert.equal(retval.toNumber(), 0, "error on step 8");

        retval = await instance_snarkbase.getWithdrawBalance(borrower);
        assert.equal(retval.toNumber(), 0, "error on step 9");

        retval = await instance_snarkbase.getOwnerOfToken(1);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error on step 10");

        retval = await instance.getCurrentTokenOwnerForLoan(loanId, 1);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error on step 11");

        await instance.startLoan(loanId);

        retval = await instance_snarkbase.getOwnerOfToken(1);
        assert.equal(retval.toUpperCase(), borrower.toUpperCase(), "error on step 12");

        retval = await instance.getCurrentTokenOwnerForLoan(loanId, 1);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error on step 13");

        retval = await instance.getTokenListForLoan(loanId);
        assert.equal(retval.length, 2, "error on step 14");

        retval = await instance.getLoanSaleStatus(loanId);
        assert.equal(retval.toNumber(), 2, "error on step 15");

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        console.log('pendingWithdrawals of token Owner:', retval.toNumber());
        assert.equal(retval.toNumber(), 6000000000, "error on step 16");

        retval = await instance_snarkbase.getWithdrawBalance(borrower);
        console.log('pendingWithdrawals of Borrower:', retval.toNumber());
        assert.equal(retval.toNumber(), 3000000000, "error on step 17");
    });

    it("5. test cancelLoanToken function", async () => {
        const loanId = 1;
        const tokenOwner = web3.eth.accounts[0];
        const borrower = web3.eth.accounts[1];

        let retval = await instance.getTokenListForLoan(loanId);
        assert.equal(retval.length, 2, "error on step 1");

        retval = await instance.getLoanSaleStatus(loanId);
        assert.equal(retval.toNumber(), 2, "error on step 2");

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        assert.equal(retval.toNumber(), 6000000000, "error on step 3");

        retval = await instance_snarkbase.getWithdrawBalance(borrower);
        assert.equal(retval.toNumber(), 3000000000, "error on step 4");

        retval = await instance_snarkbase.getOwnerOfToken(1);
        assert.equal(retval.toUpperCase(), borrower.toUpperCase(), "error on step 5");

        retval = await instance.getCurrentTokenOwnerForLoan(loanId, 1);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error on step 6");

        await instance.cancelLoanToken(1, { from: tokenOwner, value: 3000000000 });

        retval = await instance_snarkbase.getWithdrawBalance(tokenOwner);
        console.log('pendingWithdrawals of token Owner:', retval.toNumber());
        assert.equal(retval.toNumber(), 6000000000, "error on step 7");

        retval = await instance_snarkbase.getWithdrawBalance(borrower);
        console.log('pendingWithdrawals of Borrower:', retval.toNumber());
        assert.equal(retval.toNumber(), 6000000000, "error on step 8");

        retval = await instance.getTokenListForLoan(loanId);
        assert.equal(retval.length, 1, "error on step 9");
    });

    it("6. test stopLoan function", async () => {
        const loanId = 1;
        const tokenOwner = web3.eth.accounts[0];
        const borrower = web3.eth.accounts[1];

        let retval = await instance.getLoanSaleStatus(loanId);
        assert.equal(retval.toNumber(), 2, "error on step 1");
        
        retval = await instance.getTokenListForLoan(loanId);
        assert.equal(retval.length, 1, "error on step 2");
        const tokenId = retval[0].toNumber();

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval.toUpperCase(), borrower.toUpperCase(), "error on step 3");

        retval = await instance.getCurrentTokenOwnerForLoan(loanId, tokenId);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error on step 4");

        retval = await instance.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 3, "error on step 5");

        await instance.stopLoan(loanId);

        retval = await instance.getLoanSaleStatus(loanId);
        assert.equal(retval.toNumber(), 3, "error on step 6");

        retval = await instance.getSaleTypeToToken(tokenId);
        assert.equal(retval.toNumber(), 0, "error on step 7");
        
        retval = await instance.getCurrentTokenOwnerForLoan(loanId, tokenId);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error on step 8");

        retval = await instance_snarkbase.getOwnerOfToken(tokenId);
        assert.equal(retval.toUpperCase(), tokenOwner.toUpperCase(), "error on step 9");
    });
});
