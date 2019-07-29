var SnarkBase = artifacts.require("SnarkBase");
var SnarkLoan = artifacts.require("SnarkLoan");
var SnarkERC721 = artifacts.require("SnarkERC721");
var SnarkTestFunctions = artifacts.require("SnarkTestFunctions");

function pause(millis) {
    var date = Date.now();
    var curDate = null;
    do {
        curDate = Date.now();
    } while (curDate-date < millis);
}

contract('Snark Logic', async (accounts) => {

    before(async () => {
        snarkbase = await SnarkBase.deployed();
        snarkloan = await SnarkLoan.deployed();
        snarkerc721 = await SnarkERC721.deployed();
        snarktest = await SnarkTestFunctions.deployed();
    });

    it("test loan list functions", async () => {
        await snarkbase.changeRestrictAccess(false);
        
        for (let i = 0; i < 3; i++) {
            retval = await snarkerc721.balanceOf(accounts[i]);
            assert.equal(retval.toNumber(), 0, `Balance of accounts[${i}] has to be zero`);
            retval = await snarkbase.getNumberOfProfitShareSchemesForOwner(accounts[i]);
            assert.equal(retval.toNumber(), 0, `number of profit share scheme is not zero for accounts[${i}]`);
            await snarkbase.createProfitShareScheme(accounts[i], [accounts[i+1], accounts[i+2]], [i*10+10, 100-(i*10+10)], { from: accounts[i] });
            retval = await snarkbase.getNumberOfProfitShareSchemesForOwner(accounts[i]);
            assert.equal(retval.toNumber(), 1, `number of profit share scheme is not zero for accounts[${i}]`);
            profitSchemeId = await snarkbase.getProfitShareSchemesTotalCount();
            for (let j = 0; j < 3; j++) {
                await snarkbase.addToken(
                    accounts[i],
                    web3.utils.sha3(`tokenHash${accounts[i]}${j*10}`),
                    `token_url_${accounts[i]}${j*10}`,
                    'ipfs://decorator.io',
                    'big-secret',
                    [1, 20, profitSchemeId],
                    ((j + 1) % 2 == 0),
                    { from: accounts[i] }
                );
            }
            retval = await snarkerc721.balanceOf(accounts[i]);
            assert.equal(retval.toNumber(), 3, `Balance of accounts[${i}] has to be equal 3`);
            // check that each user has 1 token with autoLoan property and 2 token - without
            for (j = 0; j < 3; j++) {
                let tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[i], j);
                let details = await snarkbase.getTokenDetail(tokenId);
                switch(j) {
                    case 0:
                        assert.equal(details[10], false, `Wrong autoloan value for token ${tokenId}`);
                        break;
                    case 1:
                        assert.equal(details[10], true, `Wrong autoloan value for token ${tokenId}`);
                        break;
                    case 2:
                        assert.equal(details[10], false, `Wrong autoloan value for token ${tokenId}`);
                        break;
                    default:
                        break;
                }
            }
            // check amount of tokens in the user's autoLoan list
            retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[i]);
            assert.equal(retval.toNumber(), 2, `number of token with not autoloan for accounts[${i}] is wrong`);

            retval = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
            assert.equal(retval.toNumber(), i+1, "number of tokens in autoloan list is wrong");
        }

        // у accouns[0] token id: 1 (false), 2 (true), 3 (false)
        retval = await snarkerc721.balanceOf(accounts[0]);
        assert.equal(retval.toNumber(), 3, `Balance of accounts[0] has to be 3`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 0);
        assert.equal(retval.toNumber(), 1, "wrong tokenId for accounts[0]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 1);
        assert.equal(retval.toNumber(), 2, "wrong tokenId for accounts[0]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 2);
        assert.equal(retval.toNumber(), 3, "wrong tokenId for accounts[0]");

        // у accouns[1] token id: 4 (false), 5 (true), 6 (false)
        retval = await snarkerc721.balanceOf(accounts[1]);
        assert.equal(retval.toNumber(), 3, `Balance of accounts[1] has to be 3`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 0);
        assert.equal(retval.toNumber(), 4, "wrong tokenId for accounts[1]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 1);
        assert.equal(retval.toNumber(), 5, "wrong tokenId for accounts[1]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 2);
        assert.equal(retval.toNumber(), 6, "wrong tokenId for accounts[1]");
        
        // у accouns[2] token id: 7 (false), 8 (true), 9 (false)
        retval = await snarkerc721.balanceOf(accounts[2]);
        assert.equal(retval.toNumber(), 3, `Balance of accounts[2] has to be 3`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 0);
        assert.equal(retval.toNumber(), 7, "wrong tokenId for accounts[2]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 1);
        assert.equal(retval.toNumber(), 8, "wrong tokenId for accounts[2]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 2);
        assert.equal(retval.toNumber(), 9, "wrong tokenId for accounts[2]");

        retval = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(retval.toNumber(), 3, "number of tokens in autoloan list is wrong");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
        assert.equal(retval.toNumber(), 2, "token id in autoloan list is wrong in position 0");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
        assert.equal(retval.toNumber(), 5, "token id in autoloan list is wrong in position 1");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(2);
        assert.equal(retval.toNumber(), 8, "token id in autoloan list is wrong in position 2");

        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[0]);
        assert.equal(retval.toNumber(), 2, "count tokens in not approved for account[0] is wrong");
        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[1]);
        assert.equal(retval.toNumber(), 2, "count tokens in not approved for account[1] is wrong");
        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[2]);
        assert.equal(retval.toNumber(), 2, "count tokens in not approved for account[1] is wrong");

        // we throw a token from one wallet to another. I expect that the source address will have 
        // only one token in the non-autoloan list, i.e. will be 1. And the second - should be 3 (one more)
        await snarkerc721.transferFrom(accounts[0], accounts[1], 1, { from: accounts[0] });

        retval = await snarkerc721.balanceOf(accounts[0]);
        assert.equal(retval.toNumber(), 2, `Balance of accounts[0] has to be 2`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 0);
        assert.equal(retval.toNumber(), 3, "wrong tokenId for accounts[0]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 1);
        assert.equal(retval.toNumber(), 2, "wrong tokenId for accounts[0]");

        retval = await snarkerc721.balanceOf(accounts[1]);
        assert.equal(retval.toNumber(), 4, `Balance of accounts[0] has to be 4`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 0);
        assert.equal(retval.toNumber(), 4, "wrong tokenId for accounts[1]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 1);
        assert.equal(retval.toNumber(), 5, "wrong tokenId for accounts[1]");        
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 2);
        assert.equal(retval.toNumber(), 6, "wrong tokenId for accounts[1]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 3);
        assert.equal(retval.toNumber(), 1, "wrong tokenId for accounts[1]");

        retval = await snarkerc721.balanceOf(accounts[2]);
        assert.equal(retval.toNumber(), 3, `Balance of accounts[2] has to be 3`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 0);
        assert.equal(retval.toNumber(), 7, "wrong tokenId for accounts[2]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 1);
        assert.equal(retval.toNumber(), 8, "wrong tokenId for accounts[2]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 2);
        assert.equal(retval.toNumber(), 9, "wrong tokenId for accounts[2]");

        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[0]);
        assert.equal(retval.toNumber(), 1, `number of token with not autoloan for accounts[0] is wrong`);
        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[1]);
        assert.equal(retval.toNumber(), 3, `number of token with not autoloan for accounts[1] is wrong`);
        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[2]);
        assert.equal(retval.toNumber(), 2, `number of token with not autoloan for accounts[2] is wrong`);
        
        retval = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(retval.toNumber(), 3, "number of tokens in autoloan list is wrong");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
        assert.equal(retval.toNumber(), 2, "token id in autoloan list is wrong in position 0");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
        assert.equal(retval.toNumber(), 5, "token id in autoloan list is wrong in position 1");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(2);
        assert.equal(retval.toNumber(), 8, "token id in autoloan list is wrong in position 2");

        // create a loans for account[0]
        const _dt_n     = new Date();
        const _year_n   = _dt_n.getFullYear();
        const _month_n  = _dt_n.getMonth();
        const _date_n   = _dt_n.getDate();
        const _hours_n  = _dt_n.getHours();
        const _min_n    = _dt_n.getMinutes();

        const l1s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 1, 0) / 1000;
        const l1f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 2, 0) / 1000;

        await snarkloan.createLoan(l1s, l1f, { from: accounts[0], value: web3.utils.toWei('2', "ether") });

        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[0]);
        assert.equal(retval.toNumber(), 1, `number of token with not autoloan for accounts[0] is wrong`);
        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[1]);
        assert.equal(retval.toNumber(), 3, `number of token with not autoloan for accounts[1] is wrong`);
        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[2]);
        assert.equal(retval.toNumber(), 2, `number of token with not autoloan for accounts[2] is wrong`);
        
        retval = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(retval.toNumber(), 3, "number of tokens in autoloan list is wrong");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
        assert.equal(retval.toNumber(), 2, "token id in autoloan list is wrong in position 0");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
        assert.equal(retval.toNumber(), 5, "token id in autoloan list is wrong in position 1");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(2);
        assert.equal(retval.toNumber(), 8, "token id in autoloan list is wrong in position 2");

        retval = await snarktest.getTotalNumberOfLoansInOwnerList(accounts[0]);
        assert.equal(retval, 1, "count of owner's loans is wrong");

        loanId = await snarktest.getLoanFromOwnerListByIndex(accounts[0], 0);
        retval = await snarkloan.isLoanFinished(loanId);
        assert.isFalse(retval, "loan is finished and it's wrong");

        retval = await snarkloan.getCountOfOwnerLoans(accounts[0]);
        assert.equal(retval, 1, "count of owner's loans is wrong");

        retval = await snarkloan.getListOfLoansOfOwner(accounts[0]);
        assert.equal(retval.length, 1, "length of owner's loan list is wrong");
        assert.equal(retval[0].toNumber(), loanId.toNumber(), "owner's loan id is wrong");

        pause(60000);

        retval = await snarktest.getTotalNumberOfLoansInOwnerList(accounts[0]);
        assert.equal(retval, 1, "count of owner's loans is wrong");

        retval = await snarkloan.isLoanActive(loanId);
        assert.isTrue(retval, "loan is not active and it's wrong");

        retval = await snarkloan.isLoanFinished(loanId);
        assert.isFalse(retval, "loan is finished and it's wrong");
 
        retval = await snarkloan.getCountOfOwnerLoans(accounts[0]);
        assert.equal(retval, 1, "count of owner's loans is wrong");

        retval = await snarkloan.getListOfLoansOfOwner(accounts[0]);
        assert.equal(retval.length, 1, "length of owner's loan list is wrong");
        assert.equal(retval[0].toNumber(), loanId.toNumber(), "owner's loan id is wrong");

        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[0]);
        assert.equal(retval.toNumber(), 1, `number of token with not autoloan for accounts[0] is wrong`);
        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[1]);
        assert.equal(retval.toNumber(), 3, `number of token with not autoloan for accounts[1] is wrong`);
        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[2]);
        assert.equal(retval.toNumber(), 2, `number of token with not autoloan for accounts[2] is wrong`);
        
        retval = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(retval.toNumber(), 3, "number of tokens in autoloan list is wrong");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
        assert.equal(retval.toNumber(), 2, "token id in autoloan list is wrong in position 0");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
        assert.equal(retval.toNumber(), 5, "token id in autoloan list is wrong in position 1");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(2);
        assert.equal(retval.toNumber(), 8, "token id in autoloan list is wrong in position 2");

        // change autoLoan for token 1
        await snarkbase.setTokenAcceptOfLoanRequest(1, true);

        retval = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(retval.toNumber(), 4, "number of tokens in autoloan list is wrong");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
        assert.equal(retval.toNumber(), 2, "token id in autoloan list is wrong in position 0");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
        assert.equal(retval.toNumber(), 5, "token id in autoloan list is wrong in position 1");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(2);
        assert.equal(retval.toNumber(), 8, "token id in autoloan list is wrong in position 2");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(3);
        assert.equal(retval.toNumber(), 1, "token id in autoloan list is wrong in position 3");

        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[0]);
        assert.equal(retval.toNumber(), 1, `number of token with not autoloan for accounts[0] is wrong`);
        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[1]);
        assert.equal(retval.toNumber(), 2, `number of token with not autoloan for accounts[1] is wrong`);
        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[2]);
        assert.equal(retval.toNumber(), 2, `number of token with not autoloan for accounts[2] is wrong`);

        // accounts[0] has to see next tokens: 2, 5, 8, 3
        retval = await snarkerc721.balanceOf(accounts[0]);
        assert.equal(retval.toNumber(), 5, `Balance of accounts[0] has to be 4`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 0);
        assert.equal(retval.toNumber(), 3, "wrong tokenId for accounts[0]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 1);
        assert.equal(retval.toNumber(), 2, "wrong tokenId for accounts[0]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 2);
        assert.equal(retval.toNumber(), 5, "wrong tokenId for accounts[0]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 3);
        assert.equal(retval.toNumber(), 8, "wrong tokenId for accounts[0]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 4);
        assert.equal(retval.toNumber(), 1, "wrong tokenId for accounts[0]");
        
        // check what of tokens accounts[1] can see
        retval = await snarkerc721.balanceOf(accounts[1]);
        assert.equal(retval.toNumber(), 4, `Balance of accounts[1] has to be 4`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 0);
        assert.equal(retval.toNumber(), 4, "wrong tokenId for accounts[1]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 1);
        assert.equal(retval.toNumber(), 5, "wrong tokenId for accounts[1]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 2);
        assert.equal(retval.toNumber(), 6, "wrong tokenId for accounts[1]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 3);
        assert.equal(retval.toNumber(), 1, "wrong tokenId for accounts[1]");

        // check what of tokens accounts[2] can see
        retval = await snarkerc721.balanceOf(accounts[2]);
        assert.equal(retval.toNumber(), 3, `Balance of accounts[2] has to be 3`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 0);
        assert.equal(retval.toNumber(), 7, "wrong tokenId for accounts[2]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 1);
        assert.equal(retval.toNumber(), 8, "wrong tokenId for accounts[2]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 2);
        assert.equal(retval.toNumber(), 9, "wrong tokenId for accounts[2]");

        // during the active loan we will change an autoloan of some token for accouns[1]
        // and check what's going on with visibility of tokens for accounts[0]
        await snarkbase.setTokenAcceptOfLoanRequest(5, false, { from: accounts[1] });

        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[0]);
        assert.equal(retval.toNumber(), 1, `number of token with not autoloan for accounts[0] is wrong`);
        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[1]);
        assert.equal(retval.toNumber(), 3, `number of token with not autoloan for accounts[1] is wrong`);
        retval = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[2]);
        assert.equal(retval.toNumber(), 2, `number of token with not autoloan for accounts[2] is wrong`);
        
        retval = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(retval.toNumber(), 3, "number of tokens in autoloan list is wrong");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
        assert.equal(retval.toNumber(), 2, "token id in autoloan list is wrong in position 0");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
        assert.equal(retval.toNumber(), 1, "token id in autoloan list is wrong in position 1");
        retval = await snarktest.getTokenFromApprovedTokensForLoanByIndex(2);
        assert.equal(retval.toNumber(), 8, "token id in autoloan list is wrong in position 2");

        // accounts[0] have to see next tokens: 3, 2, 1, 8
        retval = await snarkerc721.balanceOf(accounts[0]);
        assert.equal(retval.toNumber(), 4, `Balance of accounts[0] has to be 3`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 0);
        assert.equal(retval.toNumber(), 3, "wrong tokenId for accounts[0]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 1);
        assert.equal(retval.toNumber(), 2, "wrong tokenId for accounts[0]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 2);
        assert.equal(retval.toNumber(), 1, "wrong tokenId for accounts[0]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 3);
        assert.equal(retval.toNumber(), 8, "wrong tokenId for accounts[0]");
        
        // check what of tokens accounts[1] can see
        retval = await snarkerc721.balanceOf(accounts[1]);
        assert.equal(retval.toNumber(), 4, `Balance of accounts[1] has to be 4`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 0);
        assert.equal(retval.toNumber(), 4, "wrong tokenId for accounts[1]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 1);
        assert.equal(retval.toNumber(), 5, "wrong tokenId for accounts[1]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 2);
        assert.equal(retval.toNumber(), 6, "wrong tokenId for accounts[1]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 3);
        assert.equal(retval.toNumber(), 1, "wrong tokenId for accounts[1]");

        // check what of tokens accounts[2] can see
        retval = await snarkerc721.balanceOf(accounts[2]);
        assert.equal(retval.toNumber(), 3, `Balance of accounts[2] has to be 3`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 0);
        assert.equal(retval.toNumber(), 7, "wrong tokenId for accounts[2]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 1);
        assert.equal(retval.toNumber(), 8, "wrong tokenId for accounts[2]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 2);
        assert.equal(retval.toNumber(), 9, "wrong tokenId for accounts[2]");

        pause(60000);

        retval = await snarktest.getTotalNumberOfLoansInOwnerList(accounts[0]);
        assert.equal(retval, 1, "count of owner's loans is wrong");

        retval = await snarkloan.isLoanFinished(loanId);
        assert.isTrue(retval, "loan is finished and it's wrong");

        retval = await snarkloan.getCountOfOwnerLoans(accounts[0]);
        assert.equal(retval, 0, "count of owner's loans is wrong");

        retval = await snarkloan.getListOfLoansOfOwner(accounts[0]);
        assert.equal(retval.length, 0, "length of owner's loan list is wrong");

        // check what ids every accounts see
        retval = await snarkerc721.balanceOf(accounts[0]);
        assert.equal(retval.toNumber(), 2, `Balance of accounts[0] has to be 2`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 0);
        assert.equal(retval.toNumber(), 3, "wrong tokenId for accounts[0]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 1);
        assert.equal(retval.toNumber(), 2, "wrong tokenId for accounts[0]");

        retval = await snarkerc721.balanceOf(accounts[1]);
        assert.equal(retval.toNumber(), 4, `Balance of accounts[0] has to be 4`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 0);
        assert.equal(retval.toNumber(), 4, "wrong tokenId for accounts[1]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 1);
        assert.equal(retval.toNumber(), 5, "wrong tokenId for accounts[1]");        
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 2);
        assert.equal(retval.toNumber(), 6, "wrong tokenId for accounts[1]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 3);
        assert.equal(retval.toNumber(), 1, "wrong tokenId for accounts[1]");

        retval = await snarkerc721.balanceOf(accounts[2]);
        assert.equal(retval.toNumber(), 3, `Balance of accounts[2] has to be 3`);
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 0);
        assert.equal(retval.toNumber(), 7, "wrong tokenId for accounts[2]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 1);
        assert.equal(retval.toNumber(), 8, "wrong tokenId for accounts[2]");
        retval = await snarkerc721.tokenOfOwnerByIndex(accounts[2], 2);
        assert.equal(retval.toNumber(), 9, "wrong tokenId for accounts[2]");

    });

});
