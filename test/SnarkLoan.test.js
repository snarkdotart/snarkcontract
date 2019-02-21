var SnarkLoan = artifacts.require("SnarkLoan");
var SnarkLoanExt = artifacts.require("SnarkLoanExt");
var SnarkBase = artifacts.require("SnarkBase");
var SnarkStorage = artifacts.require("SnarkStorage");
var SnarkTestFunctions = artifacts.require("SnarkTestFunctions");
var SnarkOfferBid = artifacts.require("SnarkOfferBid");

var datetime = require('node-datetime');
// const BigNumber = require('bignumber.js');
var BN = require("BN.js");

contract('SnarkLoan', async (accounts) => {
    const batchSize = 15;
    const needTokensCount = 150;
    const borrower = accounts[10];

    before(async () => {
        snarkstorage    = await SnarkStorage.deployed();
        snarkbase       = await SnarkBase.deployed();
        snarkofferbid   = await SnarkOfferBid.deployed();
        snarkloan       = await SnarkLoan.deployed();
        snarkloanext    = await SnarkLoanExt.deployed();
        snarktest       = await SnarkTestFunctions.deployed();

        await web3.eth.sendTransaction({
            from:   accounts[0],
            to:     snarkstorage.address, 
            value:  web3.utils.toWei('1', "ether")
        });
    });

    it("1. get size of the SnarkLoan library", async () => {
        const bytecode = snarkloan.constructor._json.bytecode;
        const deployed = snarkloan.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("preparing: add 150 tokens", async () => {
        const limitedEdition = 1;
        const profitShareFromSecondarySale = 20;
        const tokenUrl = "QmXDeiDv96osHCBdgJdwK2sRD66CfPYmVo4KzS9e9E7Eni";
        const decorationUrl = "QmXDeiDv96osHCBdgJdwK2sRD66CfPYmVo4KzS9e9E7Enr";
        const participants = [
            '0xC04691B99EB731536E35F375ffC85249Ec713597', 
            '0x93B68Af3849f518A2cBD0fc6317ac1BBAF21E79F'
        ];
        const profits = [ 20, 80 ];

        await snarkbase.changeRestrictAccess(false);

        for (let i = 0; i < (needTokensCount / batchSize); i++) {
            await snarkbase.createProfitShareScheme(accounts[i], participants, profits);
        }
        
        expect(new BN(await snarkbase.getTokensCount()).toNumber()).to.equal(0);

        for (let i = 1; i < needTokensCount + 1; i++) {

            let accountId = (((i / batchSize) - Math.floor(i / batchSize)) == 0 ) ? 
            Math.floor(i / batchSize) == 0 ? 0 : Math.floor(i / batchSize) - 1 : 
            Math.floor(i / batchSize);

            let tokenHash = web3.utils.sha3(`tokenHash${i}`);
            await snarkbase.addToken(
                accounts[accountId],
                tokenHash,
                tokenUrl,
                decorationUrl,
                '',
                [limitedEdition, profitShareFromSecondarySale, accountId + 1],
                [true, true],
                { from: accounts[accountId] }
            );
        }

        expect(new BN(await snarkbase.getTokensCount()).toNumber()).to.equal(needTokensCount);

        for (i = 0; i < (needTokensCount / batchSize); i++) {
            expect(new BN(await snarkbase.getTokensCountByOwner(accounts[i])).toNumber()).to.equal(batchSize);
            let tokenList = await snarkbase.getTokenListForOwner(accounts[i]);
            console.log(`Tokens list for account[${i}]: ${tokenList}`);
        }
    });

    it("create 15 loans", async () => {
        const loanCost = web3.utils.toWei('0.2', "ether");
        const startDateTimestamp = datetime.create(new Date(2019,4,1)).getTime();
        const duration = 3;

        for (let i = 1; i < needTokensCount + 1; i++) {
            expect(new BN(await snarkbase.getSaleTypeToToken(i)).toNumber()).to.equal(0);
        }

        // const balanceOfBorrowerBeforeCreateLoan = await web3.eth.getBalance(borrower);        
        // const withdrawBalanceOfBorrowerBeforeCreateLoan = await snarkbase.getWithdrawBalance(borrower);
        
        // const balanceOfStorageBeforeCreateLoan = await web3.eth.getBalance(snarkstorage.address);        
        // const withdrawBalanceOfStorageBeforeCreateLoan = await snarkbase.getWithdrawBalance(snarkstorage.address);

        token = 0;
        loanWithEmptySlot = 0;
        for (i = 0; i < batchSize; i++) {
            let tokens = [];
            for (j = 0; j < (needTokensCount / batchSize); j++) {
                let tokens_list_of_current_owner = await snarkbase.getTokenListForOwner(accounts[j]);
                if (i == 5 && j == 5) {
                    token = tokens_list_of_current_owner[i];
                    loanWithEmptySlot = i + 1;
                } else {
                    tokens.push(tokens_list_of_current_owner[i]);
                }
            }
            await snarkloan.createLoan(
                tokens, startDateTimestamp, duration, 
                { from: borrower, value: loanCost }
            );
            console.log(`Created Loan #${i+1} for tokens: ${tokens}`);
        }

        expect(new BN(await snarkloanext.getTotalNumberOfLoans()).toNumber()).to.equal(batchSize);

        const listLoansWithFreeSlots = await snarkloanext.getListOfLoansWithFreeSlots();
        expect(listLoansWithFreeSlots).to.have.lengthOf(1);
        expect(new BN(listLoansWithFreeSlots[0]).toNumber()).to.equal(loanWithEmptySlot);

        let tokenLists = await snarkloan.getTokenListsOfLoanByTypes(loanWithEmptySlot);
        expect(tokenLists.notApprovedTokensList).to.have.length(0);
        expect(tokenLists.approvedTokensList).to.have.length(9);
        expect(tokenLists.declinedTokensList).to.have.length(0);

        await snarkloanext.attachTokensToLoan(loanWithEmptySlot, [token]);

        tokenLists = await snarkloan.getTokenListsOfLoanByTypes(loanWithEmptySlot);
        expect(tokenLists.notApprovedTokensList).to.have.length(0);
        expect(tokenLists.approvedTokensList).to.have.length(10);
        expect(tokenLists.declinedTokensList).to.have.length(0);

        //////////////////////

        // const balanceOfStorageAfterCreateLoan = await web3.eth.getBalance(instance_storage.address);        
        // const withdrawBalanceOfStorageAfterCreateLoan = await instance_snarkbase.getWithdrawBalance(instance_storage.address);

        // assert.equal(
        //     new BigNumber(withdrawBalanceOfStorageBeforeCreateLoan).plus(loanCost).toNumber(),
        //     new BigNumber(withdrawBalanceOfStorageAfterCreateLoan).toNumber(),
        //     "Withdraw balance of storage is wrong after CreateLoan"
        // );

        // assert.equal(
        //     new BigNumber(balanceOfStorageBeforeCreateLoan).plus(loanCost).toNumber(),
        //     new BigNumber(balanceOfStorageAfterCreateLoan).toNumber(),
        //     "Balance of storage wallet is wrong after CreateLoan"
        // );

        // retval = await instance.getTokenListsOfLoanByTypes(1);
        // assert.equal(retval.notApprovedTokensList.length, 3, "error on step 5");
        // assert.equal(retval.approvedTokensList.length, 0, "error on step 6");
        // assert.equal(retval.declinedTokensList.length, 0, "error on step 7");

        // retval = await instance_snarkbase.getSaleTypeToToken(1);
        // assert.equal(retval.toNumber(), 0, "error on step 8");

        // retval = await instance_snarkbase.getSaleTypeToToken(2);
        // assert.equal(retval.toNumber(), 0, "error on step 9");

        // retval = await instance_snarkbase.getSaleTypeToToken(3);
        // assert.equal(retval.toNumber(), 0, "error on step 10");

        // let loanDetail = await instance.getLoanDetail(1);
        // assert.equal(loanDetail.saleStatus, 0, "loan status is not correct before stopLoan");

    });

    // TODO: создать второй и третий лоан
    // TODO: оперировать не днями, а минутами
    // TODO: проверить создание Offer при наличии еще не действующего Loan: должно позволить
    // TODO: проверить создание Offer при наличии действующего Loan: не должно позволить
    // TODO: проверить продажу Offer при наличии еще не действующего Loan: должно позволить продать и исключить токен из Loan
    // TODO: убедиться, что нельзя сделать accept loan, если лоан уже активный или завершенный
    // it("3. test acceptLoan function", async () => {
    //     const tokenOwner = accounts[0];

    //     let retval = await instance.getTokenListsOfLoanByTypes(1);
    //     assert.equal(retval.notApprovedTokensList.length, 3, "error on step 1");
    //     assert.equal(retval.approvedTokensList.length, 0, "error on step 2");
    //     assert.equal(retval.declinedTokensList.length, 0, "error on step 3");
        
    //     retval = await instance_snarkbase.getSaleTypeToToken(1);
    //     assert.equal(retval.toNumber(), 0, "error on step 4");

    //     retval = await instance_snarkbase.getSaleTypeToToken(2);
    //     assert.equal(retval.toNumber(), 0, "error on step 5");

    //     retval = await instance_snarkbase.getSaleTypeToToken(3);
    //     assert.equal(retval.toNumber(), 0, "error on step 6");

    //     retval = await instance_snarkbase.getOwnerOfToken(1);
    //     assert.equal(retval, tokenOwner, "error on step 7");

    //     retval = await instance_snarkbase.getOwnerOfToken(2);
    //     assert.equal(retval, tokenOwner, "error on step 8");

    //     await instance.acceptLoan(1, [1,2], { from: tokenOwner });

    //     retval = await instance_snarkbase.getOwnerOfToken(1);
    //     assert.equal(retval, tokenOwner, "error on step 9");

    //     retval = await instance.getTokenListsOfLoanByTypes(1);
    //     assert.equal(retval.notApprovedTokensList.length, 1, "error on step 10");
    //     assert.equal(retval.approvedTokensList.length, 2, "error on step 11");
    //     assert.equal(retval.declinedTokensList.length, 0, "error on step 12");

    //     retval = await instance_snarkbase.getSaleTypeToToken(1);
    //     assert.equal(retval.toNumber(), 0, "error on step 13");

    //     retval = await instance_snarkbase.getSaleTypeToToken(2);
    //     assert.equal(retval.toNumber(), 0, "error on step 14");

    //     retval = await instance_snarkbase.getSaleTypeToToken(3);
    //     assert.equal(retval.toNumber(), 0, "error on step 15");
    // });

    it("4. test startLoan function", async () => {

        for (i = 0; i < needTokensCount; i++) {
            expect(new BN(await snarkbase.getSaleTypeToToken(i + 1)).toNumber()).to.equal(0);
        }

        // retval = await instance.getTokenListsOfLoanByTypes(loanId);
        // assert.equal(retval.notApprovedTokensList.length, 1, "error on step 2");
        // assert.equal(retval.approvedTokensList.length, 2, "error on step 3");
        // assert.equal(retval.declinedTokensList.length, 0, "error on step 4");
        
        // const loanDetail = await instance.getLoanDetail(loanId);
        // assert.equal(loanDetail.saleStatus.toNumber(), 0, "error on step 5"); // [5]
        // const costOfLoan = loanDetail.loanPrice;
        
        // retval = await instance_snarkbase.getOwnerOfToken(1);
        // assert.equal(retval, tokenOwner, "error on step 6");
        
        // const balanceOfTokenOwnerBeforeStartLoan = await web3.eth.getBalance(tokenOwner);
        // const balanceOfSnarkStorageBeforeStartLoan = await web3.eth.getBalance(instance_storage.address);

        /////////
        for (i = 1; i < batchSize + 1; i++) {
            expect(new BN((await snarkloan.getLoanDetail(i)).saleStatus).toNumber()).to.equal(0);
            await snarkloan.startLoan(i);            
        }

        for (i = 1; i < (needTokensCount / batchSize) + 1; i++) {
            expect(new BN((await snarkloan.getLoanDetail(i)).saleStatus).toNumber()).to.equal(2);
            expect(new BN(await snarkbase.getTokensCountByOwner(accounts[i - 1])).toNumber()).to.equal(15);
        }
        
        for (i = 0; i < needTokensCount; i++) {
            expect(new BN(await snarkbase.getSaleTypeToToken(i + 1)).toNumber()).to.equal(2);
        }

        /////////
        // retval = await instance_snarkbase.getOwnerOfToken(1);
        // assert.equal(retval, tokenOwner, "error on step 7");

        // const balanceOfSnarkStorageAfterStartLoan = await web3.eth.getBalance(instance_storage.address);
        // assert.equal(
        //     new BigNumber(balanceOfSnarkStorageAfterStartLoan).toNumber(),
        //     new BigNumber(balanceOfSnarkStorageBeforeStartLoan).minus(costOfLoan).toNumber(),
        //     "Balance of storage is not correct after StartLoan"
        // );

        // // эта сумма должна перейти полностью к tokenOwner, т.к. в лоане задействованы только его 2 токена
        // const balanceOfTokenOwnerAfterStartLoan = await web3.eth.getBalance(tokenOwner);
        // assert.equal(
        //     new BigNumber(balanceOfTokenOwnerAfterStartLoan).toNumber(),
        //     new BigNumber(balanceOfTokenOwnerBeforeStartLoan).plus(costOfLoan).minus(gasUsedOfStartLoan).toNumber(),
        //     "Balance of token owner is not correct"
        // );        
    });

    it("5. test of borrowLoanedTokens function", async () => {
    //     const loanId = 1;
    //     const costOfStop = web3.utils.toWei('0.001', 'ether');
    //     let loanDetail = await instance.getLoanDetail(loanId);
    //     const borrower = loanDetail.loanOwner;

    for (let i = 1; i < batchSize + 1; i++) {
        await snarkloan.borrowLoanedTokens(i, { from: borrower }); // , value: web3.utils.toWei('0.0001', 'ether')
    }

    for (i = 1; i < needTokensCount + 1; i++) {
        expect(await snarkbase.getOwnerOfToken(i)).to.equal(borrower);
    }


    //     try {
    //         await instance.borrowLoanedTokens(loanId, { from: accounts[10], value: web3.utils.toWei('0.0001', 'ether') });
    //     } catch(e) {
    //         assert.equal(
    //             e.message, 
    //             'Returned error: VM Exception while processing transaction: revert Only loan owner can borrow tokens -- Reason given: Only loan owner can borrow tokens.', 
    //             'exception should occur due to wrong loan owner'
    //         );
    //     }

    //     await instance_loanext.setCostOfStopLoanOperationForLoan(loanId, costOfStop);

    //     try {
    //         await instance.borrowLoanedTokens(loanId, { from: borrower, value: web3.utils.toWei('0.001', 'ether') });
    //     } catch(e) {
    //         assert.equal(
    //             e.message,
    //             'Returned error: VM Exception while processing transaction: revert The amount of funds received is less than the required. -- Reason given: The amount of funds received is less than the required.',
    //             'exeption shoud occur due to wrong amount of funds'
    //         );
    //     }

    //     const snark = await instance_snarkbase.getSnarkWalletAddressAndProfit();

    //     const balanceOfSnarkWalletBefore = await web3.eth.getBalance(snark.snarkWalletAddr);
    //     const balanceOfBorrowerBefore = await web3.eth.getBalance(borrower);

    //     tx = await instance.borrowLoanedTokens(loanId, { from: borrower, value: costOfStop });
    //     const gasUsedOfBorrowLoanedTokens = tx.receipt.gasUsed;

    //     const balanceOfSnarkWalletAfter = await web3.eth.getBalance(snark.snarkWalletAddr);
    //     const balanceOfBorrowerAfter = await web3.eth.getBalance(borrower);
        
    //     assert.equal(
    //         new BigNumber(balanceOfSnarkWalletAfter).toNumber(),
    //         new BigNumber(balanceOfSnarkWalletBefore).plus(costOfStop).toNumber(),
    //         'Balance of storage is not correct'
    //     );

    //     assert.equal(
    //         new BigNumber(balanceOfBorrowerAfter).toNumber(),
    //         new BigNumber(balanceOfBorrowerBefore).minus(gasUsedOfBorrowLoanedTokens).minus(costOfStop).toNumber(),
    //         'Balance of borrower is not correct'
    //     );
        
    //     const tokensList = await instance.getTokenListsOfLoanByTypes(loanId);

    //     assert.equal(tokensList.notApprovedTokensList.length, 0, "count of tokens in notApprovedTokensList is wrong");
    //     assert.equal(tokensList.approvedTokensList.length, 2, "count of tokens in approvedTokensList is wrong");
    //     assert.equal(tokensList.declinedTokensList.length, 1, "count of tokens in declinedTokensList is wrong");

    //     for (let i = 0; i < tokensList.approvedTokensList.length; i++) {
    //         let retval = await instance_snarkbase.getOwnerOfToken(tokensList.approvedTokensList[i]);
    //         assert.equal(retval, borrower, `wrong owner of token ${tokensList.approvedTokensList[i]}`);
    //     }

    //     loanDetail = await instance.getLoanDetail(loanId);
    //     assert.equal(loanDetail.saleStatus, 2, "loan status is not correct");
    });

    it("6. test stopLoan function", async () => {
    //     const loanId = 1;

    //     let loanDetail = await instance.getLoanDetail(loanId);
    //     assert.equal(loanDetail.saleStatus, 2, "loan status is not correct before stopLoan");

    //     let loanListOfBorrower = await instance_loanext.getLoansListOfLoanOwner(loanDetail.loanOwner);
    //     assert.equal(loanListOfBorrower.length, 1, 'length of loans list is not correct before stopLoan');
    console.log(`List of Loans before stoping: ${await snarkloanext.getLoansListOfLoanOwner(borrower)}`);
    const loansOrderToRemove = [1, 15, 2, 5, 3, 7, 12, 4, 10, 14, 6, 9, 13, 8, 11];
    for (let i = 0; i < loansOrderToRemove.length; i++) {
        let loanId = loansOrderToRemove[i];
        let loanDetail = await snarkloan.getLoanDetail(loanId);
        
        expect(new BN(loanDetail.saleStatus).toNumber()).to.equal(2);
        
        let tokensList = await snarkloan.getTokenListsOfLoanByTypes(loanId);
        for (let j = 0; j < tokensList.length; j++) {
            expect(await snarkbase.getOwnerOfToken(tokensList[j])).to.equal(borrower);
        }
        
        await snarkloan.stopLoan(loanId);

        console.log(`List of Loans after stoping loan #${loanId}: ${await snarkloanext.getLoansListOfLoanOwner(borrower)}`);

        loanDetail = await snarkloan.getLoanDetail(loanId);
        expect(new BN(loanDetail.saleStatus).toNumber()).to.equal(3);

        tokensList = await snarkloan.getTokenListsOfLoanByTypes(loanId);
        for (j = 0; j < tokensList.length; j++) {
            expect(await snarkbase.getOwnerOfToken(tokensList[j])).to.not.equal(borrower);
        }
    }
      
    for (i = 1; i < needTokensCount + 1; i++) {
        let accountId = (((i / batchSize) - Math.floor(i / batchSize)) == 0 ) ? 
        Math.floor(i / batchSize) == 0 ? 0 : Math.floor(i / batchSize) - 1 : 
        Math.floor(i / batchSize);
        expect(await snarkbase.getOwnerOfToken(i)).to.equal(accounts[accountId]);
    }

    for (i = 0; i < (needTokensCount / batchSize); i++) {
        expect(new BN(await snarkbase.getTokensCountByOwner(accounts[i])).toNumber()).to.equal(batchSize);
        let tokenList = await snarkbase.getTokenListForOwner(accounts[i]);
        console.log(`Returned tokens for account[${i}]: ${tokenList}`);
    }

    //     loanDetail = await instance.getLoanDetail(loanId);
    //     assert.equal(loanDetail.saleStatus, 3, "loan status is not correct after stopLoan");

    //     loanListOfBorrower = await instance_loanext.getLoansListOfLoanOwner(loanDetail.loanOwner);
    //     assert.equal(loanListOfBorrower.length, 0, 'length of loans list is not correct after stopLoan');

    //     const tokensList = await instance.getTokenListsOfLoanByTypes(loanId);

    //     for (let i = 0; i < tokensList.approvedTokensList.length; i++) {
    //         let retval = await instance_snarkbase.getOwnerOfToken(tokensList.approvedTokensList[i]);
    //         assert.notEqual(retval, loanDetail.loanOwner, `wrong owner of token ${tokensList.approvedTokensList[i]}`);
    //         retval = await instance_snarkbase.getSaleTypeToToken(tokensList.approvedTokensList[i]);
    //         assert.equal(retval, 0, `sale status is not correct for token ${tokensList.approvedTokensList[i]}`);
    //     }

    });

    // it("7. test deleteLoan function", async () => {
    //     const loanId = 1;
    //     const tokenOwner = accounts[0];
    //     const borrower = accounts[1];
    //     const loanCost = web3.utils.toWei('0.6', "ether");
    //     const startDateTimestamp = datetime.create(new Date(2019,2,1)).getTime();
    //     const duration = 3;
    //     const tokensIds = [1, 2, 3];

    //     let loanDetail = await instance.getLoanDetail(loanId);
    //     assert.equal(loanDetail.saleStatus, 3, "loan status is not correct before deleteLoan");

    //     try {
    //         await instance.deleteLoan(loanId);
    //     } catch(e) {
    //         assert.equal(
    //             e.message, 
    //             'Returned error: VM Exception while processing transaction: revert Only loan owner can borrow tokens -- Reason given: Only loan owner can borrow tokens.', 
    //             'Must not be impossible to delete the loan because of its sale status'
    //         );
    //     }

    //     let retval = await instance_snarkbase.getTokensCount();
    //     assert.equal(retval.toNumber(), 3, "amount of token is not correct");

    //     for (let i = 0; i < 3; i++) {
    //         let detail = await instance_snarkbase.getTokenDetail(i + 1);
    //         assert.equal(detail.currentOwner, tokenOwner, 'token owner is not correct');
    //         assert.equal(detail.isAcceptOfLoanRequestFromSnark, false, `isAcceptOfLoanRequestFromSnark is wrong for token ${i+1}`);
    //         assert.equal(detail.isAcceptOfLoanRequestFromOthers, false, `isAcceptOfLoanRequestFromOthers is wrong for token ${i+1}`);
    //     }

    //     let countOfLoan = await instance_loanext.getLoansListOfLoanOwner(borrower);
    //     assert.equal(countOfLoan.length, 0, 'Wrong number of loans belong to borrower');

    //     await instance.createLoan(
    //         tokensIds, startDateTimestamp, duration, 
    //         { from: borrower, value: loanCost }
    //     );

    //     const idOfNewLoan = await instance_loanext.getTotalNumberOfLoans();
    //     assert.equal(idOfNewLoan, 2, 'Amount of loans is wrong after createLoan function');

    //     countOfLoan = await instance_loanext.getLoansListOfLoanOwner(borrower);
    //     assert.equal(countOfLoan.length, 1, 'Wrong number of loans belong to borrower after createLoan function');

    //     loanDetail = await instance.getLoanDetail(idOfNewLoan);
    //     assert.equal(loanDetail.saleStatus.toNumber(), 0, "Sale status is wrong of new loan after createLoan function");
    //     assert.equal(loanDetail.loanPrice, loanCost, 'Price is wrong after creating loan');

    //     let tokensList = await instance.getTokenListsOfLoanByTypes(idOfNewLoan);
    //     assert.equal(tokensList.notApprovedTokensList.length, 3, "notApprovedTokensList is wrong after creating new loan");
    //     assert.equal(tokensList.approvedTokensList.length, 0, "approvedTokensList is wrong after creating new loan");
    //     assert.equal(tokensList.declinedTokensList.length, 0, "declinedTokensList is wrong after creating new loan");

    //     const balanceOfBorrowerBeforeDeleteLoan = await web3.eth.getBalance(borrower);

    //     const tx = await instance.deleteLoan(idOfNewLoan, { from: borrower });
    //     const costOfT = tx.receipt.gasUsed;

    //     const balanceOfBorrowerAfterDeleteLoan = await web3.eth.getBalance(borrower);
    //     assert.equal(
    //         new BigNumber(balanceOfBorrowerBeforeDeleteLoan).plus(loanCost).minus(costOfT).toNumber(),
    //         new BigNumber(balanceOfBorrowerAfterDeleteLoan).toNumber(),
    //         'Balance of borrower is wrong after delete loan'
    //     );

    //     countOfLoan = await instance_loanext.getLoansListOfLoanOwner(borrower);
    //     assert.equal(countOfLoan.length, 0, 'Wrong number of loans belong to borrower after deleteLoan function');

    //     loanDetail = await instance.getLoanDetail(idOfNewLoan);
    //     assert.equal(loanDetail.saleStatus, 3, "loan status is not correct before deleteLoan");

    // });

    // it("8. test cancelTokensInLoan function", async () => {
    //     const tokenOwner = accounts[0];
    //     const borrower = accounts[1];
    //     const loanCost = web3.utils.toWei('0.6', "ether");
    //     const startDateTimestamp = datetime.create(new Date(2019,2,1)).getTime();
    //     const duration = 3;
    //     const tokensIds = [1, 2, 3];

    //     let countOfLoan = await instance_loanext.getLoansListOfLoanOwner(borrower);
    //     assert.equal(countOfLoan.length, 0, 'Wrong number of loans belong to borrower');

    //     const balanceOfStorageBeforeCreateLoan = await web3.eth.getBalance(instance_storage.address);
    //     const withdrawBalanceOfStorageBeforeCreateLoan = await instance_snarkbase.getWithdrawBalance(instance_storage.address);

    //     await instance.createLoan(
    //         tokensIds, startDateTimestamp, duration, 
    //         { from: borrower, value: loanCost }
    //     );

    //     const balanceOfStorageAfterCreateLoan = await web3.eth.getBalance(instance_storage.address);
    //     const withdrawBalanceOfStorageAfterCreateLoan = await instance_snarkbase.getWithdrawBalance(instance_storage.address);
        
    //     assert.equal(
    //         new BigNumber(withdrawBalanceOfStorageAfterCreateLoan).toNumber(),
    //         new BigNumber(withdrawBalanceOfStorageBeforeCreateLoan).plus(loanCost).toNumber(),
    //         "Balance of withdraw balance of storage after create loan is not match"
    //     );

    //     assert.equal(
    //         new BigNumber(balanceOfStorageAfterCreateLoan).toNumber(),
    //         new BigNumber(balanceOfStorageBeforeCreateLoan).plus(loanCost).toNumber(),
    //         "Balance of storage is wrong after create laon"
    //     );

    //     const loanId = await instance_loanext.getTotalNumberOfLoans();
    //     assert.equal(loanId, 3, 'Amount of loans is wrong after createLoan function');

    //     loanDetail = await instance.getLoanDetail(loanId);
    //     assert.equal(loanDetail.saleStatus.toNumber(), 0, "Sale status is wrong of new loan after createLoan function");
    //     assert.equal(loanDetail.loanPrice, loanCost, 'Price is wrong after creating loan');

    //     let tokensList = await instance.getTokenListsOfLoanByTypes(loanId);
    //     assert.equal(tokensList.notApprovedTokensList.length, 3, "notApprovedTokensList is wrong after creating new loan");
    //     assert.equal(tokensList.approvedTokensList.length, 0, "approvedTokensList is wrong after creating new loan");
    //     assert.equal(tokensList.declinedTokensList.length, 0, "declinedTokensList is wrong after creating new loan");

    //     for (let i = 0; i < tokensList.approvedTokensList.length; i++) {
    //         let retval = await instance_snarkbase.getOwnerOfToken(tokensList.approvedTokensList[i]);
    //         assert.notEqual(retval, tokenOwner, `wrong owner of token ${tokensList.approvedTokensList[i]}`);
            
    //         retval = await instance_snarkbase.getSaleTypeToToken(tokensList.approvedTokensList[i]);
    //         assert.equal(retval, 0, `sale status is not correct for token ${tokensList.approvedTokensList[i]}`);
            
    //         retval = await instance.getListOfNotFinishedLoansForToken(tokensList.approvedTokensList[i]);
    //         assert.equal(retval.length, 1, 'list of loans for token id is not correct');
    //         assert.equal(retval[0], loanId, 'LoanId is wrong for current tokenId');
    //     }

    //     tokenId = 1;
    //     await instance.cancelTokensInLoan([tokenId], loanId);

    //     const balanceOfStorageAfterCancelTokensInLoan = await web3.eth.getBalance(instance_storage.address);
    //     const withdrawBalanceOfStorageAfterCancelTokensInLoan = await instance_snarkbase.getWithdrawBalance(instance_storage.address);

    //     assert.equal(
    //         new BigNumber(balanceOfStorageAfterCreateLoan).toNumber(),
    //         new BigNumber(balanceOfStorageAfterCancelTokensInLoan).toNumber(),
    //         "Balance of storage is wrong after cancel tokens in loan"
    //     );

    //     assert.equal(
    //         new BigNumber(withdrawBalanceOfStorageAfterCreateLoan).toNumber(),
    //         new BigNumber(withdrawBalanceOfStorageAfterCancelTokensInLoan).toNumber(),
    //         "Withdraw balance of storage is wrong after cancel tokens in loan"
    //     );

    //     tokensList = await instance.getTokenListsOfLoanByTypes(loanId);
    //     assert.equal(tokensList.notApprovedTokensList.length, 2, "notApprovedTokensList is wrong after creating new loan");
    //     assert.equal(tokensList.approvedTokensList.length, 0, "approvedTokensList is wrong after creating new loan");
    //     assert.equal(tokensList.declinedTokensList.length, 0, "declinedTokensList is wrong after creating new loan");

    //     tokenId = 3;
    //     t = await instance_test.getTypeOfTokenListForLoan(loanId, tokenId);

    //     tokenId = await instance_test.getTokenForLoanListByTypeAndIndex(loanId, t, 0);
    //     assert.equal(tokenId, 3, 'Returned a wrong token id');

    //     retval = await instance_snarkbase.getOwnerOfToken(1);
    //     assert.equal(retval, tokenOwner, 'Token owner of token 1 is not correct after cancelTokensInLoan');
    //     retval = await instance_snarkbase.getOwnerOfToken(2);
    //     assert.equal(retval, tokenOwner, 'Token owner of token 2 is not correct after cancelTokensInLoan');
    //     retval = await instance_snarkbase.getOwnerOfToken(3);
    //     assert.equal(retval, tokenOwner, 'Token owner of token 3 is not correct after cancelTokensInLoan');

    //     tokensList = await instance.getTokenListsOfLoanByTypes(loanId);
    //     assert.equal(tokensList.notApprovedTokensList.length, 2, "notApprovedTokensList is wrong after creating new loan");
    //     assert.equal(tokensList.approvedTokensList.length, 0, "approvedTokensList is wrong after creating new loan");
    //     assert.equal(tokensList.declinedTokensList.length, 0, "declinedTokensList is wrong after creating new loan");

    //     await instance.acceptLoan(loanId, [2,3]);

    //     tokensList = await instance.getTokenListsOfLoanByTypes(loanId);
    //     assert.equal(tokensList.notApprovedTokensList.length, 0, "notApprovedTokensList is wrong after acceptin loan");
    //     assert.equal(tokensList.approvedTokensList.length, 2, "approvedTokensList is wrong after acceptin loan");
    //     assert.equal(tokensList.declinedTokensList.length, 0, "declinedTokensList is wrong after acceptin loan");

    //     retval = await instance_snarkbase.getOwnerOfToken(1);
    //     assert.equal(retval, tokenOwner, 'Token owner of token 1 is not correct after acceptLoan');
    //     retval = await instance_snarkbase.getOwnerOfToken(2);
    //     assert.equal(retval, tokenOwner, 'Token owner of token 2 is not correct after acceptLoan');
    //     retval = await instance_snarkbase.getOwnerOfToken(3);
    //     assert.equal(retval, tokenOwner, 'Token owner of token 3 is not correct after acceptLoan');

    //     const balanceOfStorageAfterAcceptLoan = await web3.eth.getBalance(instance_storage.address);
    //     const withdrawBalanceOfStorageAfterAcceptLoan = await instance_snarkbase.getWithdrawBalance(instance_storage.address);

    //     assert.equal(
    //         new BigNumber(balanceOfStorageAfterCreateLoan).toNumber(),
    //         new BigNumber(balanceOfStorageAfterAcceptLoan).toNumber(),
    //         "Balance of storage is wrong after accept loan"
    //     );

    //     assert.equal(
    //         new BigNumber(withdrawBalanceOfStorageAfterCreateLoan).toNumber(),
    //         new BigNumber(withdrawBalanceOfStorageAfterAcceptLoan).toNumber(),
    //         "Withdraw balance of storage is wrong after accept loan"
    //     );

    //     await instance.startLoan(loanId);
    //     await instance.borrowLoanedTokens(loanId, { from: borrower, value: loanCost });

    //     tokensList = await instance.getTokenListsOfLoanByTypes(loanId);
    //     assert.equal(tokensList.notApprovedTokensList.length, 0, "notApprovedTokensList is wrong after acceptin loan");
    //     assert.equal(tokensList.approvedTokensList.length, 2, "approvedTokensList is wrong after acceptin loan");
    //     assert.equal(tokensList.declinedTokensList.length, 0, "declinedTokensList is wrong after acceptin loan");

    //     retval = await instance_snarkbase.getOwnerOfToken(1);
    //     assert.equal(retval, tokenOwner, 'Token owner of token 1 is not correct after startLoan');
    //     retval = await instance_snarkbase.getOwnerOfToken(2);
    //     assert.equal(retval, borrower, 'Token owner of token 2 is not correct after starttLoan');
    //     retval = await instance_snarkbase.getOwnerOfToken(3);
    //     assert.equal(retval, borrower, 'Token owner of token 3 is not correct after startLoan');

    //     const balanceOfStorageAfterStartLoan = await web3.eth.getBalance(instance_storage.address);
    //     const withdrawBalanceOfStorageAfterStartLoan = await instance_snarkbase.getWithdrawBalance(instance_storage.address);

    //     assert.equal(
    //         new BigNumber(balanceOfStorageAfterAcceptLoan).minus(loanCost).toNumber(),
    //         new BigNumber(balanceOfStorageAfterStartLoan).toNumber(),
    //         "Balance of storage is wrong after start loan"
    //     );

    //     assert.equal(
    //         new BigNumber(withdrawBalanceOfStorageAfterAcceptLoan).minus(loanCost).toNumber(),
    //         new BigNumber(withdrawBalanceOfStorageAfterStartLoan).toNumber(),
    //         "Withdraw balance of storage is wrong after start loan"
    //     );

    //     await instance.cancelTokensInLoan([2,3], loanId);

    //     retval = await instance_snarkbase.getOwnerOfToken(1);
    //     assert.equal(retval, tokenOwner, 'Token owner of token 1 is not correct after cancelTokensInLoan');
    //     retval = await instance_snarkbase.getOwnerOfToken(2);
    //     assert.equal(retval, tokenOwner, 'Token owner of token 2 is not correct after cancelTokensInLoan');
    //     retval = await instance_snarkbase.getOwnerOfToken(3);
    //     assert.equal(retval, tokenOwner, 'Token owner of token 3 is not correct after cancelTokensInLoan');

    //     // loan is in an active sale state and it's a reason why we can't run a deleteLoan function
    //     loanDetail = await instance.getLoanDetail(loanId);
    //     assert.equal(loanDetail.saleStatus, 2, "loan status is not correct after cancelTokensInLoan");

    //     tokensList = await instance.getTokenListsOfLoanByTypes(loanId);
    //     assert.equal(tokensList.notApprovedTokensList.length, 0, "notApprovedTokensList is wrong after cancelTokensInLoan");
    //     assert.equal(tokensList.approvedTokensList.length, 0, "approvedTokensList is wrong after cancelTokensInLoan");
    //     assert.equal(tokensList.declinedTokensList.length, 0, "declinedTokensList is wrong after cancelTokensInLoan");

    //     await instance.stopLoan(loanId);

    //     loanDetail = await instance.getLoanDetail(loanId);
    //     assert.equal(loanDetail.saleStatus, 3, "loan status is not correct after cancelTokensInLoan");
    // });

    // it("9. test situation when there is offer to the token", async () => {
    //     // Я распределил атомы на 4 кошелька
    //     // Если на один атом в каком-то из кошельков стоит Offer, то функция Request Loan запускается.
    //     // Но если поставить Offer на 2 атома (в одном кошельке или разных), то Request Loan уже не запускается.
    //     let arr_tokens = await instance_snarkbase.getTokenListForOwner(accounts[0]);
    //     assert.equal(arr_tokens.length, 3, "Tokens amount of accounts[0] is wrong");

    //     // убеждаемся, что у первых 3-х токенов статус продажи None и отключены autoaccept
    //     for (let i = 0; i < arr_tokens.length; i++) {
    //         let status = await instance_snarkbase.getSaleTypeToToken(arr_tokens[i]);
    //         assert.equal(status, 0, `Status of token #${arr_tokens[i]} is not None - ${status}`);
         
    //         let accepts = await instance_snarkbase.isTokenAcceptOfLoanRequestFromSnarkAndOthers(arr_tokens[i]);
    //         assert.equal(accepts[0], false, "accept of loan request from snark is wrong");
    //         assert.equal(accepts[1], false, "accept of loan request from others is wrong");
    //     }

    //     await instance_snarkbase.createProfitShareScheme(
    //         accounts[3], 
    //         [accounts[3], accounts[7]], 
    //         [60, 40]
    //     );

    //     let retval = await instance_snarkbase.getNumberOfProfitShareSchemesForOwner(accounts[3]);
    //     assert.equal(retval.toNumber(), 1, "number of profit share schemes is wrong");

    //     const profitShareSchemeId = await instance_snarkbase.getProfitShareSchemeIdForOwner(accounts[3], 0);

    //     // создаем 4-й токен
    //     await instance_snarkbase.addToken(
    //         accounts[3],
    //         web3.utils.sha3("tokenHash_of_accounts[3]"),
    //         "QmXDeiDv96osHCBdgJdwK2sRD77CfPYmVo4KzS9e9E7Eni",
    //         "QmXDeiDv98osHCBdgJdwK2sRD66CfPYmVo4KzS9e9E7Enr",
    //         '',
    //         [1, 20, profitShareSchemeId],
    //         [true, true],
    //         { from: accounts[3] }
    //     );

    //     // убеждаемся, что у нас 4 токена
    //     retval = await instance_snarkbase.getTokensCount();
    //     assert.equal(retval, 4, "Common amount of tokens is wrong");

    //     // перекидываем 2-й и 3-й токены в другие кошельки
    //     await instance_offerbid.toGiftToken(2, accounts[1]);
    //     await instance_offerbid.toGiftToken(3, accounts[2]);

    //     // убеждаемся, что все токены лежат в разных кошельках
    //     retval = await instance_snarkbase.getOwnerOfToken(1);
    //     assert.equal(retval, accounts[0], "wrong owner of token 1");

    //     retval = await instance_snarkbase.getOwnerOfToken(2);
    //     assert.equal(retval, accounts[1], "wrong owner of token 2");

    //     retval = await instance_snarkbase.getOwnerOfToken(3);
    //     assert.equal(retval, accounts[2], "wrong owner of token 3");

    //     retval = await instance_snarkbase.getOwnerOfToken(4);
    //     assert.equal(retval, accounts[3], "wrong owner of token 4");

    //     retval = await instance_loanext.getLoanRequestsListOfTokenOwner(accounts[0]);
    //     assert.equal(retval[0].length, 0, `list of requests for account ${accounts[0]} is wrong (token 1)`);
    //     assert.equal(retval[1].length, 0, `list of requests for account ${accounts[0]} is wrong (token 1)`);

    //     retval = await instance_loanext.getLoanRequestsListOfTokenOwner(accounts[1]);
    //     assert.equal(retval[0].length, 0, `list of requests for account ${accounts[1]} is wrong (token 2)`);
    //     assert.equal(retval[1].length, 0, `list of requests for account ${accounts[1]} is wrong (token 2)`);

    //     retval = await instance_loanext.getLoanRequestsListOfTokenOwner(accounts[2]);
    //     assert.equal(retval[0].length, 0, `list of requests for account ${accounts[2]} is wrong (token 3)`);
    //     assert.equal(retval[1].length, 0, `list of requests for account ${accounts[2]} is wrong (token 3)`);

    //     retval = await instance_loanext.getLoanRequestsListOfTokenOwner(accounts[3]);
    //     assert.equal(retval[0].length, 0, `list of requests for account ${accounts[3]} is wrong (token 4)`);
    //     assert.equal(retval[1].length, 0, `list of requests for account ${accounts[3]} is wrong (token 4)`);

    //     // ставим Offer на один из первых трех токенов, у которых отключен autoaccept, например на первый токен
    //     const priceOffer = web3.utils.toWei('0.2', 'ether');
    //     await instance_offerbid.addOffer(1, priceOffer, { from: accounts[0] });
    //     status = await instance_snarkbase.getSaleTypeToToken(1);
    //     assert.equal(status, 1, `Status of token #1 is not Offer - ${status}`);

    //     // создаем лоан на все 4 токена, которые лежат в разных кошельках
    //     const startDateTimestamp = datetime.create(new Date(2019, 3, 1)).getTime();
    //     const duration = 3;
    //     const priceLoan = web3.utils.toWei('0.5', 'ether');
    //     await instance.createLoan([1,2,3,4], startDateTimestamp, duration, { from: accounts[4], value: priceLoan } );

    //     let loanId = await instance_loanext.getTotalNumberOfLoans();
    //     // по идее должны получить следующее поведение:
    //     // - первый токен должен исключиться из лоана автоматически, т.к. у него стоит Offer
    //     // - ожидаем 2 реквеста на 2-й и 3-й токены, т.е. токены в notApproved list
    //     // - 4-й токен попадает в approved list автоматически
    //     retval = await instance.getTokenListsOfLoanByTypes(loanId);
    //     assert.equal(retval.notApprovedTokensList.length, 2, "length of not approved tokens list is wrong");
    //     assert.equal(retval.approvedTokensList.length, 1, "length of approved tokens list is wrong");
    //     assert.equal(retval.declinedTokensList.length, 0, "length of declined tokens list is wrong");
    //     assert.equal(retval.notApprovedTokensList[0], 2, "token number is wrong into not approved tokens list");
    //     assert.equal(retval.notApprovedTokensList[1], 3, "token number is wrong into not approved tokens list");
    //     assert.equal(retval.approvedTokensList[0], 4, "token number is wrong into not approved tokens list");

    //     retval = await instance_loanext.getLoanRequestsListOfTokenOwner(accounts[0]);
    //     assert.equal(retval[0].length, 0, `list of requests for account ${accounts[0]} is wrong (token 1)`);
    //     assert.equal(retval[1].length, 0, `list of requests for account ${accounts[0]} is wrong (token 1)`);

    //     retval = await instance_loanext.getLoanRequestsListOfTokenOwner(accounts[1]);
    //     assert.equal(retval[0].length, 1, `list of requests for account ${accounts[1]} is wrong (token 2)`);
    //     assert.equal(retval[1].length, 1, `list of requests for account ${accounts[1]} is wrong (token 2)`);
    //     assert.equal(retval[0][0].toNumber(), 2, "request is not for token #2");
    //     assert.equal(retval[1][0].toNumber(), loanId, "request is not for token #2");

    //     retval = await instance_loanext.getLoanRequestsListOfTokenOwner(accounts[2]);
    //     assert.equal(retval[0].length, 1, `list of requests for account ${accounts[2]} is wrong (token 3)`);
    //     assert.equal(retval[1].length, 1, `list of requests for account ${accounts[2]} is wrong (token 3)`);
    //     assert.equal(retval[0][0].toNumber(), 3, "request is not for token #3");
    //     assert.equal(retval[1][0].toNumber(), loanId, "request is not for token #3");

    //     retval = await instance_loanext.getLoanRequestsListOfTokenOwner(accounts[3]);
    //     assert.equal(retval[0].length, 0, `list of requests for account ${accounts[3]} is wrong (token 4)`);
    //     assert.equal(retval[1].length, 0, `list of requests for account ${accounts[3]} is wrong (token 4)`);
    // });

    // it("10. test join token to the loan", async () => {
    //     let loanId = await instance_loanext.getTotalNumberOfLoans();

    //     let retval = await instance.getTokenListsOfLoanByTypes(loanId);
    //     assert.equal(retval.notApprovedTokensList.length, 2, "length of not approved tokens list is wrong");
    //     assert.equal(retval.approvedTokensList.length, 1, "length of approved tokens list is wrong");
    //     assert.equal(retval.declinedTokensList.length, 0, "length of declined tokens list is wrong");
    //     assert.equal(retval.notApprovedTokensList[0], 2, "token number is wrong into not approved tokens list");
    //     assert.equal(retval.notApprovedTokensList[1], 3, "token number is wrong into not approved tokens list");
    //     assert.equal(retval.approvedTokensList[0], 4, "token number is wrong into not approved tokens list");

    //     const offerId = await instance_offerbid.getOfferByToken(1);
    //     await instance_offerbid.cancelOffer(offerId, { from: accounts[0] });
    //     await instance.acceptLoan(loanId, [1], { from: accounts[0] });

    //     retval = await instance.getTokenListsOfLoanByTypes(loanId);
    //     assert.equal(retval.notApprovedTokensList.length, 2, "length of not approved tokens list is wrong");
    //     assert.equal(retval.approvedTokensList.length, 2, "length of approved tokens list is wrong");
    //     assert.equal(retval.declinedTokensList.length, 0, "length of declined tokens list is wrong");
    //     assert.equal(retval.notApprovedTokensList[0], 2, "token number is wrong into not approved tokens list");
    //     assert.equal(retval.notApprovedTokensList[1], 3, "token number is wrong into not approved tokens list");
    //     assert.equal(retval.approvedTokensList[0], 4, "token number is wrong into not approved tokens list");
    //     assert.equal(retval.approvedTokensList[1], 1, "token number is wrong into not approved tokens list");
    // });

    // it("11. test an ability to acceptBid when loan is started", async () => {
    //     // Github issue #40
    //     // Scenario
    //     // 1. Create Token with auto loan accept.
    //     // 2. Create a loan startig today
    //     // 3. Create an offer for this token.
    //     // 4. Start this loan (2 cases: до вызова borrowedTokens и после)
    //     // 5. Add a bid for an offer from point  3
    //     // 6. Accept Bid
    //     // It should be not accepted but it accepted now

    //     // const priceOffer = web3.utils.toWei('0.4', 'ether');
    //     // const priceBid = web3.utils.toWei('0.2', 'ether');
    //     // const tokenId = 2;
    //     // const tokenOwner = accounts[1];
    //     // const bidOwner = accounts[5];

    //     // let loansList = await instance_loanext.getListOfNotFinishedLoansForToken(tokenId);
    //     // console.log(`Count of loans for token #${tokenId}: ${loansList.length}`);
    //     // for (let i = 0; i < loansList.length; i++) {
    //     //     const loanDetails = await instance.getLoanDetail(loansList[i]);
    //     //     console.log('');
    //     //     console.log(`Loan Id: ${ loansList[i] }`);
    //     //     console.log(`Start date: ${ loanDetail.startDate }`);
    //     //     console.log(`Duration date: ${ loanDetail.duration }`);
    //     //     console.log(`Sale status: ${ loanDetail.saleStatus }`);
    //     //     console.log(`Loan price: ${ loanDetail.loanPrice }`);
    //     //     console.log(`Loan owner: ${ loanDetail.loanOwner }`);
    //     // }
    //     // console.log('------');

    //     // let loanId = await instance.getTotalNumberOfLoans();
    //     // loanDetail = await instance.getLoanDetail(loanId);
    //     // assert.isBelow(loanDetail.saleStatus.toNumber(), 2, "Loan has not to be in an active status");

    //     // console.log(`current loanid: ${loanId}`);
    //     // console.log(`current sale status: ${loanDetail.saleStatus}`);

    //     // await instance_offerbid.addOffer(tokenId, priceOffer, { from: tokenOwner });
    //     // const offerId = await instance_offerbid.getTotalNumberOfOffers();

    //     // status = await instance_snarkbase.getSaleTypeToToken(tokenId);
    //     // assert.equal(status, 1, `Status of token #1 is not Offer - ${status}`);

    //     // await instance.startLoan(loanId);
    //     // loanDetail = await instance.getLoanDetail(loanId);
    //     // assert.equal(loanDetail.saleStatus.toNumber(), 2, "Loan has to be in an active status");

    //     // await instance_offerbid.addBid(tokenId, { from: bidOwner, value: priceBid });
    //     // const bidId = await instance_offerbid.getTotalNumberOfBids();

    //     // loansList = await instance.getListOfNotFinishedLoansForToken(tokenId);
    //     // for (let i = 0; i < loansList.length; i++) {
    //     //     loanDetails = await instance.getLoanDetail(loansList[i]);
    //     //     console.log('');
    //     //     console.log(`Loan Id: ${loansList[i]}`);
    //     //     console.log(`Start date: ${loanDetail.startDate}`);
    //     //     console.log(`Duration date: ${loanDetail.duration}`);
    //     //     console.log(`Sale status: ${loanDetail.saleStatus}`);
    //     //     console.log(`Loan price: ${loanDetail.loanPrice}`);
    //     //     console.log(`Loan owner: ${loanDetail.loanOwner}`);
    //     // }

    //     // assert.equal(loansList.length, 1, "lenght of loans list is wrong");
    //     // assert.equal(loansList[0].toNumber(), loanId, "loan id is wrong in the list");

    //     // await instance_offerbid.acceptBid(bidId, { from: tokenOwner });

    // });

});
