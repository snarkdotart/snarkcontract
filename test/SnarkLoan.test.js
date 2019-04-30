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

        // проверяем, что нет лоанов
        let countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(0);

        // а также возвращается пустой список лоанов
        let allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.be.empty;

        // указатель на лоан должен быть пустой
        let pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(0);

        // проверяем как установлены верхния и нижняя граница
        let topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();
        let bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();

        expect(topBoundary.toNumber()).to.equal(0);
        expect(bottomBoundary.toNumber()).to.equal(0);

        let findplace = await snarktest.findPosition(loan_1_start, loan_1_finish);
        console.log(`find position for loan 1: ${JSON.stringify(findplace)}`);

        // проверим количество лоанов у пользователя перед добавлением. Должно быть 0
        let numberOfOwnerLoans = await snarkloan.getCountOfOwnerLoans(accounts[0]);
        expect(numberOfOwnerLoans.toNumber()).to.equal(0);

        // проверяем количество денег, хранящихся на SnarkStorage и SnarkLoan. После создания Loan-а 
        // количество денег должно увеличиться только на SnarkStorage
        const balanceOfSnarkStorage = await web3.eth.getBalance(snarkstorage.address);
        const balanceOfSnarkLoan = await web3.eth.getBalance(snarkloan.address);

        // добавляем первый лоан
        await snarkloan.createLoan(loan_1_start, loan_1_finish, { from: accounts[0], value: valueOfLoan });

        const balanceOfSnarkStorage_after = await web3.eth.getBalance(snarkstorage.address);
        const balanceOfSnarkLoan_after = await web3.eth.getBalance(snarkloan.address);

        expect(new BN(balanceOfSnarkStorage).eq(new BN(balanceOfSnarkStorage_after).sub(new BN(valueOfLoan)))).is.true;
        expect(new BN(balanceOfSnarkLoan).eq(new BN(balanceOfSnarkLoan_after))).is.true;

        // убеждаемся, что количество лоанов увеличилось, стало 1
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(1);

        // получаем указатель на лоан и смотрим куда он указывает
        // пока должен указывать на первый лоан
        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(1);

        // проверяем сколько будет возвращать лоанов в списке
        // список должен состоять из одного элемента и содержать лоан с id 1, т.к. он первый
        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(1);
        expect(allloans[0].toNumber()).to.equal(1);

        // проверяем, что данные по лоану записались как положено
        const loanDetail = await snarkloan.getLoanDetail(countOfLoans);
        expect(loanDetail[0].toUpperCase()).to.equal(accounts[0].toUpperCase());
        expect(loanDetail[1].toNumber()).to.equal(loan_1_start);
        expect(loanDetail[2].toNumber()).to.equal(loan_1_finish);
        expect(loanDetail[3].toNumber()).to.equal(0);
        expect(loanDetail[4].toNumber()).to.equal(0);
        expect(loanDetail[5].eq(new BN(valueOfLoan))).to.be.true;

        // проверяем как установлены верхния и нижняя граница
        // ожидаем, что будут соответствовать первому лоану
        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_1_start);
        expect(topBoundary.toNumber()).to.equal(loan_1_finish);

        // готовимся к созданию второго лоана, который гарантированно не пересекается с первым
        findplace = await snarktest.findPosition(loan_2_start, loan_2_finish);
        console.log(`find position for loan 2: ${JSON.stringify(findplace)}`);

        // добавляем второй лоан
        await snarkloan.createLoan(loan_2_start, loan_2_finish, { from: accounts[0], value: valueOfLoan });

        // убеждаемся, что теперь у нас именно 2 лоана
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(2);

        // проверяем, что список содержит именно 2 лоана
        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(2);
        expect(allloans[0].toNumber()).to.equal(1);
        expect(allloans[1].toNumber()).to.equal(2);

        // проверяем, что указатель на лоан не сбился
        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(1);

        // проверяем как установлены верхния и нижняя граница
        // ожидаем, что старт будет соответствовать первому лоану, а финиш - второму
        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_1_start);
        expect(topBoundary.toNumber()).to.equal(loan_2_finish);

        // добавляем 3-й лоан, который должен попасть во временной промежуток между 1-м и 2-м.
        // При получении списка должны получить в отсортированном по времени следования - 1,3,2
        findplace = await snarktest.findPosition(loan_3_start, loan_3_finish);
        console.log(`find position for loan 3: ${JSON.stringify(findplace)}`);

        // добавляем второй лоан
        await snarkloan.createLoan(loan_3_start, loan_3_finish, { from: accounts[0], value: valueOfLoan });

        // убеждаемся, что теперь у нас именно 3 лоана
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(3);

        // проверяем, что список содержит именно 3 лоана
        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(3);
        expect(allloans[0].toNumber()).to.equal(1);
        expect(allloans[1].toNumber()).to.equal(3);
        expect(allloans[2].toNumber()).to.equal(2);

        // проверяем, что указатель на лоан не сбился
        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(1);

        // проверяем как установлены верхния и нижняя граница
        // ожидаем, что ничего не изменится
        // старт будет соответствовать первому лоану, а финиш - второму
        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_1_start);
        expect(topBoundary.toNumber()).to.equal(loan_2_finish);

        // добавляем 4-й лоан, который должен стать на первое место
        // при этом указатель должен переместиться
        findplace = await snarktest.findPosition(loan_4_start, loan_4_finish);
        console.log(`find position for loan 4: ${JSON.stringify(findplace)}`);

        // добавляем второй лоан
        await snarkloan.createLoan(loan_4_start, loan_4_finish, { from: accounts[0], value: valueOfLoan });

        // убеждаемся, что теперь у нас именно 4 лоана
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(4);

        // проверяем, что список содержит именно 4 лоана
        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(4);
        expect(allloans[0].toNumber()).to.equal(4);
        expect(allloans[1].toNumber()).to.equal(1);
        expect(allloans[2].toNumber()).to.equal(3);
        expect(allloans[3].toNumber()).to.equal(2);

        // проверяем, что указатель на лоан не сбился
        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(4);

        // проверяем как установлены верхния и нижняя граница
        // ожидаем, что ничего не изменится
        // старт будет соответствовать четвертому лоану, а финиш - второму
        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_4_start);
        expect(topBoundary.toNumber()).to.equal(loan_2_finish);

        // добавляем 5-й лоан, который должен стать на последнее место
        // при этом указатель должен остаться прежним
        findplace = await snarktest.findPosition(loan_5_start, loan_5_finish);
        console.log(`find position for loan 5: ${JSON.stringify(findplace)}`);
        // добавляем второй лоан
        await snarkloan.createLoan(loan_5_start, loan_5_finish, { from: accounts[0], value: valueOfLoan });

        // убеждаемся, что теперь у нас именно 5 лоана
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(5);

        // проверяем, что список содержит именно 5 лоана
        allloans = await snarkloan.getListOfLoans();
        expect(allloans).to.have.lengthOf(5);
        expect(allloans[0].toNumber()).to.equal(4);
        expect(allloans[1].toNumber()).to.equal(1);
        expect(allloans[2].toNumber()).to.equal(3);
        expect(allloans[3].toNumber()).to.equal(2);
        expect(allloans[4].toNumber()).to.equal(5);

        // проверяем, что указатель на лоан не сбился
        pointer = await snarkloan.getLoanId();
        expect(pointer.toNumber()).to.equal(4);

        // проверяем как установлены верхния и нижняя граница
        // ожидаем, что ничего не изменится
        // старт будет соответствовать четвертому лоану, а финиш - пятому
        bottomBoundary = await snarktest.getBottomBoundaryOfLoansPeriod();
        topBoundary = await snarktest.getTopBoundaryOfLoansPeriod();

        expect(bottomBoundary.toNumber()).to.equal(loan_4_start);
        expect(topBoundary.toNumber()).to.equal(loan_5_finish);

        // проверим количество лоанов у пользователя перед добавлением. Должно быть 5
        numberOfOwnerLoans = await snarkloan.getCountOfOwnerLoans(accounts[0]);
        expect(numberOfOwnerLoans.toNumber()).to.equal(5);

        let listOfOwnerLoans = await snarkloan.getListOfLoansOfOwner(accounts[0]);
        expect(listOfOwnerLoans).to.have.lengthOf(5);
        expect(listOfOwnerLoans[0].toNumber()).to.equal(1);
        expect(listOfOwnerLoans[1].toNumber()).to.equal(2);
        expect(listOfOwnerLoans[2].toNumber()).to.equal(3);
        expect(listOfOwnerLoans[3].toNumber()).to.equal(4);
        expect(listOfOwnerLoans[4].toNumber()).to.equal(5);
    });

    it("test delete of loan", async () => {
        // убеждаемся, что у нас до сих пор 5 лоанов
        let countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(5);

        // и что они находятся в той же самой последовательности
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

        // проверить удаление лоана, находящегося в списке на первой позиции
        await snarkloan.deleteLoan(4);
       
        // проверяем параметры
        // количество лоанов должно стать 4
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(4);

        // и что они находятся в той же самой последовательности
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

        // проверить удаление лоана, находящегося в списке на последней позиции
        await snarkloan.deleteLoan(5);
       
        // количество лоанов должно стать 3
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(3);

        // и что они находятся в той же самой последовательности
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

        // проверить удаление лоана, находящегося в списке посередине
        await snarkloan.deleteLoan(3);
       
        // количество лоанов должно стать 2
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(2);

        // и что они находятся в той же самой последовательности
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

        // проверить удаление лоана, находящегося в начале
        await snarkloan.deleteLoan(1);
       
        // количество лоанов должно стать 1
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(1);

        // и что они находятся в той же самой последовательности
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

        // проверить удаление последнего лоана
        await snarkloan.deleteLoan(2);
       
        // количество лоанов должно стать 0
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

    });

    it("test ApprovedTokensForLoan array", async () => {
        let countOfTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(countOfTokens, 0, "error on step 1");
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

        await snarkbase.createProfitShareScheme(accounts[1], [accounts[0], accounts[2]], [20, 80]);
        profitSchemeId = await snarkbase.getProfitShareSchemesTotalCount();

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

        let totalSupply = await snarkerc721.totalSupply();
        assert.equal(totalSupply, 4, "total supply is wrong");

        let countApprovedTokens = await snarktest.getTotalNumberOfTokensInApprovedTokensForLoan();
        assert.equal(countApprovedTokens.toNumber(), 2, "wrong count of tokens in approved list");

        let tokenId = await snarktest.getTokenFromApprovedTokensForLoanByIndex(0);
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

        let isActive = await snarkloan.isLoanActive();
        assert.isFalse(isActive, "Loan is active and it's wrong");
    
        // надо добавить Loan и дождаться, чтобы он начал работать
        let countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(0);

        const _dt_n     = new Date();
        const _year_n   = _dt_n.getFullYear();
        const _month_n  = _dt_n.getMonth();
        const _date_n   = _dt_n.getDate();
        const _hours_n  = _dt_n.getHours();
        const _min_n    = _dt_n.getMinutes();
        const l1s  = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 1, 0) / 1000;
        const l1f = new Date(_year_n, _month_n, _date_n, _hours_n, _min_n + 2, 0) / 1000;
    
        const valueOfLoan = web3.utils.toWei('2', "ether");

        // стартовать должен через минуту
        await snarkloan.createLoan(l1s, l1f, { from: accounts[0], value: valueOfLoan });

        // убеждаемся, что через лоан создан
        countOfLoans = await snarkloan.getNumberOfLoans();
        expect(countOfLoans.toNumber()).to.equal(1);

        // надо выждать минуту, чтобы лоан гарантированно начал работу
        pause(60000);

        isActive = await snarkloan.isLoanActive();
        assert.isTrue(isActive, "Loan is not active and it's wrong");
    
        totalSupply = await snarkerc721.totalSupply();
        assert.equal(totalSupply, 4, "total supply is wrong");
        
        // для account[0] было: token 1 - true, token 2 - false
        // для account[1] было: token 3 - true, token 4 - false

        // после старта лоана ожидаем (при loanowner - account[0]):
        // для account[0] видим 3 токена: 3, 1, 2
        // для account[1] видим 2 токена: 3, 4

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
        
        // надо дождаться остановки лоана и проверить обратно количество токенов
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

});
