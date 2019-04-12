var SnarkBase = artifacts.require("SnarkBase");
var SnarkLoan = artifacts.require("SnarkLoan");
var SnarkOfferBid = artifacts.require("SnarkOfferBid");
var SnarkERC721 = artifacts.require("SnarkERC721");
var SnarkTestFunctions = artifacts.require("SnarkTestFunctions");

contract('Snark Logic', async (accounts) => {

    before(async () => {
        snarkbase = await SnarkBase.deployed();
        snarkloan = await SnarkLoan.deployed();
        snarkofferbid = await SnarkOfferBid.deployed();
        snarkerc721 = await SnarkERC721.deployed();
        snarktest = await SnarkTestFunctions.deployed();
    });

    // it("test loan list functions for owner", async () => {
    //     const loanOwner = accounts[0];
    //     const loanId_1 = 1;
    //     const loanId_2 = 2;
    //     const loanId_3 = 3;

    //     let countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
    //     assert.equal(countOfLoans, 0, "error on step 1");

    //     let isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_1);
    //     assert.isFalse(isExist, "error on step 2");

    //     isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_2);
    //     assert.isFalse(isExist, "error on step 3");

    //     isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_3);
    //     assert.isFalse(isExist, "error on step 4");

    //     await snarktest.addLoanToLoanListOfLoanOwner(loanOwner, loanId_1);

    //     countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
    //     assert.equal(countOfLoans, 1, "error on step 5");

    //     isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_1);
    //     assert.isTrue(isExist, "error on step 6");

    //     await snarktest.addLoanToLoanListOfLoanOwner(loanOwner, loanId_2);

    //     countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
    //     assert.equal(countOfLoans, 2, "error on step 7");

    //     isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_2);
    //     assert.isTrue(isExist, "error on step 8");

    //     await snarktest.addLoanToLoanListOfLoanOwner(loanOwner, loanId_3);

    //     countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
    //     assert.equal(countOfLoans, 3, "error on step 9");

    //     isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_3);
    //     assert.isTrue(isExist, "error on step 10");

    //     await snarktest.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId_1);

    //     isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_1);
    //     assert.isFalse(isExist, "error on step 11");

    //     countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
    //     assert.equal(countOfLoans, 2, "error on step 12");

    //     await snarktest.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId_2);

    //     isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_2);
    //     assert.isFalse(isExist, "error on step 13");

    //     countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
    //     assert.equal(countOfLoans, 1, "error on step 14");

    //     await snarktest.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId_3);

    //     isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_3);
    //     assert.isFalse(isExist, "error on step 15");

    //     countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
    //     assert.equal(countOfLoans, 0, "error on step 16");

    //     await snarktest.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId_3);

    //     isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_3);
    //     assert.isFalse(isExist, "error on step 17");

    //     countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
    //     assert.equal(countOfLoans, 0, "error on step 18");

    //     await snarktest.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId_1);

    //     isExist = await snarktest.isExistLoanInLoanListOfLoanOwner(loanOwner, loanId_1);
    //     assert.isFalse(isExist, "error on step 19");

    //     countOfLoans = await snarktest.getCountOfLoansForLoanOwner(loanOwner);
    //     assert.equal(countOfLoans, 0, "error on step 20");
    // });

    // it("test ApprovedTokensForLoan array", async () => {
    //     let countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
    //     assert.equal(countOfTokens, 0, "error on step 1");
    //                     //  0  1  2  3  4  5  6
    //     const tokensList = [1, 3, 5, 8, 2, 9, 4];

    //     for (let i = 0; i < tokensList.length; i++) {
    //         await snarktest.addTokenToApprovedListForLoan(tokensList[i]);
    //     }

    //     countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
    //     assert.equal(countOfTokens, tokensList.length, "error on step 2");

    //     for (let i = 0; i < countOfTokens; i++) {
    //         let t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(i);
    //         assert.equal(t, tokensList[i], 'error with tokens order');
    //     }

    //     // delete token id = 8
    //     await snarktest.deleteTokenFromApprovedListForLoan(8);

    //     countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
    //     assert.equal(countOfTokens, tokensList.length - 1, "error on step 3");

    //     let t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
    //     assert.equal(t, 1, "error on step 4");
    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
    //     assert.equal(t, 3, "error on step 5");
    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(2);
    //     assert.equal(t, 5, "error on step 6");
    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(3);
    //     assert.equal(t, 4, "error on step 7");
    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(4);
    //     assert.equal(t, 2, "error on step 8");
    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(5);
    //     assert.equal(t, 9, "error on step 9");
    //     t = await snarktest.isTokenInApprovedListForLoan(8);
    //     assert.isFalse(t);

    //     // delete token id = 1
    //     await snarktest.deleteTokenFromApprovedListForLoan(1);

    //     countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
    //     assert.equal(countOfTokens, tokensList.length - 2, "error on step 10");

    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
    //     assert.equal(t, 9, "error on step 11");
    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
    //     assert.equal(t, 3, "error on step 12");
    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(2);
    //     assert.equal(t, 5, "error on step 13");
    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(3);
    //     assert.equal(t, 4, "error on step 14");
    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(4);
    //     assert.equal(t, 2, "error on step 15");
    //     t = await snarktest.isTokenInApprovedListForLoan(1);
    //     assert.isFalse(t);

    //     await snarktest.deleteTokenFromApprovedListForLoan(9);
    //     t = await snarktest.isTokenInApprovedListForLoan(9);
    //     assert.isFalse(t);
    //     await snarktest.deleteTokenFromApprovedListForLoan(2);
    //     t = await snarktest.isTokenInApprovedListForLoan(2);
    //     assert.isFalse(t);
    //     countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
    //     assert.equal(countOfTokens, tokensList.length - 4, "error on step 16");
    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
    //     assert.equal(t, 4, "error on step 17");
    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
    //     assert.equal(t, 3, "error on step 18");
    //     t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(2);
    //     assert.equal(t, 5, "error on step 19");

    //     await snarktest.deleteTokenFromApprovedListForLoan(4);
    //     await snarktest.deleteTokenFromApprovedListForLoan(3);
    //     await snarktest.deleteTokenFromApprovedListForLoan(5);
    //     countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
    //     assert.equal(countOfTokens, 0, "error on step 20");

    //     await snarktest.deleteTokenFromApprovedListForLoan(54);
    // });

    // it("test new logic of loan", async () => {
    //     let balanceOfERC721 = await snarkerc721.balanceOf(accounts[0]);
    //     assert.equal(balanceOfERC721, 0, "balance is not equal zero before test");

    //     await snarkbase.createProfitShareScheme(accounts[0], [accounts[1], accounts[2]], [20, 80]);
    //     let profitSchemeId = await snarkbase.getProfitShareSchemesTotalCount();

    //     await snarkbase.addToken(
    //         accounts[0],
    //         web3.utils.sha3(`1-tokenHashOf_${accounts[0]}`),
    //         `1-tokenUrlOf_${accounts[0]}`,
    //         'ipfs://decorator.io',
    //         '1-big-secret',
    //         [1, 20, profitSchemeId],
    //         [true, true]
    //     );

    //     await snarkbase.addToken(
    //         accounts[0],
    //         web3.utils.sha3(`2-tokenHashOf_${accounts[0]}`),
    //         `2-tokenUrlOf_${accounts[0]}`,
    //         'ipfs://decorator.io',
    //         '2-big-secret',
    //         [1, 20, profitSchemeId],
    //         [false, false]
    //     );

    //     await snarkbase.createProfitShareScheme(accounts[1], [accounts[0], accounts[2]], [20, 80]);
    //     profitSchemeId = await snarkbase.getProfitShareSchemesTotalCount();

    //     await snarkbase.addToken(
    //         accounts[1],
    //         web3.utils.sha3(`1-tokenHashOf_${accounts[1]}`),
    //         `1-tokenUrlOf_${accounts[1]}`,
    //         'ipfs://decorator.io',
    //         '1-big-secret',
    //         [1, 20, profitSchemeId],
    //         [true, true]
    //     );

    //     await snarkbase.addToken(
    //         accounts[1],
    //         web3.utils.sha3(`2-tokenHashOf_${accounts[1]}`),
    //         `2-tokenUrlOf_${accounts[1]}`,
    //         'ipfs://decorator.io',
    //         '2-big-secret',
    //         [1, 20, profitSchemeId],
    //         [false, false]
    //     );

    //     let totalSupply = await snarkerc721.totalSupply();
    //     assert.equal(totalSupply, 4, "total supply is wrong");

    //     let countApprovedTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
    //     assert.equal(countApprovedTokens.toNumber(), 2, "wrong count of tokens in approved list");

    //     let tokenId = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
    //     assert.equal(tokenId, 1, "tokenId should be equal 1");

    //     tokenId = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
    //     assert.equal(tokenId, 3, "tokenId should be equal 3");
        
    //     // check account[0]
    //     balanceOfERC721 = await snarkerc721.balanceOf(accounts[0]);
    //     assert.equal(balanceOfERC721, 2, "balance of account0 is wrong");

    //     tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 0);
    //     assert.equal(tokenId, 1, "token id should be equal 1");

    //     tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 1);
    //     assert.equal(tokenId, 2, "token id should be equal 2");

    //     let countNotApprovedTokens = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[0]);
    //     assert.equal(countNotApprovedTokens, 1, "wrong number of not approved tokens for account0");

    //     tokenId = await snarktest.getTokenFromNotApprovedTokensForLoanByIndex(accounts[0], 0);
    //     assert.equal(tokenId, 2);
        
    //     // check account[1]
    //     balanceOfERC721 = await snarkerc721.balanceOf(accounts[1]);
    //     assert.equal(balanceOfERC721, 2, "balance of account1 is wrong");

    //     tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 0);
    //     assert.equal(tokenId, 3);

    //     tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 1);
    //     assert.equal(tokenId, 4);

    //     countNotApprovedTokens = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[1]);
    //     assert.equal(countNotApprovedTokens, 1, "wrong number of not approved tokens for account1");

    //     tokenId = await snarktest.getTokenFromNotApprovedTokensForLoanByIndex(accounts[1], 0);
    //     assert.equal(tokenId, 4);

    //     // check account[2]
    //     balanceOfERC721 = await snarkerc721.balanceOf(accounts[2]);
    //     assert.equal(balanceOfERC721, 0, "balance of account2 is wrong");

    //     countNotApprovedTokens = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[2]);
    //     assert.equal(countNotApprovedTokens, 0, "wrong number of not approved tokens for account2");

    //     let isActive = await snarkloanext.isAnyLoanActive();
    //     assert.isFalse(isActive, "Loan is active and it's wrong");
    
    //     await snarkloanext.setActiveLoan(true);

    //     isActive = await snarkloanext.isAnyLoanActive();
    //     assert.isTrue(isActive, "Loan is not active and it's wrong");
    
    //     totalSupply = await snarkerc721.totalSupply();
    //     assert.equal(totalSupply, 4, "total supply is wrong");
        
    //     balanceOfERC721 = await snarkerc721.balanceOf(accounts[0]);
    //     assert.equal(balanceOfERC721, 3, "balance of account0 is wrong");

    //     tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 0);
    //     assert.equal(tokenId, 2, "wrong 1st tokenId for account0");
    //     let ownerOfToken = await snarkerc721.ownerOf(tokenId);
    //     assert.equal(ownerOfToken.toUpperCase(), accounts[0].toUpperCase(), "wrong owner of token");
    //     tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 1);
    //     assert.equal(tokenId, 1, "wrong 2nd tokenId for account0");
    //     ownerOfToken = await snarkerc721.ownerOf(tokenId);
    //     assert.equal(ownerOfToken, accounts[0], "wrong owner of token");
    //     tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 2);
    //     assert.equal(tokenId, 3, "wrong 3th tokenId for account0");
    //     ownerOfToken = await snarkerc721.ownerOf(tokenId);
    //     assert.equal(ownerOfToken, accounts[1], "wrong owner of token");

    //     balanceOfERC721 = await snarkerc721.balanceOf(accounts[1]);
    //     assert.equal(balanceOfERC721, 3, "balance of account1 is wrong");

    //     tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 0);
    //     assert.equal(tokenId, 4, "wrong 1st tokenId for account1");
    //     tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 1);
    //     assert.equal(tokenId, 1, "wrong 2nd tokenId for account1");
    //     tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 2);
    //     assert.equal(tokenId, 3, "wrong 3th tokenId for account1");

    //     balanceOfERC721 = await snarkerc721.balanceOf(accounts[2]);
    //     assert.equal(balanceOfERC721, 2, "balance of account2 is wrong");

    //     tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 0);
    //     assert.equal(tokenId, 1, "wrong 1st tokenId for account2");
    //     tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 1);
    //     assert.equal(tokenId, 3, "wrong 2nd tokenId for account2");

    //     await snarkloanext.setActiveLoan(false);

    //     balanceOfERC721 = await snarkerc721.balanceOf(accounts[0]);
    //     assert.equal(balanceOfERC721, 2, "balance of account0 is wrong");

    //     balanceOfERC721 = await snarkerc721.balanceOf(accounts[1]);
    //     assert.equal(balanceOfERC721, 2, "balance of account1 is wrong");

    //     balanceOfERC721 = await snarkerc721.balanceOf(accounts[2]);
    //     assert.equal(balanceOfERC721, 0, "balance of account2 is wrong");

    // });
});
