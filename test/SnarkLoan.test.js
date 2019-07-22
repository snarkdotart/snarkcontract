var SnarkLoan = artifacts.require("SnarkLoan");
var SnarkBase = artifacts.require("SnarkBase");
var SnarkStorage = artifacts.require("SnarkStorage");
var SnarkTestFunctions = artifacts.require("SnarkTestFunctions");
var SnarkERC721 = artifacts.require("SnarkERC721");

const BN = web3.utils.BN;

function pause(millis) {
    var date = Date.now();
    var curDate = null;
    do {
        curDate = Date.now();
    } while (curDate-date < millis);
}

contract('SnarkLoan', async (accounts) => {
    const dt        = new Date();
    const _year     = dt.getFullYear();
    const _month    = dt.getMonth();
    const _date     = dt.getDate();
    const _hours    = dt.getHours();
    const _minutes  = dt.getMinutes();
    const loan_1_start  = new Date(_year, _month, _date, _hours + 2, _minutes, 0) / 1000;
    const loan_1_finish = new Date(_year, _month, _date, _hours + 3, _minutes, 0) / 1000;
    const loan_2_start  = new Date(_year, _month, _date, _hours + 7, _minutes, 0) / 1000;
    const loan_2_finish = new Date(_year, _month, _date, _hours + 8, _minutes, 0) / 1000;
    const loan_3_start  = new Date(_year, _month, _date, _hours + 4, _minutes, 0) / 1000;
    const loan_3_finish = new Date(_year, _month, _date, _hours + 5, _minutes, 0) / 1000;
    const loan_4_start  = new Date(_year, _month, _date, _hours + 1, _minutes, 0) / 1000;
    const loan_4_finish = new Date(_year, _month, _date, _hours + 1, _minutes + 1, 0) / 1000;
    const loan_5_start  = new Date(_year, _month, _date, _hours + 9, _minutes, 0) / 1000;
    const loan_5_finish = new Date(_year, _month, _date, _hours + 10, _minutes, 0) / 1000;

    before(async () => {
        snarkstorage    = await SnarkStorage.deployed();
        snarkbase       = await SnarkBase.deployed();
        snarkloan       = await SnarkLoan.deployed();
        snarktest       = await SnarkTestFunctions.deployed();
        snarkerc721     = await SnarkERC721.deployed();

        await web3.eth.sendTransaction({
            from:   accounts[0],
            to:     snarkstorage.address, 
            value:  web3.utils.toWei('1', "ether")
        });
    });

    it("get size of the SnarkLoan library", async () => {
        const bytecode = snarkloan.constructor._json.bytecode;
        const deployed = snarkloan.constructor._json.deployedBytecode;
        const sizeOfB = bytecode.length / 2;
        const sizeOfD = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
    });

    it("test create loan", async () => {
        const valueOfLoan = web3.utils.toWei('1', "ether");

        // check that there are not any loans
        let countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(0);

        // check that list of loans is empty
        let allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.be.empty;

        // pointer to a loan has to be empty
        let pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(0);

        // check if settled the top and bottom boundaries up
        let topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();
        let bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();

        expect(topBoundary.toNumber()).to.equal(0);
        expect(bottomBoundary.toNumber()).to.equal(0);

        let findplace = await snarktest.findPosition(loan_1_start, loan_1_finish);
        console.log(`find position for loan 1: ${JSON.stringify(findplace)}`);

        // check a number of loans in the owner list before adding a new one
        let numberOfOwnerLoans = await snarkloan.getCountOfOwnerLoans(accounts[0]);
        expect(numberOfOwnerLoans.toNumber()).to.equal(0);

        // check the amount of ether on SnarkLoan and SnarkStorage contracts. 
        // An increasing of ether should be in SnarkStorage only.
        const balanceOfSnarkStorage = await web3.eth.getBalance(snarkstorage.address);
        const balanceOfSnarkLoan = await web3.eth.getBalance(snarkloan.address);

        // Adding a new loan should throw an exception
        try {
            await snarkloan.createLoan(loan_1_start, loan_1_finish, { from: accounts[0], value: valueOfLoan });
        } catch(e) {
            expect(e.message).to.equal('Returned error: VM Exception while processing transaction: revert User has to have at least one token -- Reason given: User has to have at least one token.');
        }

        // we have to add at least one loan to account[0]
        let balanceOfERC721 = await snarkerc721.balanceOf(accounts[0]);
        assert.equal(balanceOfERC721, 0, "balance is not equal zero before test");
        
        await snarkbase.createProfitShareScheme(accounts[0], [accounts[1], accounts[2]], [20, 80]);
        let profitSchemeId = await snarkbase.getProfitShareSchemesTotalCount();

        await snarkbase.addToken(
            accounts[0],
            web3.utils.sha3(`1-tokenHashOf_${accounts[0]}`),
            `1-tokenUrlOf_${accounts[0]}`,
            'ipfs://decorator.io',
            '1-big-secret',
            [1, 20, profitSchemeId],
            true
        );

        await snarkbase.addToken(
            accounts[0],
            web3.utils.sha3(`2-tokenHashOf_${accounts[0]}`),
            `2-tokenUrlOf_${accounts[0]}`,
            'ipfs://decorator.io',
            '2-big-secret',
            [1, 20, profitSchemeId],
            false
        );

        let totalSupply = await snarkerc721.totalSupply();
        assert.equal(totalSupply, 2, "total supply is wrong");

        let countApprovedTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(countApprovedTokens.toNumber(), 1, "wrong count of tokens in approved list");

        let tokenId = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
        assert.equal(tokenId, 1, "tokenId should be equal 1");

        await snarkloan.createLoan(loan_1_start, loan_1_finish, { from: accounts[0], value: valueOfLoan });

        const balanceOfSnarkStorage_after = await web3.eth.getBalance(snarkstorage.address);
        const balanceOfSnarkLoan_after = await web3.eth.getBalance(snarkloan.address);

        expect(new BN(balanceOfSnarkStorage).eq(new BN(balanceOfSnarkStorage_after).sub(new BN(valueOfLoan)))).is.true;
        expect(new BN(balanceOfSnarkLoan).eq(new BN(balanceOfSnarkLoan_after))).is.true;

        // check if the number of loans equals 1
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(1);

        // the pointer has to point to the first loan
        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(1);

        // check the return number of loans in the list. It should equal to 1.
        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(1);
        expect(allloans[0].toNumber()).to.equal(1);

        // check if the detail of loan saved properly
        const loanDetail = await snarkloan.getLoanDetail(countOfLoans);
        expect(loanDetail[0].toUpperCase()).to.equal(accounts[0].toUpperCase());
        expect(loanDetail[1].toNumber()).to.equal(loan_1_start);
        expect(loanDetail[2].toNumber()).to.equal(loan_1_finish);
        expect(loanDetail[3].toNumber()).to.equal(0);
        expect(loanDetail[4].toNumber()).to.equal(0);
        expect(loanDetail[5].eq(new BN(valueOfLoan))).to.be.true;

        // check if settled the top and bottom boundaries up
        // we expect that they will equal data of the first loan
        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_1_start);
        expect(topBoundary.toNumber()).to.equal(loan_1_finish);

        // prepare to add of the second loan which will not overlap with the first one
        findplace = await snarktest.findPosition(loan_2_start, loan_2_finish);
        console.log(`find position for loan 2: ${JSON.stringify(findplace)}`);

        let busyDates = await snarkloan.getListOfBusyDates();
        expect(busyDates[0]).to.have.lengthOf(1);
        expect(busyDates[1]).to.have.lengthOf(1);
        expect(busyDates[0][0].eq(new BN(loan_1_start))).to.be.true;
        expect(busyDates[1][0].eq(new BN(loan_1_finish))).to.be.true;

        await snarkloan.createLoan(loan_2_start, loan_2_finish, { from: accounts[0], value: valueOfLoan });

        // check if there are 2 loans now
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(2);

        // check lint of loans
        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(2);
        expect(allloans[0].toNumber()).to.equal(1);
        expect(allloans[1].toNumber()).to.equal(2);

        // check the pointer
        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(1);

        // we expect that the bottom of the boundary will equal the start of the 
        // first loan and the top boundary will equal the end of the second loan
        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_1_start);
        expect(topBoundary.toNumber()).to.equal(loan_2_finish);

        // add 3rd loan which should be between 2nd and 1st loans
        findplace = await snarktest.findPosition(loan_3_start, loan_3_finish);
        console.log(`find position for loan 3: ${JSON.stringify(findplace)}`);

        busyDates = await snarkloan.getListOfBusyDates();
        expect(busyDates[0]).to.have.lengthOf(2);
        expect(busyDates[1]).to.have.lengthOf(2);
        expect(busyDates[0][0].eq(new BN(loan_1_start))).to.be.true;
        expect(busyDates[1][0].eq(new BN(loan_1_finish))).to.be.true;
        expect(busyDates[0][1].eq(new BN(loan_2_start))).to.be.true;
        expect(busyDates[1][1].eq(new BN(loan_2_finish))).to.be.true;

        await snarkloan.createLoan(loan_3_start, loan_3_finish, { from: accounts[0], value: valueOfLoan });

        // check if there are 3 loans now
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(3);

        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(3);
        expect(allloans[0].toNumber()).to.equal(1);
        expect(allloans[1].toNumber()).to.equal(3);
        expect(allloans[2].toNumber()).to.equal(2);

        // check if the pointer is correct
        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(1);

        // we expect that the bottom of the boundary will equal the start of the 
        // first loan and the top boundary will equal the end of the second loan
        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_1_start);
        expect(topBoundary.toNumber()).to.equal(loan_2_finish);

        // add 4th loan which has to become the first in the list
        // and the pointer has to shift to it
        findplace = await snarktest.findPosition(loan_4_start, loan_4_finish);
        console.log(`find position for loan 4: ${JSON.stringify(findplace)}`);

        busyDates = await snarkloan.getListOfBusyDates();
        expect(busyDates[0]).to.have.lengthOf(3);
        expect(busyDates[1]).to.have.lengthOf(3);
        expect(busyDates[0][0].eq(new BN(loan_1_start))).to.be.true;
        expect(busyDates[1][0].eq(new BN(loan_1_finish))).to.be.true;
        expect(busyDates[0][1].eq(new BN(loan_3_start))).to.be.true;
        expect(busyDates[1][1].eq(new BN(loan_3_finish))).to.be.true;
        expect(busyDates[0][2].eq(new BN(loan_2_start))).to.be.true;
        expect(busyDates[1][2].eq(new BN(loan_2_finish))).to.be.true;

        await snarkloan.createLoan(loan_4_start, loan_4_finish, { from: accounts[0], value: valueOfLoan });

        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(4);

        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(4);
        expect(allloans[0].toNumber()).to.equal(4);
        expect(allloans[1].toNumber()).to.equal(1);
        expect(allloans[2].toNumber()).to.equal(3);
        expect(allloans[3].toNumber()).to.equal(2);

        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(4);

        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_4_start);
        expect(topBoundary.toNumber()).to.equal(loan_2_finish);

        // add 5th loan to the last position
        // despite that, the pointer has not to be changed
        findplace = await snarktest.findPosition(loan_5_start, loan_5_finish);
        console.log(`find position for loan 5: ${JSON.stringify(findplace)}`);

        busyDates = await snarkloan.getListOfBusyDates();
        expect(busyDates[0]).to.have.lengthOf(4);
        expect(busyDates[1]).to.have.lengthOf(4);
        expect(busyDates[0][0].eq(new BN(loan_4_start))).to.be.true;
        expect(busyDates[1][0].eq(new BN(loan_4_finish))).to.be.true;
        expect(busyDates[0][1].eq(new BN(loan_1_start))).to.be.true;
        expect(busyDates[1][1].eq(new BN(loan_1_finish))).to.be.true;
        expect(busyDates[0][2].eq(new BN(loan_3_start))).to.be.true;
        expect(busyDates[1][2].eq(new BN(loan_3_finish))).to.be.true;
        expect(busyDates[0][3].eq(new BN(loan_2_start))).to.be.true;
        expect(busyDates[1][3].eq(new BN(loan_2_finish))).to.be.true;

        // add a second loan
        await snarkloan.createLoan(loan_5_start, loan_5_finish, { from: accounts[0], value: valueOfLoan });

        // check if the number of loans is 5
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(5);

        // check if the list contains 5 loans
        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(5);
        expect(allloans[0].toNumber()).to.equal(4);
        expect(allloans[1].toNumber()).to.equal(1);
        expect(allloans[2].toNumber()).to.equal(3);
        expect(allloans[3].toNumber()).to.equal(2);
        expect(allloans[4].toNumber()).to.equal(5);

        // check if the pointer is correct
        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(4);

        // check the top and the bottom of boundaries
        // expect that nothing was changed
        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_4_start);
        expect(topBoundary.toNumber()).to.equal(loan_5_finish);

        // // check the quantity of loan in the list of the owner before adding of a new one. 
        // The amount of loans has to be 5.
        numberOfOwnerLoans = await snarkloan.getCountOfOwnerLoans(accounts[0]);
        expect(numberOfOwnerLoans.toNumber()).to.equal(5);

        let listOfOwnerLoans = await snarkloan.getListOfLoansOfOwner(accounts[0]);
        expect(listOfOwnerLoans).to.have.lengthOf(5);
        expect(listOfOwnerLoans[0].toNumber()).to.equal(1);
        expect(listOfOwnerLoans[1].toNumber()).to.equal(2);
        expect(listOfOwnerLoans[2].toNumber()).to.equal(3);
        expect(listOfOwnerLoans[3].toNumber()).to.equal(4);
        expect(listOfOwnerLoans[4].toNumber()).to.equal(5);

        busyDates = await snarkloan.getListOfBusyDates();
        expect(busyDates[0]).to.have.lengthOf(5);
        expect(busyDates[1]).to.have.lengthOf(5);
        expect(busyDates[0][0].eq(new BN(loan_4_start))).to.be.true;
        expect(busyDates[1][0].eq(new BN(loan_4_finish))).to.be.true;
        expect(busyDates[0][1].eq(new BN(loan_1_start))).to.be.true;
        expect(busyDates[1][1].eq(new BN(loan_1_finish))).to.be.true;
        expect(busyDates[0][2].eq(new BN(loan_3_start))).to.be.true;
        expect(busyDates[1][2].eq(new BN(loan_3_finish))).to.be.true;
        expect(busyDates[0][3].eq(new BN(loan_2_start))).to.be.true;
        expect(busyDates[1][3].eq(new BN(loan_2_finish))).to.be.true;
        expect(busyDates[0][4].eq(new BN(loan_5_start))).to.be.true;
        expect(busyDates[1][4].eq(new BN(loan_5_finish))).to.be.true;
    });

    it("test delete of loan", async () => {
        // check if we still have 5 loans
        let countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(5);

        // they have to be in the same order
        let allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(5);
        expect(allloans[0].toNumber()).to.equal(4);
        expect(allloans[1].toNumber()).to.equal(1);
        expect(allloans[2].toNumber()).to.equal(3);
        expect(allloans[3].toNumber()).to.equal(2);
        expect(allloans[4].toNumber()).to.equal(5);

        let listOfOwnerLoans = await snarkloan.getListOfLoansOfOwner(accounts[0]);
        expect(listOfOwnerLoans).to.have.lengthOf(5);
        expect(listOfOwnerLoans[0].toNumber()).to.equal(1);
        expect(listOfOwnerLoans[1].toNumber()).to.equal(2);
        expect(listOfOwnerLoans[2].toNumber()).to.equal(3);
        expect(listOfOwnerLoans[3].toNumber()).to.equal(4);
        expect(listOfOwnerLoans[4].toNumber()).to.equal(5);

        let bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        let topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_4_start);
        expect(topBoundary.toNumber()).to.equal(loan_5_finish);

        let pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(4);

        let busyDates = await snarkloan.getListOfBusyDates();
        expect(busyDates[0]).to.have.lengthOf(5);
        expect(busyDates[1]).to.have.lengthOf(5);

        // check if the first loan was deleted (first position)
        await snarkloan.deleteLoan(4);

        // check if it's possible to delete the loan twice
        try {
            await snarkloan.deleteLoan(4);
        } catch(e) {
            expect(e.message).to.equal('Returned error: VM Exception while processing transaction: revert Loan does not exist -- Reason given: Loan does not exist.');
        }

        busyDates = await snarkloan.getListOfBusyDates();
        expect(busyDates[0]).to.have.lengthOf(4);
        expect(busyDates[1]).to.have.lengthOf(4);

        // number of loans has to be 4
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(4);

        // they have to be in the same order
        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(4);
        expect(allloans[0].toNumber()).to.equal(1);
        expect(allloans[1].toNumber()).to.equal(3);
        expect(allloans[2].toNumber()).to.equal(2);
        expect(allloans[3].toNumber()).to.equal(5);

        listOfOwnerLoans = await snarkloan.getListOfLoansOfOwner(accounts[0]);
        expect(listOfOwnerLoans).to.have.lengthOf(4);
        expect(listOfOwnerLoans[0].toNumber()).to.equal(1);
        expect(listOfOwnerLoans[1].toNumber()).to.equal(2);
        expect(listOfOwnerLoans[2].toNumber()).to.equal(3);
        expect(listOfOwnerLoans[3].toNumber()).to.equal(5);

        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_1_start);
        expect(topBoundary.toNumber()).to.equal(loan_5_finish);

        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(1);

        // check of deleting the loan which is at the last of the list
        await snarkloan.deleteLoan(5);
       
        // number of loans has to be 3
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(3);

        // they have to be in the same order
        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(3);
        expect(allloans[0].toNumber()).to.equal(1);
        expect(allloans[1].toNumber()).to.equal(3);
        expect(allloans[2].toNumber()).to.equal(2);

        listOfOwnerLoans = await snarkloan.getListOfLoansOfOwner(accounts[0]);
        expect(listOfOwnerLoans).to.have.lengthOf(3);
        expect(listOfOwnerLoans[0].toNumber()).to.equal(1);
        expect(listOfOwnerLoans[1].toNumber()).to.equal(2);
        expect(listOfOwnerLoans[2].toNumber()).to.equal(3);

        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_1_start);
        expect(topBoundary.toNumber()).to.equal(loan_2_finish);

        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(1);

        // check of deleting the loan which is at the middle of the list
        await snarkloan.deleteLoan(3);
       
        // number of loans has to be 2
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(2);

        // they have to be in the same order
        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(2);
        expect(allloans[0].toNumber()).to.equal(1);
        expect(allloans[1].toNumber()).to.equal(2);

        listOfOwnerLoans = await snarkloan.getListOfLoansOfOwner(accounts[0]);
        expect(listOfOwnerLoans).to.have.lengthOf(2);
        expect(listOfOwnerLoans[0].toNumber()).to.equal(1);
        expect(listOfOwnerLoans[1].toNumber()).to.equal(2);

        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_1_start);
        expect(topBoundary.toNumber()).to.equal(loan_2_finish);

        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(1);

        // check of deleting the loan which is at the beginning of the list
        await snarkloan.deleteLoan(1);
       
        // number of loans has to be 1
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(1);

        // they have to be in the same order
        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(1);
        expect(allloans[0].toNumber()).to.equal(2);

        listOfOwnerLoans = await snarkloan.getListOfLoansOfOwner(accounts[0]);
        expect(listOfOwnerLoans).to.have.lengthOf(1);
        expect(listOfOwnerLoans[0].toNumber()).to.equal(2);

        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_2_start);
        expect(topBoundary.toNumber()).to.equal(loan_2_finish);

        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(2);

        // check of deleting the last loan
        await snarkloan.deleteLoan(2);
       
        // number of loans has to be 0
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(0);

        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(0);

        listOfOwnerLoans = await snarkloan.getListOfLoansOfOwner(accounts[0]);
        expect(listOfOwnerLoans).to.have.lengthOf(0);

        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(0);
        expect(topBoundary.toNumber()).to.equal(0);

        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(0);

        busyDates = await snarkloan.getListOfBusyDates();
        expect(busyDates[0]).to.have.lengthOf(0);
        expect(busyDates[1]).to.have.lengthOf(0);
    });

    it('test creating a loan with the same data as a deleted one', async () => {
        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(0);

        await snarkloan.createLoan(
            loan_1_start, 
            loan_5_finish, 
            { 
                from: accounts[0], 
                value: web3.utils.toWei('1', "ether") 
            }
        );

        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(1);

        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(1);

        loanId = allloans[0];
        maxLoanId = await snarktest.getMaxLoanId();
        expect(loanId.toNumber()).to.equal(maxLoanId.toNumber());

        await snarkloan.deleteLoan(loanId);

        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(0);

        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(0);

        loanId = await snarkloan.getLoanId();
        expect(loanId.toNumber()).to.equal(0);
    });

    it("test deleting the last loan when a pointer to points on it", async () => {
        const _dt_n     = new Date();
        const _year_n   = _dt_n.getFullYear();
        const _month_n  = _dt_n.getMonth();
        const _date_n   = _dt_n.getDate();
        const _hours_n  = _dt_n.getHours();
        const _min_n    = _dt_n.getMinutes();
        
        const l1s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 1, 0) / 1000;
        const l1f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 2, 0) / 1000;
        const l2s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 3, 0) / 1000;
        const l2f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 4, 0) / 1000;
    
        const valueOfLoan = web3.utils.toWei('2', "ether");

        await snarkloan.createLoan(l1s, l1f, { from: accounts[0], value: valueOfLoan });
        let loanId1 = await snarktest.getMaxLoanId();

        await snarkloan.createLoan(l2s, l2f, { from: accounts[0], value: valueOfLoan });
        let loanId2 = await snarktest.getMaxLoanId();

        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(2);

        loanId = await snarkloan.getLoanId();
        expect(loanId.toNumber()).to.equal(loanId1.toNumber());

        pause(70000);

        isActive = await snarkloan.isLoanActive(loanId1);
        assert.isTrue(isActive, "Loan is not active and it's wrong");

        loanId = await snarkloan.getLoanId();
        expect(loanId.toNumber()).to.equal(loanId1.toNumber());

        pause(60000);

        isActive = await snarkloan.isLoanActive(loanId1);
        assert.isFalse(isActive, "Loan is still active and it's wrong");

        isFinished = await snarkloan.isLoanFinished(loanId1);
        assert.isTrue(isFinished, "Loan is not finished and it's wrong");

        loanId = await snarkloan.getLoanId();
        expect(loanId.toNumber()).to.equal(loanId2.toNumber());

        isActive = await snarkloan.isLoanActive(loanId2);
        assert.isFalse(isActive, "Loan is active and it's wrong");

        isFinished = await snarkloan.isLoanFinished(loanId2);
        assert.isFalse(isFinished, "Loan is not finished and it's wrong");

        await snarkloan.deleteLoan(loanId2);

        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(0);

        loanId = await snarkloan.getLoanId();
        expect(loanId.toNumber()).to.equal(0);

    });

    it("test ApprovedTokensForLoan array", async () => {
        let countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(countOfTokens, 1, "error on step 1");
                        //  0  1  2  3  4  5  6
        const tokensList = [1, 3, 5, 8, 2, 9, 4];

        for (let i = 0; i < tokensList.length; i++) {
            await snarktest.addTokenToApprovedListForLoan(tokensList[i]);
        }

        countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(countOfTokens, tokensList.length, "error on step 2");

        for (let i = 0; i < countOfTokens; i++) {
            let t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(i);
            assert.equal(t, tokensList[i], 'error with tokens order');
        }

        // delete token id = 8
        await snarktest.deleteTokenFromApprovedListForLoan(8);

        countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(countOfTokens, tokensList.length - 1, "error on step 3");

        let t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
        assert.equal(t, 1, "error on step 4");
        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
        assert.equal(t, 3, "error on step 5");
        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(2);
        assert.equal(t, 5, "error on step 6");
        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(3);
        assert.equal(t, 4, "error on step 7");
        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(4);
        assert.equal(t, 2, "error on step 8");
        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(5);
        assert.equal(t, 9, "error on step 9");
        t = await snarktest.isTokenInApprovedListForLoan(8);
        assert.isFalse(t);

        // delete token id = 1
        await snarktest.deleteTokenFromApprovedListForLoan(1);

        countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(countOfTokens, tokensList.length - 2, "error on step 10");

        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
        assert.equal(t, 9, "error on step 11");
        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
        assert.equal(t, 3, "error on step 12");
        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(2);
        assert.equal(t, 5, "error on step 13");
        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(3);
        assert.equal(t, 4, "error on step 14");
        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(4);
        assert.equal(t, 2, "error on step 15");
        t = await snarktest.isTokenInApprovedListForLoan(1);
        assert.isFalse(t);

        await snarktest.deleteTokenFromApprovedListForLoan(9);
        t = await snarktest.isTokenInApprovedListForLoan(9);
        assert.isFalse(t);
        await snarktest.deleteTokenFromApprovedListForLoan(2);
        t = await snarktest.isTokenInApprovedListForLoan(2);
        assert.isFalse(t);
        countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(countOfTokens, tokensList.length - 4, "error on step 16");
        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
        assert.equal(t, 4, "error on step 17");
        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
        assert.equal(t, 3, "error on step 18");
        t = await snarktest.getTokenFromApprovedTokensForLoanByIndex(2);
        assert.equal(t, 5, "error on step 19");

        await snarktest.deleteTokenFromApprovedListForLoan(4);
        await snarktest.deleteTokenFromApprovedListForLoan(3);
        await snarktest.deleteTokenFromApprovedListForLoan(5);
        countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(countOfTokens, 0, "error on step 20");

        await snarktest.deleteTokenFromApprovedListForLoan(54);
    });

    it("test new logic of loan", async () => {
        // until this time here has to exist 2 tokens where one of them has to be in a list of approve
        let totalSupply = await snarkerc721.totalSupply();
        assert.equal(totalSupply, 2, "total supply is wrong");

        let countApprovedTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(countApprovedTokens.toNumber(), 0, "wrong count of tokens in approved list");

        await snarktest.addTokenToApprovedListForLoan(1);

        countApprovedTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(countApprovedTokens.toNumber(), 1, "wrong count of tokens in approved list");

        let tokenId = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
        assert.equal(tokenId, 1, "tokenId should be equal 1");

        // add 2 tokens to another account
        await snarkbase.createProfitShareScheme(accounts[1], [accounts[0], accounts[2]], [20, 80]);
        const profitSchemeId = await snarkbase.getProfitShareSchemesTotalCount();

        await snarkbase.addToken(
            accounts[1],
            web3.utils.sha3(`1-tokenHashOf_${accounts[1]}`),
            `1-tokenUrlOf_${accounts[1]}`,
            'ipfs://decorator.io',
            '1-big-secret',
            [1, 20, profitSchemeId],
            true
        );

        await snarkbase.addToken(
            accounts[1],
            web3.utils.sha3(`2-tokenHashOf_${accounts[1]}`),
            `2-tokenUrlOf_${accounts[1]}`,
            'ipfs://decorator.io',
            '2-big-secret',
            [1, 20, profitSchemeId],
            false
        );

        totalSupply = await snarkerc721.totalSupply();
        assert.equal(totalSupply, 4, "total supply is wrong");

        countApprovedTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(countApprovedTokens.toNumber(), 2, "wrong count of tokens in approved list");

        tokenId = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
        assert.equal(tokenId, 1, "tokenId should be equal 1");

        tokenId = await snarktest.getTokenFromApprovedTokensForLoanByIndex(1);
        assert.equal(tokenId, 3, "tokenId should be equal 3");
        
        // check account[0]
        balanceOfERC721 = await snarkerc721.balanceOf(accounts[0]);
        assert.equal(balanceOfERC721, 2, "balance of account0 is wrong");

        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 0);
        assert.equal(tokenId, 1, "token id should be equal 1");

        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 1);
        assert.equal(tokenId, 2, "token id should be equal 2");

        let countNotApprovedTokens = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[0]);
        assert.equal(countNotApprovedTokens, 1, "wrong number of not approved tokens for account0");

        tokenId = await snarktest.getTokenFromNotApprovedTokensForLoanByIndex(accounts[0], 0);
        assert.equal(tokenId, 2);

        expect(await snarkloan.doUserHaveAccessToToken(accounts[0], 1)).is.true;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[0], 2)).is.true;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[0], 3)).is.false;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[0], 4)).is.false;

        expect(await snarkloan.doUserHaveAccessToToken(accounts[1], 1)).is.false;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[1], 2)).is.false;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[1], 3)).is.true;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[1], 4)).is.true;
        
        // check account[1]
        balanceOfERC721 = await snarkerc721.balanceOf(accounts[1]);
        assert.equal(balanceOfERC721, 2, "balance of account1 is wrong");

        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 0);
        assert.equal(tokenId, 3);

        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 1);
        assert.equal(tokenId, 4);

        countNotApprovedTokens = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[1]);
        assert.equal(countNotApprovedTokens, 1, "wrong number of not approved tokens for account1");

        tokenId = await snarktest.getTokenFromNotApprovedTokensForLoanByIndex(accounts[1], 0);
        assert.equal(tokenId, 4);

        // check account[2]
        balanceOfERC721 = await snarkerc721.balanceOf(accounts[2]);
        assert.equal(balanceOfERC721, 0, "balance of account2 is wrong");

        countNotApprovedTokens = await snarktest.getTotalNumberOfTokensInNotApprovedTokensForLoan(accounts[2]);
        assert.equal(countNotApprovedTokens, 0, "wrong number of not approved tokens for account2");
        
        let countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(0);

        let isActive = await snarkloan.isLoanActive(countOfLoans);
        assert.isFalse(isActive, "Loan is active and it's wrong");

        const _dt_n     = new Date();
        const _year_n   = _dt_n.getFullYear();
        const _month_n  = _dt_n.getMonth();
        const _date_n   = _dt_n.getDate();
        const _hours_n  = _dt_n.getHours();
        const _min_n    = _dt_n.getMinutes();
        const l1s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 1, 0) / 1000;
        const l1f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 2, 0) / 1000;
    
        const valueOfLoan = web3.utils.toWei('2', "ether");

        await snarkloan.createLoan(l1s, l1f, { from: accounts[0], value: valueOfLoan });

        let loanId = await snarktest.getMaxLoanId();

        // check if the loan was created
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(1);

        // wait a minute to loan start
        pause(60000);

        isActive = await snarkloan.isLoanActive(loanId);
        assert.isTrue(isActive, "Loan is not active and it's wrong");
    
        totalSupply = await snarkerc721.totalSupply();
        assert.equal(totalSupply, 4, "total supply is wrong");
        
        // for account[0] was: token 1 - true, token 2 - false
        // for account[1] was: token 3 - true, token 4 - false

        // after starting of loan we expecting:
        // for account[0] we have to see 3 tokens: 3, 1, 2
        // for account[1] we have to see 2 tokens: 3, 4

        balanceOfERC721 = await snarkerc721.balanceOf(accounts[0]);
        assert.equal(balanceOfERC721, 3, "balance of account0 is wrong");

        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 0);
        assert.equal(tokenId, 2, "wrong 1st tokenId for account0");
        let ownerOfToken = await snarkerc721.ownerOf(tokenId);
        assert.equal(ownerOfToken.toUpperCase(), accounts[0].toUpperCase(), "wrong owner of token");
        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 1);
        assert.equal(tokenId, 1, "wrong 2nd tokenId for account0");
        ownerOfToken = await snarkerc721.ownerOf(tokenId);
        assert.equal(ownerOfToken, accounts[0], "wrong owner of token");
        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 2);
        assert.equal(tokenId, 3, "wrong 3th tokenId for account0");
        ownerOfToken = await snarkerc721.ownerOf(tokenId);
        assert.equal(ownerOfToken, accounts[1], "wrong owner of token");

        balanceOfERC721 = await snarkerc721.balanceOf(accounts[1]);
        assert.equal(balanceOfERC721, 2, "balance of account1 is wrong");

        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 0);
        assert.equal(tokenId, 3, "wrong 1st tokenId for account1");
        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 1);
        assert.equal(tokenId, 4, "wrong 3th tokenId for account1");

        expect(await snarkloan.doUserHaveAccessToToken(accounts[0], 1)).is.true;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[0], 2)).is.true;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[0], 3)).is.true;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[0], 4)).is.false;

        expect(await snarkloan.doUserHaveAccessToToken(accounts[1], 1)).is.false;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[1], 2)).is.false;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[1], 3)).is.true;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[1], 4)).is.true;
        
        // wait for loan stopping and check the number of loans
        pause(60000);

        balanceOfERC721 = await snarkerc721.balanceOf(accounts[0]);
        assert.equal(balanceOfERC721, 2, "balance of account0 is wrong");

        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 0);
        assert.equal(tokenId, 1, "token id should be equal 1");

        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[0], 1);
        assert.equal(tokenId, 2, "token id should be equal 2");

        balanceOfERC721 = await snarkerc721.balanceOf(accounts[1]);
        assert.equal(balanceOfERC721, 2, "balance of account1 is wrong");

        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 0);
        assert.equal(tokenId, 3);

        tokenId = await snarkerc721.tokenOfOwnerByIndex(accounts[1], 1);
        assert.equal(tokenId, 4);

        balanceOfERC721 = await snarkerc721.balanceOf(accounts[2]);
        assert.equal(balanceOfERC721, 0, "balance of account2 is wrong");

        expect(await snarkloan.doUserHaveAccessToToken(accounts[0], 1)).is.true;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[0], 2)).is.true;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[0], 3)).is.false;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[0], 4)).is.false;

        expect(await snarkloan.doUserHaveAccessToToken(accounts[1], 1)).is.false;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[1], 2)).is.false;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[1], 3)).is.true;
        expect(await snarkloan.doUserHaveAccessToToken(accounts[1], 4)).is.true;
        
    });

    it("test of loan shifting by time", async () => {
        let loanId = await snarkloan.getLoanId();
        expect(loanId.toNumber()).to.equal(0);

        let isActive = await snarkloan.isLoanActive(loanId);
        assert.isFalse(isActive, "Loan is active and it's wrong");

        let isFinished = await snarkloan.isLoanFinished(loanId);
        assert.isTrue(isFinished, "Loan is not finished and it's wrong");

        await snarkloan.toShiftPointer();

        const _dt_n     = new Date();
        const _year_n   = _dt_n.getFullYear();
        const _month_n  = _dt_n.getMonth();
        const _date_n   = _dt_n.getDate();
        const _hours_n  = _dt_n.getHours();
        const _min_n    = _dt_n.getMinutes();

        // time of starting and finishing of the first loan
        const l1s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 1, 0) / 1000;
        const l1f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 2, 0) / 1000;
        
        // time of starting and finishing of second loan
        const l2s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 3, 0) / 1000;
        const l2f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 4, 0) / 1000;
    
        // let the price of loans will be the same for both of them
        const valueOfLoan = web3.utils.toWei('2', "ether");

        // create a first loan which has to start in a minute
        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();
        console.log(`before, Bottom boundary: ${bottomBoundary}, Top boundary: ${topBoundary}`);
        console.log(`Find position: ${ JSON.stringify(await snarktest.findPosition(l1s, l1f)) }`);

        await snarkloan.createLoan(l1s, l1f, { from: accounts[0], value: valueOfLoan });
        const loanId_1 = await snarktest.getMaxLoanId();
        console.log(`LoanId of 1st loan: ${ loanId_1 }`);

        pointer = await snarktest.getLoanPointer();
        console.log(`Loan Pointer before start loan 1: ${ pointer }`);
        
        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();
        console.log(`after, Bottom boundary: ${bottomBoundary}, Top boundary: ${topBoundary}`);

        isLoanFinished = await snarkloan.isLoanFinished(loanId_1);
        assert.isFalse(isLoanFinished, "Loan 1 is finished now and it's wrong");

        loanDetail = await snarkloan.getLoanDetail(loanId_1);
        console.log(`
            Start date: ${ new BN(loanDetail[1]).toNumber() },
            End date: ${ new BN(loanDetail[2]).toNumber() },
            Previous loanId: ${ loanDetail[3] },
            Next loanId: ${ loanDetail[4] },
        `);

        // check if a position is right\
        console.log(`Find position: ${ JSON.stringify(await snarktest.findPosition(l2s, l2f)) }`);
        
        // create a second loan which has to start in 3 minutes
        await snarkloan.createLoan(l2s, l2f, { from: accounts[0], value: valueOfLoan });
        const loanId_2 = await snarktest.getMaxLoanId();
        console.log(`LoanId of 2nd loan: ${ loanId_2 }`);

        pointer = await snarktest.getLoanPointer();
        console.log(`Loan Pointer before start loan 2: ${ pointer }`);

        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();
        console.log(`after, Bottom boundary: ${bottomBoundary}, Top boundary: ${topBoundary}`);

        isLoanFinished = await snarkloan.isLoanFinished(loanId_2);
        assert.isFalse(isLoanFinished, "Loan 2 is finished now and it's wrong");

        loanDetail = await snarkloan.getLoanDetail(loanId_2);
        console.log(`
            Start date: ${ new BN(loanDetail[1]).toNumber() },
            End date: ${ new BN(loanDetail[2]).toNumber() },
            Previous loanId: ${ loanDetail[3] },
            Next loanId: ${ loanDetail[4] }
        `);

        // check if the loan was created
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(2);

        // wait a minute to start loan work
        pause(60000);

        isLoanFinished = await snarkloan.isLoanFinished(loanId_1);
        assert.isFalse(isLoanFinished, "Loan is finished now and it's wrong");

        isActive = await snarkloan.isLoanActive(loanId_1);
        assert.isTrue(isActive, "Loan is not active and it's wrong");

        pointer = await snarktest.getLoanPointer();
        console.log(`Loan Pointer after start loan: ${ pointer }`);

        loanId = await snarkloan.getLoanId();
        expect(loanId.toNumber()).to.equal(loanId_1.toNumber());

        // wait a minute to sure the loan stopped and started a new one
        pause(120000);
        
        loanId = await snarkloan.getLoanId();
        expect(loanId.toNumber()).to.equal(loanId_2.toNumber());

        isActive = await snarkloan.isLoanActive(loanId);
        assert.isTrue(isActive, "Loan is not active and it's wrong");

        pause(60000);
        
        loanId = await snarkloan.getLoanId();
        expect(loanId.toNumber()).to.equal(0);

        isActive = await snarkloan.isLoanActive(loanId);
        assert.isFalse(isActive, "Loan is active and it's wrong");

    });

    it("test duration of a loan upon creation one", async () => {

        const duration = await snarkloan.getDefaultLoanDuration();
        expect(duration.toNumber()).to.equal(1);

        const _dt_n     = new Date();
        const _year_n   = _dt_n.getFullYear();
        const _month_n  = _dt_n.getMonth();
        const _date_n   = _dt_n.getDate();
        const _hours_n  = _dt_n.getHours();
        const _min_n    = _dt_n.getMinutes();

        const l1s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 10, 0) / 1000;
        const l1f = new Date(_year_n, _month_n, _date_n + 1, _hours_n, _min_n + 10, 0) / 1000;

        console.log(`1. s: ${l1s}, f: ${l1f}, f-s=${l1f - l1s}`);
        
        const l2s  = new Date(_year_n, _month_n, _date_n + 1, _hours_n, _min_n + 10, 0) / 1000;
        const l2f = new Date(_year_n, _month_n, _date_n + 2, _hours_n, _min_n + 11, 0) / 1000;

        console.log(`1. s: ${l2s}, f: ${l2f}, f-s=${l2f - l2s}`);

        const valueOfLoan = web3.utils.toWei('2', "ether");

        await snarkloan.createLoan(l1s, l1f, { from: accounts[0], value: valueOfLoan });

        try {
            await snarkloan.createLoan(l2s, l2f, { from: accounts[0], value: valueOfLoan });
        } catch (e) {
            expect(e.message).to.equal('Returned error: VM Exception while processing transaction: revert Duration exceeds a max value -- Reason given: Duration exceeds a max value.');
        }
    });

    it("test overlapping of loans", async () => {
        const _dt_n     = new Date();
        const _year_n   = _dt_n.getFullYear();
        const _month_n  = _dt_n.getMonth();
        const _date_n   = _dt_n.getDate();
        const _hours_n  = _dt_n.getHours();
        const _min_n    = _dt_n.getMinutes();

        const l1s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 2, 0) / 1000;
        const l1f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 3, 0) / 1000;
        
        const l2s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 5, 0) / 1000;
        const l2f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 6, 0) / 1000;

        const l3s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 8, 0) / 1000;
        const l3f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 9, 0) / 1000;

        const l4s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 1, 0) / 1000;
        const l4f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 2, 0) / 1000;

        const l5s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 7, 0) / 1000;
        const l5f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 10, 0) / 1000;

        const l6s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 1, 0) / 1000;
        const l6f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 10, 0) / 1000;

        const valueOfLoan = web3.utils.toWei('2', "ether");

        await snarkloan.createLoan(l1s, l1f, { from: accounts[0], value: valueOfLoan });
        console.log(`Loan #1 was successfully created`);
        await snarkloan.createLoan(l2s, l2f, { from: accounts[0], value: valueOfLoan });
        console.log(`Loan #2 was successfully created`);
        await snarkloan.createLoan(l3s, l3f, { from: accounts[0], value: valueOfLoan });
        console.log(`Loan #3 was successfully created`);
        
        try {
            await snarkloan.createLoan(l4s, l4f, { from: accounts[0], value: valueOfLoan });
        } catch (e) {
            console.log(`An exception occurred upon creation of Loan #4`);
            expect(e.message).to.equal('Returned error: VM Exception while processing transaction: revert Selected period has not to crossed with existing loans -- Reason given: Selected period has not to crossed with existing loans.');
        }

        try {
            await snarkloan.createLoan(l5s, l5f, { from: accounts[0], value: valueOfLoan });
        } catch (e) {
            console.log(`An exception occurred upon creation of Loan #5`);
            expect(e.message).to.equal('Returned error: VM Exception while processing transaction: revert Selected period has not to crossed with existing loans -- Reason given: Selected period has not to crossed with existing loans.');
        }

        try {
            await snarkloan.createLoan(l6s, l6f, { from: accounts[0], value: valueOfLoan });
        } catch (e) {
            console.log(`An exception occurred upon creation of Loan #6`);
            expect(e.message).to.equal('Returned error: VM Exception while processing transaction: revert Selected period has not to crossed with existing loans -- Reason given: Selected period has not to crossed with existing loans.');
        }
        
    });

    it("test deleteAllLoans", async () => {
        await snarktest.deleteAllLoans(100);
    });

    it("add 3 loans, delete 2 the last and wait when the first finish work", async () => {
        const _dt_n     = new Date();
        const _year_n   = _dt_n.getFullYear();
        const _month_n  = _dt_n.getMonth();
        const _date_n   = _dt_n.getDate();
        const _hours_n  = _dt_n.getHours();
        const _min_n    = _dt_n.getMinutes();
        const valueOfLoan = web3.utils.toWei('2', "ether");
        
        const l1s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 1, 0) / 1000;
        const l1f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 2, 0) / 1000;
        
        const l2s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 2, 10) / 1000;
        const l2f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 3, 0) / 1000;
        
        const l3s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 3, 10) / 1000;
        const l3f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 4, 0) / 1000;
        
        let loansCount = await snarkloan.getNumberOfLoans();
        expect(loansCount.toNumber()).to.equal(0);

        await snarkloan.createLoan(l1s, l1f, { from: accounts[0], value: valueOfLoan });
        const loanId_1 = await snarktest.getMaxLoanId();

        await snarkloan.createLoan(l2s, l2f, { from: accounts[0], value: valueOfLoan });
        const loanId_2 = await snarktest.getMaxLoanId();

        await snarkloan.createLoan(l3s, l3f, { from: accounts[0], value: valueOfLoan });
        const loanId_3 = await snarktest.getMaxLoanId();

        loansCount = await snarkloan.getNumberOfLoans();
        expect(loansCount.toNumber()).to.equal(3);

        let pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(loanId_1.toNumber());

        let bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        expect(bottomBoundary.toNumber()).to.equal(l1s);

        let topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();
        expect(topBoundary.toNumber()).to.equal(l3f);

        await snarkloan.deleteLoan(loanId_2);
        await snarkloan.deleteLoan(loanId_3);

        loansCount = await snarkloan.getNumberOfLoans();
        expect(loansCount.toNumber()).to.equal(1);

        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(loanId_1.toNumber());

        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        expect(bottomBoundary.toNumber()).to.equal(l1s);

        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();
        expect(topBoundary.toNumber()).to.equal(l1f);

        let isLoanFinished = await snarkloan.isLoanFinished(loanId_1);
        assert.isFalse(isLoanFinished, "Loan is finished now and it's wrong");
        
        let isActive = await snarkloan.isLoanActive(loanId_1);
        assert.isFalse(isActive, "Loan is finished now and it's wrong");

        pause(60000);

        isActive = await snarkloan.isLoanActive(loanId_1);
        assert.isTrue(isActive, "Loan is not active now and it's wrong");

        isLoanFinished = await snarkloan.isLoanFinished(loanId_1);
        assert.isFalse(isLoanFinished, "Loan is finished now and it's wrong");

        pause(60000);

        isActive = await snarkloan.isLoanActive(loanId_1);
        assert.isFalse(isActive, "Loan is active now and it's wrong");

        isLoanFinished = await snarkloan.isLoanFinished(loanId_1);
        assert.isTrue(isLoanFinished, "Loan is not finished now and it's wrong");

        loansCount = await snarkloan.getNumberOfLoans();
        expect(loansCount.toNumber()).to.equal(1);

        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(0);

        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        expect(bottomBoundary.toNumber()).to.equal(l1s);

        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();
        expect(topBoundary.toNumber()).to.equal(l1f);

        await snarkloan.createLoan(l3s, l3f, { from: accounts[0], value: valueOfLoan });
        const loanId_4 = await snarktest.getMaxLoanId();

        loansCount = await snarkloan.getNumberOfLoans();
        expect(loansCount.toNumber()).to.equal(1);

        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(loanId_4.toNumber());

        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        expect(bottomBoundary.toNumber()).to.equal(l3s);

        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();
        expect(topBoundary.toNumber()).to.equal(l3f);

    });
});
