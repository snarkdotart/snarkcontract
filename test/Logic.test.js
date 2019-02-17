var SnarkBase = artifacts.require("SnarkBase");
var SnarkLoan = artifacts.require("SnarkLoan");
var SnarkLoanExt = artifacts.require("SnarkLoanExt");
var SnarkOfferBid = artifacts.require("SnarkOfferBid");
var SnarkERC721 = artifacts.require("SnarkERC721");
var SnarkTestFunctions = artifacts.require("SnarkTestFunctions");

contract('Snark Logic', async (accounts) => {

    before(async () => {
        snarkbase = await SnarkBase.deployed();
        snarkloan = await SnarkLoan.deployed();
        snarkloanext = await SnarkLoanExt.deployed();
        snarkofferbid = await SnarkOfferBid.deployed();
        snarkerc721 = await SnarkERC721.deployed();
        snarktest = await SnarkTestFunctions.deployed();
    });

    it("test loan list functions for owner", async () => {
        const loanOwner = accounts[0];
        const loanId_1 = 1;
        const loanId_2 = 2;
        const loanId_3 = 3;

        let countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
        assert.equal(countOfLoans, 0, "error on step 1");

        let isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_1);
        assert.isFalse(isExist, "error on step 2");

        isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_2);
        assert.isFalse(isExist, "error on step 3");

        isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_3);
        assert.isFalse(isExist, "error on step 4");

        await snarktest.addLoanToLoanListOfLoanOwner(loanOwner, loanId_1);

        countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
        assert.equal(countOfLoans, 1, "error on step 5");

        isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_1);
        assert.isTrue(isExist, "error on step 6");

        await snarktest.addLoanToLoanListOfLoanOwner(loanOwner, loanId_2);

        countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
        assert.equal(countOfLoans, 2, "error on step 7");

        isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_2);
        assert.isTrue(isExist, "error on step 8");

        await snarktest.addLoanToLoanListOfLoanOwner(loanOwner, loanId_3);

        countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
        assert.equal(countOfLoans, 3, "error on step 9");

        isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_3);
        assert.isTrue(isExist, "error on step 10");

        await snarktest.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId_1);

        isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_1);
        assert.isFalse(isExist, "error on step 11");

        countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
        assert.equal(countOfLoans, 2, "error on step 12");

        await snarktest.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId_2);

        isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_2);
        assert.isFalse(isExist, "error on step 13");

        countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
        assert.equal(countOfLoans, 1, "error on step 14");

        await snarktest.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId_3);

        isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_3);
        assert.isFalse(isExist, "error on step 15");

        countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
        assert.equal(countOfLoans, 0, "error on step 16");

        await snarktest.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId_3);

        isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_3);
        assert.isFalse(isExist, "error on step 17");

        countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
        assert.equal(countOfLoans, 0, "error on step 18");

        await snarktest.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId_1);

        isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_1);
        assert.isFalse(isExist, "error on step 19");

        countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
        assert.equal(countOfLoans, 0, "error on step 20");

        let list = await snarktest.getLoansListOfLoanOwner(loanOwner);
        console.log(list);
    });

});
