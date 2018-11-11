pragma solidity ^0.4.24;

import "./openzeppelin/Ownable.sol";
import "./SnarkDefinitions.sol";
import "./snarklibs/SnarkBaseLib.sol";
import "./snarklibs/SnarkCommonLib.sol";
import "./snarklibs/SnarkLoanLib.sol";
import "./openzeppelin/SafeMath.sol";


/// @title Contract provides a functionality to work with loans
/// @author Vitali Hurski
contract SnarkLoan is Ownable, SnarkDefinitions {

    using SnarkBaseLib for address;
    using SnarkCommonLib for address;
    using SnarkLoanLib for address;
    using SafeMath for uint256;

    address private _storage;

    event LoanCreated(
        address indexed loanBidOwner, 
        uint256 loanId, 
        uint256[] unacceptedTokens
    );

    event LoanAccepted(address indexed tokenOwner, uint256 loanId, uint256 tokenId);
    event LoanDeclined(address indexed tokenOwner, uint256 loanId, uint256 tokenId);
    event LoanStarted(uint256 loanId);
    event TokensBorrowed(address indexed loanOwner, uint256[] tokens);
    event LoanFinished(uint256 loanId);
    event LoanDeleted(uint256 loanId);
    event TokenCanceledInLoans(uint256 tokenId, uint256[] loanList);

    modifier restrictedAccess() {
        if (_storage.isRestrictedAccess()) {
            require(msg.sender == owner, "only Snark can perform the function");
        }
        _;
    }    

    modifier correctLoan(uint256 loanId) {
        require(loanId > 0 && loanId <= _storage.getTotalNumberOfLoans(), "Loan id is wrong");
        _;
    }

    modifier onlyLoanOwner(uint256 loanId) {
        require(msg.sender == _storage.getOwnerOfLoan(loanId), "Only loan owner can borrow tokens");
        _;
    }

    constructor(address storageAddress) public {
        _storage = storageAddress;
    }
    
    /// @dev Function to destroy a contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    function setDefaultLoanDuration(uint256 duration) public onlyOwner {
        _storage.setDefaultLoanDuration(duration);
    }

    function getDefaultLoanDuration() public view returns (uint256) {
        return _storage.getDefaultLoanDuration();
    }

    /// @dev в качестве startDate дата должна приходить в формате datetime
    /// без учета времени, например: 1298851200000 => 2011-02-28T00:00:00.000Z
    /// duration - простое число в днях, например 10 (дней)
    function createLoan(uint256[] tokensIds, uint256 startDate, uint256 duration) public payable restrictedAccess {
        require(duration <= getDefaultLoanDuration(), "Duration exceeds a max value");
        // check if the user requested their own tokens
        for (uint256 i = 0; i < tokensIds.length; i++) {
            require(tokensIds[i] <= _storage.getTotalNumberOfTokens(), "Token id has to be valid");
            require(
                _storage.getOwnerOfToken(tokensIds[i]) != msg.sender,
                "Borrower can't request loan for their own tokens"
            );
            // проверяем, чтобы токен сейчас не продавался
            require(_storage.getSaleTypeToToken(
                tokensIds[i]) != uint256(SaleType.Offer), 
                "Token's sale type cannot be 'Offer'"
            );
        }
         // Transfer money funds into the contract 
        if (msg.value > 0) _storage.addPendingWithdrawals(_storage, msg.value);
        // Create new entry for a Loan
        uint256 loanId = _storage.createLoan(msg.sender, msg.value, tokensIds, startDate, duration);
        bool isAgree = false;
        for (i = 0; i < tokensIds.length; i++) {
            address tokenOwner = _storage.getOwnerOfToken(tokensIds[i]);
            // запоминаем владельца токена, чтобы потом знать кому возвращать токен
            _storage.setActualTokenOwnerForLoan(loanId, tokensIds[i], tokenOwner);
            if (_storage.isTokenBusyForPeriod(tokensIds[i], startDate, duration)) {
                // токен уже занят. перекидываем его в Declined List - 2
                _storage.addTokenToListOfLoan(loanId, tokensIds[i], 2);
            } else {
                isAgree = (msg.sender == owner) ? 
                    _storage.isTokenAcceptOfLoanRequestFromSnark(tokensIds[i]) :
                    _storage.isTokenAcceptOfLoanRequestFromOthers(tokensIds[i]);
                if (isAgree) {
                    // занимаем период в календаре и какой лоан застолбил его день
                    _storage.makeTokenBusyForPeriod(loanId, tokensIds[i], startDate, duration);
                    // перекидываем токен в Approved List - 1
                    _storage.addTokenToListOfLoan(loanId, tokensIds[i], 1);
                } else {
                    _storage.addLoanRequestToTokenOwner(
                        tokenOwner,
                        tokensIds[i],
                        loanId
                    );
                }
            }
        }
        emit LoanCreated(msg.sender, loanId, _storage.getTokensListOfLoanByType(loanId, 0));
    }

    /// @notice пользователь соглашается с запросом на заем токена
    function acceptLoan(uint256 loanId, uint256[] tokenIds) public {
        require(tokenIds.length > 0, "Array of tokens can't be empty");
        // можно принять условия на лоан только пока он не начал свою работу
        // и убеждиться, что владелец лоана не удалил его до этого момента
        require(
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Active) &&
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Finished),
            "Loan can't be in 'Active' of 'Finished' status"
        );

        uint256 startDate = _storage.getStartDateOfLoan(loanId);
        uint256 duration = _storage.getDurationOfLoan(loanId);
        uint256 numberOfTokens = _storage.getOwnedTokensCount(msg.sender);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0 && tokenIds[i] <= numberOfTokens, "Token has to be exist");

            address _ownerOfToken = _storage.getOwnerOfToken(tokenIds[i]);
            require(msg.sender == _ownerOfToken, "Only the token owner can accept a loan request.");

            uint256 _saleType = _storage.getSaleTypeToToken(tokenIds[i]);
            require(_saleType != uint256(SaleType.Offer), "Token's sale type cannot be 'Offer'");

            // проверяем, занят ли этот токен на запрашиваемые даты или нет
            if (_storage.isTokenBusyForPeriod(tokenIds[i], startDate, duration)) {
                // занятый токен перемещаем в Declined list
                _storage.addTokenToListOfLoan(loanId, tokenIds[i], 2);
                // Оповещаем, что токен отвергнут
                emit LoanDeclined(msg.sender, loanId, tokenIds[i]);
            } else {
                // свободный токен перемещаем в Approved list
                _storage.addTokenToListOfLoan(loanId, tokenIds[i], 1);
                // занимаем в календаре токена запрашиваемые даты
                _storage.makeTokenBusyForPeriod(loanId, tokenIds[i], startDate, duration);
                // Оповещаем, что токен аппрувнут
                emit LoanAccepted(msg.sender, loanId, tokenIds[i]);
            }
            // удаляем request у пользователя на данный токен для этого кредита
            _storage.deleteLoanRequestFromTokenOwner(loanId, tokenIds[i]);
        }
    }

    /// @notice просто помечает, что лоан начался. функция должна быть максимально "легкой",
    /// так как плата будет производиться со стороны Snark
    /// @dev после вызова этой функции необходимо произвести оценку вызова функции StopLoan со 
    /// стороны backend-a с помощью contractInstance.method.estimateGas(ARGS...) и записать
    /// эту стоимость с помощью setCostOfStopLoanOperationForLoan, чтобы при вызове 
    /// функции borrowTokensOfLoan на клиенте выставлять соответствующую стоимость.
    /// Вызывать функцию стоит только через минуту после начала суток (в 0:01), дабы
    /// гарантировать, что предыдущая аренда была остановлена. Например, была аренда
    /// с 14 числа на 3 дня. Значит запуск должен произойти 14 числа в 0:01, т.к. 13-ое число
    /// должно отработать полностью, если там была аренда и в начале суток 14 числа должна была
    /// произойти остановка предыдущего лоана ровно в 0:00.
    function startLoan(uint256 loanId) public onlyOwner correctLoan(loanId) {
        // проверяем, чтобы не было случайного повторного запуска
        require(
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Active) &&
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Finished),
            "Loan can't be in 'Active' of 'Finished' status"
        );
        // выставляем самому лоану saleStatus = Active
        _storage.setLoanSaleStatus(loanId, 2); // 2 - Active
        // распределяем деньги за аренду лоана между владельцами участвующих токенов
        uint256 loanPrice = _storage.getPriceOfLoan(loanId);
        if (loanPrice > 0) {
            // получаем список токенов, которые будут переданы в аренду
            uint256[] memory tokenList = _storage.getTokensListOfLoanByType(loanId, 1);
            // вычисляем сумму, которая будет перечислена каждому владельцу токена
            uint256 income = loanPrice.div(tokenList.length);
            for (uint256 i = 0; i < tokenList.length; i++) {
                address tokenOwner = _storage.getActualTokenOwnerForLoan(loanId, tokenList[i]);
                // списываем сумму с баланса контракта
                _storage.subPendingWithdrawals(_storage, income);
                // и зачисляем ее на баланс владельца токена
                _storage.addPendingWithdrawals(tokenOwner, income);
            }
        }

        emit LoanStarted(loanId);
    }

    /// @notice функция производит перевод токенов в кошелек владельца лоана,
    /// при этом ему необходимо заплатить также и за операцию обратного перевода
    function borrowLoanedTokens(uint256 loanId) public payable onlyLoanOwner(loanId) correctLoan(loanId) {
        // вызвать эту функцию можно только, если лоан уже активный
        require(_storage.getLoanSaleStatus(loanId) == uint256(SaleStatus.Active), "Loan is not active");
        /*************************************************************/
        // Проверяем на правильность пришедшей суммы
        uint256 price = _storage.getCostOfStopLoanOperationForLoan(loanId);
        require(msg.value >= price, "");
        // перекидываем деньги на снарковский кошелек, т.к. с него будет 
        // вызываться обратная передача токенов их владельцам
        address snarkWallet = _storage.getSnarkWalletAddress();
        snarkWallet.transfer(msg.value);
        /*************************************************************/
        // если остались токены в списке NotApproved, то перекидываем их в Declined
        // и удаляем все запросы из списка владельцев токенов
        uint256[] memory notApprovedTokens = _storage.getTokensListOfLoanByType(loanId, 0);
        for (uint256 i = 0; i < notApprovedTokens.length; i++) {
            _storage.addTokenToListOfLoan(loanId, notApprovedTokens[i], 2);
            // и удаляем requests у tokenOwners
            _storage.deleteLoanRequestFromTokenOwner(loanId, notApprovedTokens[i]);
        }
        // выставляем всем токенам в Approved списке saleType = Loan
        uint256[] memory approvedTokens = _storage.getTokensListOfLoanByType(loanId, 1);
        for (i = 0; i < approvedTokens.length; i++) {
            _storage.setSaleTypeToToken(approvedTokens[i], uint256(SaleType.Loan));
            _storage.transferToken(
                approvedTokens[i], 
                _storage.getOwnerOfToken(approvedTokens[i]), 
                msg.sender
            );
        }

        emit TokensBorrowed(msg.sender, approvedTokens);
    }

    /// @notice Only contract can end loan according to schedule
    /// @dev функцию надо вызывать ровно в начале суток, по истечению переода, например,
    /// аренда с 12 числа на 3 дня. Это значит вызов этой функции должен произойти 15 числа в 0:00.
    function stopLoan(uint256 loanId) public onlyOwner correctLoan(loanId) {
        // остановить мы может только работающий лоан
        require(_storage.getLoanSaleStatus(loanId) == uint256(SaleStatus.Active), "Loan is not active");
        address loanOwner = _storage.getOwnerOfLoan(loanId);
        _storage.setLoanSaleStatus(loanId, uint256(SaleStatus.Finished));
        uint256[] memory approvedTokens = _storage.getTokensListOfLoanByType(loanId, 1);
        for (uint256 i = 0; i < approvedTokens.length; i++) {
            _storage.setSaleTypeToToken(approvedTokens[i], uint256(SaleType.None));
            address currentOwnerOfToken = _storage.getOwnerOfToken(approvedTokens[i]);
            // проверяем на всякий случай, что токен все еще принадлежит borrower-у
            require(loanOwner == currentOwnerOfToken, "Token owner is not a loan owner yet");
            _storage.transferToken(
                approvedTokens[i],
                loanOwner,
                _storage.getActualTokenOwnerForLoan(loanId, approvedTokens[i])
            );
        }
        // удаляем лоан из списка лоан овнера
        _storage.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId);
        
        emit LoanFinished(loanId);
    }

    /// @notice владелец токена может удалить свой лоан до момента его начала работы
    function deleteLoan(uint256 loanId) public onlyLoanOwner(loanId) correctLoan(loanId) {
        // проверяем статус лоана - он должен быть не активным и не завершенным
        require(
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Active) &&
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Finished),
            "Loan can't be in 'Active' or in 'Finished' status"
        );
        _storage.setLoanSaleStatus(loanId, uint256(SaleStatus.Finished));
        address loanOwner = _storage.getOwnerOfLoan(loanId);
        uint256 startDate = _storage.getStartDateOfLoan(loanId);
        uint256 duration = _storage.getDurationOfLoan(loanId);
        // необходимо обработать только токены, находящиеся в списке Approved
        uint256[] memory approvedTokens = _storage.getTokensListOfLoanByType(loanId, 1);
        for (uint256 i = 0; i < approvedTokens.length; i++) {
            // удаляем из календаря токенов запланированные дни
            _storage.makeTokenFreeForPeriod(approvedTokens[i], startDate, duration);
            // удаляем все запросы к владельцам токенов
            _storage.deleteLoanRequestFromTokenOwner(loanId, approvedTokens[i]);
            // удаляем лоан из списка владельца лоана
            _storage.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId);
        }
        // возвращаем предоплату за аренду, зачисляя на счет владельца лоана
        uint256 loanPrice = _storage.getPriceOfLoan(loanId);
        if (loanPrice > 0) {
            // списываем сумму с баланса контракта
            _storage.subPendingWithdrawals(_storage, loanPrice);
            // и зачисляем ее на баланс владельца токена
            _storage.addPendingWithdrawals(loanOwner, loanPrice);
        }

        emit LoanDeleted(loanId);
    }

    /// @notice позволяет владельцу токена явно отозвать свой токен от участия в лоане
    function cancelTokenInLoan(uint256 tokenId) public {
        require(
            msg.sender == _storage.getOwnerOfToken(tokenId), 
            "Only owner of token can withdraw its token from participation in a loan"
        );
        _storage.setSaleTypeToToken(tokenId, uint256(SaleType.None));
        _storage.cancelTokenInLoan(tokenId);
    }

    /// @notice возвращает токены во всех 3-х списках лоана
    function getTokenListsOfLoanByTypes(uint256 loanId) public view returns (
        uint256[] notApprovedTokensList,
        uint256[] approvedTokensList,
        uint256[] declinedTokensList)
    {
        notApprovedTokensList = _storage.getTokensListOfLoanByType(loanId, 0);
        approvedTokensList = _storage.getTokensListOfLoanByType(loanId, 1);
        declinedTokensList = _storage.getTokensListOfLoanByType(loanId, 2);
    }

    /// @notice возвращает список запросов на аренду по владельцу токена
    function getLoanRequestsListOfTokenOwner(address tokenOwner) public view returns (uint256[]) {
        return _storage.getLoanRequestsListForTokenOwner(tokenOwner);
    }

    /// @notice возвращает список лоанов заемщика
    function getLoansListOfLoanOwner(address loanOwner) public view returns (uint256[]) {
        return _storage.getLoansListOfLoanOwner(loanOwner);
    }

    /// @notice Return loan detail
    function getLoanDetail(uint256 loanId) public view returns (
        uint256 amountOfNonApprovedTokens,
        uint256 amountOfApprovedTokens,
        uint256 amountOfDeclinedTokens,
        uint256 startDate,
        uint256 duration,
        uint256 saleStatus,
        uint256 loanPrice,
        address loanOwner) 
    {
        return _storage.getLoanDetail(loanId);
    }

    /// @notice возвращает стоимость вызова функции StopLoan, 
    /// чтобы можно было выставить ее для borrowLoanedTokens
    function getCostOfStopLoanOperationForLoan(uint256 loanId) public view returns (uint256) {
        return _storage.getCostOfStopLoanOperationForLoan(loanId);
    }

    /// @notice записываем стоимость вызова функции StopLoan
    function setCostOfStopLoanOperationForLoan(uint256 loanId, uint256 costOfStopOperation) public onlyOwner {
        _storage.setCostOfStopLoanOperationForLoan(loanId, costOfStopOperation);
    }

}
