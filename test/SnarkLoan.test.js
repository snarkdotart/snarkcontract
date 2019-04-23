var SnarkLoan = artifacts.require("SnarkLoan");
var SnarkBase = artifacts.require("SnarkBase");
var SnarkStorage = artifacts.require("SnarkStorage");
var SnarkTestFunctions = artifacts.require("SnarkTestFunctions");
var SnarkOfferBid = artifacts.require("SnarkOfferBid");

const BN = web3.utils.BN;

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
        snarkofferbid   = await SnarkOfferBid.deployed();
        snarkloan       = await SnarkLoan.deployed();
        snarktest       = await SnarkTestFunctions.deployed();

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

        // добавляем первый лоан
        await snarkloan.createLoan(loan_1_start, loan_1_finish, { from: accounts[0], value: valueOfLoan });

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

});
