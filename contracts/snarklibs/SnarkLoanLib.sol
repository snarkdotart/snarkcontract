pragma solidity ^0.4.24;

import "../openzeppelin/SafeMath.sol";
import "../SnarkStorage.sol";


/// @author Vitali Hurski
library SnarkLoanLib {

    using SafeMath for uint256;
    
    event TokenCanceledInLoans(uint256 tokenId, uint256[] loanList);

    function createLoan(
        address storageAddress, 
        address loanOwner,
        uint256 loanPrice,
        uint256[] tokensIds,
        uint256 startDate,
        uint256 duration
    )
        public
        returns (uint256)
    {
        uint256 loanId = increaseNumberOfLoans(storageAddress);
        setOwnerOfLoan(storageAddress, loanOwner, loanId);
        setPriceOfLoan(storageAddress, loanId, loanPrice);
        addLoanToLoanListOfLoanOwner(storageAddress, loanOwner, loanId);
        for (uint256 index = 0; index < tokensIds.length; index++) {
            // Type of List: 0 - NotApproved, 1 - Approved, 2 - Declined
            addTokenToListOfLoan(storageAddress, loanId, tokensIds[index], 0); // 0 - NotApproved
        }
        setStartDateOfLoan(storageAddress, loanId, startDate);
        setDurationOfLoan(storageAddress, loanId, duration);
        setLoanSaleStatus(storageAddress, loanId, 0); // 0 - Prepairing

        return loanId;
    }

    /// @notice увеличивает общее количество лоанов в системе
    function increaseNumberOfLoans(address storageAddress) public returns (uint256) {
        uint256 totalNumber = getTotalNumberOfLoans(storageAddress).add(1);
        SnarkStorage(storageAddress).setUint(keccak256("totalNumberOfLoans"), totalNumber);
        return totalNumber;
    }

    /// @notice возвращает общее количество лоанов в системе
    function getTotalNumberOfLoans(address storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfLoans"));
    }

    /// @notice возвращает владельца loan-а
    function getOwnerOfLoan(address storageAddress, uint256 loanId) public view returns (address) {
        return SnarkStorage(storageAddress).addressStorage(keccak256(abi.encodePacked("loanOwner", loanId)));
    }

    /// @notice устанавливает владельца loan-а
    function setOwnerOfLoan(address storageAddress, address loanOwner, uint256 loanId) public {
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("loanOwner", loanId)),
            loanOwner
        );
    }

    /// @notice Добавляет токен в список определенного типа
    function addTokenToListOfLoan(address storageAddress, uint256 loanId, uint256 tokenId, uint256 listType) public {
        // проверяем, был ли уже включен токен в лоан ранее, или это первый раз
        if (isTokenIncludedInLoan(storageAddress, loanId, tokenId)) {
            // если уже не первый раз, то значит происходит перемещение токена из одного списка в другой
            // а это значит, что его необходимо удалить из предыдущего списка
            // но предварительно надо проверить, не пытаемся ли мы переместить токен в тот же самый список,
            // в котором он уже находиться. И если да, то exception, ибо можно вызвать дублирование токена в списке.
            require(
                getTypeOfTokenListForLoan(storageAddress, loanId, tokenId) != listType, 
                "Token is already belongs selected type"
            );
            removeTokenFromListOfLoan(storageAddress, loanId, tokenId);
        } else {
            // если добавление токена происходит первый раз, то помечаем его как добавленный в лоан
            setTokenAsIncludedInLoan(storageAddress, loanId, tokenId, true);
        }
        // запоминаем тип списка, в который попал токен
        setTypeOfTokenListForLoan(storageAddress, loanId, tokenId, listType);
        // записываем токен в конец списка
        uint256 index = increaseNumberOfTokensInListByType(storageAddress, loanId, listType).sub(1);
        setTokenForLoanListByTypeAndIndex(storageAddress, loanId, listType, index, tokenId);
    }

    /// @notice удаляем токен из списка, в котором он находился до вызова этой функции
    function removeTokenFromListOfLoan(address storageAddress, uint256 loanId, uint256 tokenId) public {
        // получаем тип списка, в котором находится токен
        uint256 listType = getTypeOfTokenListForLoan(storageAddress, loanId, tokenId);
        // удаляем по индексу токен из списка токен
        uint256 indexOfToken = getTokenIndexInListOfLoanByType(storageAddress, loanId, tokenId);
        uint256 maxIndex = getNumberOfTokensInListByType(storageAddress, loanId, listType).sub(1);
        if (indexOfToken < maxIndex) {
            uint256 tokenIdOnLastIndex = getTokenForLoanListByTypeAndIndex(storageAddress, loanId, listType, maxIndex);
            setTokenForLoanListByTypeAndIndex(storageAddress, loanId, listType, indexOfToken, tokenIdOnLastIndex);
        }
        decreaseNumberOfTokensInListByType(storageAddress, loanId, listType);
    }

    /// @notice помогает узнать используется ли токен в лоане или нет
    function isTokenIncludedInLoan(address storageAddress, uint256 loanId, uint256 tokenId)
        public 
        view 
        returns (bool)
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("isTokenIncludedInLoan", loanId, tokenId))
        );
    }

    /// @notice помечаем, что токен используется в выбранном лоане
    function setTokenAsIncludedInLoan(address storageAddress, uint256 loanId, uint256 tokenId, bool isIncluded) 
        public 
    {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("isTokenIncludedInLoan", loanId, tokenId)),
            isIncluded
        );
    }

    /// @notice возвращаем к какому типу списка сейчас принадлежит токен
    function getTypeOfTokenListForLoan(address storageAddress, uint256 loanId, uint256 tokenId) 
        public 
        view 
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("typeOfTokenListForLoan", loanId, tokenId))
        );
    }

    /// @notice запоминаем к какому типу списка сейчас принадлежит токен
    function setTypeOfTokenListForLoan(address storageAddress, uint256 loanId, uint256 tokenId, uint256 listType) 
        public
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("typeOfTokenListForLoan", loanId, tokenId)),
            listType
        );
    }

    /// @notice возвращает количество токетов в определенном списке
    function getNumberOfTokensInListByType(address storageAddress, uint256 loanId, uint256 listType) 
        public 
        view 
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokensInListByType", loanId, listType))
        );
    }

    /// @notice увеличиваем значение количества токенов в определенном списке
    function increaseNumberOfTokensInListByType(address storageAddress, uint256 loanId, uint256 listType) 
        public 
        returns (uint256) 
    {
        uint256 numberOfTokens = getNumberOfTokensInListByType(storageAddress, loanId, listType).add(1);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfTokensInListByType", loanId, listType)), 
            numberOfTokens
        );
        return numberOfTokens;
    }

    /// @notice уменьшаем значение количества токенов в определенном списке
    function decreaseNumberOfTokensInListByType(address storageAddress, uint256 loanId, uint256 listType) 
        public 
        returns (uint256) 
    {
        uint256 numberOfTokens = getNumberOfTokensInListByType(storageAddress, loanId, listType).sub(1);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfTokensInListByType", loanId, listType)), 
            numberOfTokens
        );
        return numberOfTokens;
    }

    /// @notice получаем id токена в списке определенного типа по определенному индексу
    function getTokenForLoanListByTypeAndIndex(address storageAddress, uint256 loanId, uint256 listType, uint256 index) 
        public
        view
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokensListOfLoanByType", loanId, listType, index))
        );
    }

    /// @notice записываем токен в список определенного типа по определенному индексу
    function setTokenForLoanListByTypeAndIndex(
        address storageAddress, 
        uint256 loanId, 
        uint256 listType, 
        uint256 index, 
        uint256 tokenId
    ) 
        public
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("tokensListOfLoanByType", loanId, listType, index)), 
            tokenId
        );
        setTokenIndexInListOfLoanByType(storageAddress, loanId, tokenId, index);
    }

    /// @notice возвращает список токенов в выбранном списке (NotApproved, Approved, Declined)
    function getTokensListOfLoanByType(address storageAddress, uint256 loanId, uint256 listType) 
        public 
        view 
        returns (uint256[]) 
    {
        uint256 amount = getNumberOfTokensInListByType(storageAddress, loanId, listType);
        uint256[] memory list = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            list[i] = getTokenForLoanListByTypeAndIndex(storageAddress, loanId, listType, i);
        }
        return list;
    }

    /// @notice возвращаем индекс для токена в списке. не важно в каком, т.к. токен может находиться
    ///         только в одном списке из 3-х
    function getTokenIndexInListOfLoanByType(
        address storageAddress,
        uint256 loanId,
        uint256 tokenId
    ) 
        public 
        view 
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenIndexInsideListOfLoan", loanId, tokenId))
        );
    }

    /// @notice запоминаем под каким индексом токен записан в списке
    function setTokenIndexInListOfLoanByType(
        address storageAddress,
        uint256 loanId,
        uint256 tokenId,
        uint256 index
    )
        public 
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("tokenIndexInsideListOfLoan", loanId, tokenId)),
            index
        );
    }

    /// @notice возвращает дату начала аренды
    function getStartDateOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToStartDate", loanId)));
    }

    /// @notice устанавливает дату начала аренды
    function setStartDateOfLoan(address storageAddress, uint256 loanId, uint256 startDate) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToStartDate", loanId)), startDate);
    }

    /// @notice возвращает продолжительность аренды
    function getDurationOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToDuration", loanId)));
    }

    /// @notice устанавливает продолжительность аренды
    function setDurationOfLoan(address storageAddress, uint256 loanId, uint256 duration) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToDuration", loanId)), duration);
    }

    /// @notice возвращает статус аренды
    function getLoanSaleStatus(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToSaleStatus", loanId)));
    }

    /// @notice устанавливает статус аренды
    function setLoanSaleStatus(address storageAddress, uint256 loanId, uint256 saleStatus) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToSaleStatus", loanId)), saleStatus);
    }

    /// @notice возвращает установки по кредиту
    function getLoanDetail(address storageAddress, uint256 loanId)
        public 
        view 
        returns 
    (
        uint256 amountOfNonApprovedTokens,
        uint256 amountOfApprovedTokens,
        uint256 amountOfDeclinedTokens,
        uint256 startDate,
        uint256 duration,
        uint256 saleStatus,
        uint256 loanPrice,
        address loanOwner)
    {
        amountOfNonApprovedTokens = getNumberOfTokensInListByType(storageAddress, loanId, 0);
        amountOfApprovedTokens = getNumberOfTokensInListByType(storageAddress, loanId, 1);
        amountOfDeclinedTokens = getNumberOfTokensInListByType(storageAddress, loanId, 2);
        startDate = getStartDateOfLoan(storageAddress, loanId);
        duration = getDurationOfLoan(storageAddress, loanId);
        saleStatus = getLoanSaleStatus(storageAddress, loanId);
        loanPrice = getPriceOfLoan(storageAddress, loanId);
        loanOwner = getOwnerOfLoan(storageAddress, loanId);
    }

    /// @notice проверяет занят ли токен на выбранный период
    function isTokenBusyForPeriod(
        address storageAddress, 
        uint256 tokenId, 
        uint256 startDate, 
        uint256 duration
    ) 
        public 
        view 
        returns (bool) 
    {
        bool isBusy = false;
        uint256 checkDay = startDate;
        for (uint256 i = 0; i < duration; i++) {
            checkDay = startDate + 86400000 * i;
            isBusy = isBusy || isTokenBusyOnDay(storageAddress, tokenId, checkDay);
        }
        return isBusy;
    }

    /// @notice проверяет в календаре токена не занят ли он на определенную дату
    function isTokenBusyOnDay(address storageAddress, uint256 tokenId, uint256 date) public view returns (bool) {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("tokenCalendar", tokenId, date))
        );
    }

    /// @notice возвращает id loan из календаря для токена на определенную дату
    function getEventIdOnDayForToken(address storageAddress, uint256 tokenId, uint256 date) 
        public 
        view 
        returns (uint256) 
    {
        SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenCalendarDayToEventId", tokenId, date))
        );
    }

    /// @notice помечает занятый период для токена
    function makeTokenBusyForPeriod(
        address storageAddress, 
        uint256 loanId, 
        uint256 tokenId, 
        uint256 startDate, 
        uint256 duration
    ) 
        public 
    {
        uint256 busyDay;
        for (uint256 i = 0; i < duration; i++) {
            busyDay = startDate + 86400000 * i;
            makeTokenBusyOnDay(storageAddress, loanId, tokenId, busyDay);
        }
    }

    /// @notice помечает, что токен день занят в установленный день, а также каким кредитом именно
    function makeTokenBusyOnDay(address storageAddress, uint256 loanId, uint256 tokenId, uint256 date) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("tokenCalendar", tokenId, date)),
            true
        );
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("tokenCalendarDayToEventId", tokenId, date)),
            loanId
        );
    }

    /// @notice освобождает занятый период для токена
    function makeTokenFreeForPeriod(
        address storageAddress,
        uint256 tokenId,
        uint256 startDate,
        uint256 duration
    ) 
        public
    {
        uint256 busyDay;
        for (uint256 i = 0; i < duration; i++) {
            busyDay = startDate + 86400000 * i;
            makeTokenFreeOnDay(storageAddress, tokenId, busyDay);
        }
    }

    /// @notice освобождает в календаре выбранный день для токена на определенную дату
    function makeTokenFreeOnDay(address storageAddress, uint256 tokenId, uint256 date) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("tokenCalendar", tokenId, date)),
            false
        );
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("tokenCalendarDayToEventId", tokenId, date)),
            0
        );
    }

    /// @notice возвращает максимальную продолжительность, на которую возможно взять токен в заем
    function getDefaultLoanDuration(address storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("defaultLoanDuration"));
    }

    /// @notice устанавливает максимальную продолжительность, на которую возможно взять токен в заем
    function setDefaultLoanDuration(address storageAddress, uint256 duration) public {
        SnarkStorage(storageAddress).setUint(keccak256("defaultLoanDuration"), duration);
    }

    /// @notice добавляет новый запрос на аренду токена для владельца токена
    function addLoanRequestToTokenOwner(address storageAddress, address tokenOwner, uint256 tokenId, uint256 loanId)
        public 
    {
        uint256 index = increaseCountLoanRequestsForTokenOwner(storageAddress, tokenOwner).sub(1);
        setTokenForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, index, tokenId);
        setLoanForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, index, loanId);
        saveIndexOfLoanRequestForTokenOwnerByTokenAndLoan(storageAddress, tokenOwner, tokenId, loanId, index);
    }

    /// @notice производит запись токена в список запросов по владельцу токена и индексу
    function setTokenForLoanRequestByTokenOwnerAndIndex(
        address storageAddress, 
        address tokenOwner, 
        uint256 index, 
        uint256 tokenId
    )
        public
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("LoanRequestsForToken", tokenOwner, index)),
            tokenId
        );
    }

    /// @notice производит запись лоана в список запросов по владельцу токена и индексу
    function setLoanForLoanRequestByTokenOwnerAndIndex(
        address storageAddress, 
        address tokenOwner, 
        uint256 index, 
        uint256 loanId
    )
        public
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("LoanRequestsForLoan", tokenOwner, index)),
            loanId
        );
    }

    /// @notice сохраяет индекс запроса для владельца токена
    function saveIndexOfLoanRequestForTokenOwnerByTokenAndLoan(
        address storageAddress,
        address tokenOwner,
        uint256 tokenId,
        uint256 loanId,
        uint256 index
    ) 
        public 
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("IndexOfLoanRequestForTokenOwner", tokenOwner, tokenId, loanId)),
            index
        );
    }

    /// @notice возвращает индекс запроса для владельца токена по token id и loan id
    function getIndexOfLoanRequestForTokenOwnerByTokenAndLoan(
        address storageAddress,
        address tokenOwner,
        uint256 tokenId,
        uint256 loanId
    )
        public
        view
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("IndexOfLoanRequestForTokenOwner", tokenOwner, tokenId, loanId))
        );
    }

    /// @notice удаляет запрос из списка владельца токена
    function deleteLoanRequestFromTokenOwner(address storageAddress, uint256 loanId, uint256 tokenId) public {
        address tokenOwner = getOwnerOfLoan(storageAddress, loanId);
        uint256 index = getIndexOfLoanRequestForTokenOwnerByTokenAndLoan(storageAddress, tokenOwner, tokenId, loanId);
        uint256 maxIndex = getCountLoanRequestsForTokenOwner(storageAddress, tokenOwner).sub(1);
        require(index < maxIndex, "Index of request exceed of aIndex of request is wrong");
        if (index < maxIndex) {
            setTokenForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, index, tokenId);
            setLoanForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, index, loanId);
        }
        setTokenForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, maxIndex, 0);
        setLoanForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, maxIndex, 0);
        decreaseCountLoanRequestsForTokenOwner(storageAddress, tokenOwner);
    }

    /// @notice Возвращает информацию запроса по индексу
    function getLoanRequestForTokenOwnerByIndex(address storageAddress, address tokenOwner, uint256 index)
        public
        view
        returns 
    (
        uint256 tokenId, 
        uint256 loanId
    )
    {
        tokenId = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("LoanRequestsForToken", tokenOwner, index))
        );
        loanId = SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("LoanRequestsForLoan", tokenOwner, index))
        );
    }

    /// @notice возвращает общее количество запросов на аренду для владельца токенов
    function getCountLoanRequestsForTokenOwner(address storageAddress, address tokenOwner)
        public
        view
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("LoanRequestsCount", tokenOwner))
        );
    }

    /// @notice увеличивает счетчик числа запросов для владельца токена
    function increaseCountLoanRequestsForTokenOwner(address storageAddress, address tokenOwner)
        public
        returns (uint256)
    {
        uint256 count = getCountLoanRequestsForTokenOwner(storageAddress, tokenOwner).add(1);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("LoanRequestsCount", tokenOwner)),
            count
        );
        return count;
    }

    /// @notice уменьшает счетчик числа запросов для владельца токена
    function decreaseCountLoanRequestsForTokenOwner(address storageAddress, address tokenOwner)
        public
        returns (uint256)
    {
        uint256 count = getCountLoanRequestsForTokenOwner(storageAddress, tokenOwner).sub(1);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("LoanRequestsCount", tokenOwner)),
            count
        );
        return count;
    }

    function getLoanRequestsListForTokenOwner(address storageAddress, address tokenOwner)
        public
        view
        returns (uint256[])
    {
        uint256 count = getCountLoanRequestsForTokenOwner(storageAddress, tokenOwner);
        uint256[] memory list = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            (list[i],) = getLoanRequestForTokenOwnerByIndex(storageAddress, tokenOwner, i);
        }
        return list;
    }
    
    /// @notice возвращает адрес текущего владельца токена для loan-а
    function getActualTokenOwnerForLoan(
        address storageAddress, 
        uint256 loanId, 
        uint256 tokenId
    ) 
        public 
        view
        returns (address)
    {
        return SnarkStorage(storageAddress).addressStorage(
            keccak256(abi.encodePacked("actualTokenOwnerForLoan", loanId, tokenId))
        );
    }

    /// @notice сохраняем адрес текущего владельца токена для loan-а
    function setActualTokenOwnerForLoan(
        address storageAddress, 
        uint256 loanId, 
        uint256 tokenId, 
        address tokenOwner
    ) 
        public 
    {
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("actualTokenOwnerForLoan", loanId, tokenId)),
            tokenOwner
        );
    }

    /// @notice возвращает предложенную сумму за кредит всех токенов, входящих в лоан
    function getPriceOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("priceOfLoan", loanId)));
    }

    /// @notice сохраняет предложенную сумму за кредит всех токенов, входящих в лоан
    function setPriceOfLoan(address storageAddress, uint256 loanId, uint256 price) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("priceOfLoan", loanId)), price);
    }

    /// @notice добавляет loan в список laon-ов пользователя
    function addLoanToLoanListOfLoanOwner(address storageAddress, address loanOwner, uint256 loanId) public {
        uint256 index = increaseCountOfLoansForLoanOwner(storageAddress, loanOwner).sub(1);
        setLoanToLoanListOfLoanOwnerByIndex(storageAddress, loanOwner, index, loanId);
        saveIndexOfLoanInLoanListOfLoanOwner(storageAddress, loanOwner, loanId, index);
    }

    /// @notice удаляет лоан из списка лоанов пользователя
    function deleteLoanFromLoanListOfLoanOwner(address storageAddress, address loanOwner, uint256 loanId) public {
        uint256 index = getIndexOfLoanInLoanListOfLoanOwner(storageAddress, loanOwner, loanId);
        uint256 maxIndex = getCountOfLoansForLoanOwner(storageAddress, loanOwner).sub(1);
        if (index < maxIndex) {
            uint256 lastLoan = getLoanFromLoanListOfLoanOwnerByIndex(storageAddress, loanOwner, maxIndex);
            setLoanToLoanListOfLoanOwnerByIndex(storageAddress, loanOwner, index, lastLoan);
        }
        setLoanToLoanListOfLoanOwnerByIndex(storageAddress, loanOwner, maxIndex, 0);
        decreaseCountOfLoansForLoanOwner(storageAddress, loanOwner);
    }

    /// @notice возвращает лоан из списка лоанов пользователя по индексу
    function getLoanFromLoanListOfLoanOwnerByIndex(
        address storageAddress,
        address loanOwner,
        uint256 index
    )
        public
        view 
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("loansListOfLoanOwner", loanOwner, index))
        );
    }

    /// @notice записывает лоан в список пользователя на определенную позицию
    function setLoanToLoanListOfLoanOwnerByIndex(
        address storageAddress,
        address loanOwner,
        uint256 index,
        uint256 loanId
    )
        public
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("loansListOfLoanOwner", loanOwner, index)),
            loanId
        );
    }

    /// @notice возвращает индекс лоана в списке пользователя
    function getIndexOfLoanInLoanListOfLoanOwner(
        address storageAddress, 
        address loanOwner, 
        uint256 loanId
    )
        public
        view
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("loanIndexInLoanListOfLoanOwner", loanOwner, loanId))
        );
    }

    /// @notice записывает индекс лоана в списке пользователя
    function saveIndexOfLoanInLoanListOfLoanOwner(
        address storageAddress, 
        address loanOwner, 
        uint256 loanId, 
        uint256 index
    )
        public
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("loanIndexInLoanListOfLoanOwner", loanOwner, loanId)),
            index
        );
    }

    /// @notice увеличивает счетчик количества loan-ов в списке пользователя
    function increaseCountOfLoansForLoanOwner(address storageAddress, address loanOwner) public returns (uint256) {
        uint256 count = getCountOfLoansForLoanOwner(storageAddress, loanOwner).add(1);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("LoansNumberOfLoanOwner", loanOwner)),
            count
        );
        return count;
    }

    /// @notice уменьшает счетчик количества лоанов в списке пользователя
    function decreaseCountOfLoansForLoanOwner(address storageAddress, address loanOwner) public returns (uint256) {
        uint256 count = getCountOfLoansForLoanOwner(storageAddress, loanOwner).sub(1);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("LoansNumberOfLoanOwner", loanOwner)),
            count
        );
        return count;
    }

    /// @notice возвращает количество лоанов у пользователя в списке
    function getCountOfLoansForLoanOwner(address storageAddress, address loanOwner) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("LoansNumberOfLoanOwner", loanOwner))
        );
    }

    /// @notice возвращает список лоанов пользователя
    function getLoansListOfLoanOwner(address storageAddress, address loanOwner) public view returns (uint256[]) {
        uint256 countLoans = getCountOfLoansForLoanOwner(storageAddress, loanOwner);
        uint256[] memory list = new uint256[](countLoans);
        for (uint256 i = 0; i < countLoans; i++) {
            list[i] = getLoanFromLoanListOfLoanOwnerByIndex(storageAddress, loanOwner, i);
        }
        return list;
    }

    /// @notice возвращает стоимость операции вызова StopLoan
    function getCostOfStopLoanOperationForLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("costOfDeleteLoanOperation", loanId))
        );
    }

    /// @notice записываем стоимость вызова функции StopLoan
    function setCostOfStopLoanOperationForLoan(address storageAddress, uint256 loanId, uint256 cost) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("costOfDeleteLoanOperation", loanId)),
            cost
        );
    }

    /*************************************************************************************/
    /// @notice добавляет лоан в список лоанов для токена
    function addLoanToTokensLoanList(address storageAddress, uint256 tokenId, uint256 loanId) public {
        if (!isLoanInTokensLoanList(storageAddress, tokenId, loanId)) {
            uint256 index = increaseNumberOfLoansInTokensLoanList(storageAddress, tokenId).sub(1);
            setLoanFromLoansInTokensLoanListByIndex(storageAddress, tokenId, index, loanId);
            setIndexOfLoanInTokensLoanList(storageAddress, tokenId, loanId, index);
            markLoanInTokensLoanListAsInUse(storageAddress, tokenId, loanId, true);
        }
    }

    /// @notice удаляет лоан из списка лоанов для токена
    function removeLoanFromTokensLoanList(address storageAddress, uint256 tokenId, uint256 loanId) public {
        if (isLoanInTokensLoanList(storageAddress, tokenId, loanId)) {
            uint256 index = getIndexOfLoanInTokensLoanList(storageAddress, tokenId, loanId);
            uint256 maxIndex = getNumberOfLoansInTokensLoanList(storageAddress, tokenId).sub(1);
            if (index < maxIndex) {
                uint256 loanIdInMaxIndex = getLoanFromLoansInTokensLoanListByIndex(storageAddress, tokenId, maxIndex);
                setLoanFromLoansInTokensLoanListByIndex(storageAddress, tokenId, index, loanIdInMaxIndex);
            }
            setLoanFromLoansInTokensLoanListByIndex(storageAddress, tokenId, index, 0);
            setIndexOfLoanInTokensLoanList(storageAddress, tokenId, loanId, 0);
            markLoanInTokensLoanListAsInUse(storageAddress, tokenId, loanId, false);
            decreaseNumberOfLoansInTokensLoanList(storageAddress, tokenId);
        }
    }
    
    /// @notice возвращает количество лоанов для токена
    function getNumberOfLoansInTokensLoanList(address storageAddress, uint256 tokenId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfLoansForToken", tokenId))
        );
    }

    /// @notice увеличивает счетчик количества лоанов в списке
    function increaseNumberOfLoansInTokensLoanList(address storageAddress, uint256 tokenId) public returns (uint256) {
        uint256 number = getNumberOfLoansInTokensLoanList(storageAddress, tokenId).add(1);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfLoansForToken", tokenId)),
            number
        );
        return number;
    }

    /// @notice уменьшает счетчик количества лоанов в списке
    function decreaseNumberOfLoansInTokensLoanList(address storageAddress, uint256 tokenId) public returns (uint256) {
        uint256 number = getNumberOfLoansInTokensLoanList(storageAddress, tokenId).sub(1);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfLoansForToken", tokenId)),
            number
        );
        return number;
    }

    /// @notice возвращает лоан из списка по индексу
    function getLoanFromLoansInTokensLoanListByIndex(address storageAddress, uint256 tokenId, uint256 index) 
        public 
        view 
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("loanListForToken", tokenId, index))
        );
    }

    /// @notice записывает лоан в список по индексу
    function setLoanFromLoansInTokensLoanListByIndex(
        address storageAddress, 
        uint256 tokenId, 
        uint256 index, 
        uint256 loanId
    )
        public 
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("loanListForToken", tokenId, index)),
            loanId
        );
    }

    /// @notice возвращает список лоанов из списка для токена
    function getListOfLoansFromTokensLoanList(address storageAddress, uint256 tokenId) public view returns (uint256[]) {
        uint256 numberOfLoans = getNumberOfLoansInTokensLoanList(storageAddress, tokenId);
        uint256[] memory loanList = new uint256[](numberOfLoans);
        for (uint256 i = 0; i < numberOfLoans; i++) {
            loanList[i] = getLoanFromLoansInTokensLoanListByIndex(storageAddress, tokenId, i);
        }
        return loanList;
    }

    /// @notice возвращает true или false в зависимости от того, есть ли loan в списке у токена
    function isLoanInTokensLoanList(address storageAddress, uint256 tokenId, uint256 loanId)
        public
        view
        returns (bool)
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("isLoanInTokensLoanList", tokenId, loanId))
        );
    }

    /// @notice помечает, что лоан уже есть в списке у токена
    function markLoanInTokensLoanListAsInUse(address storageAddress, uint256 tokenId, uint256 loanId, bool isUsed) 
        public 
    {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("isLoanInTokensLoanList", tokenId, loanId)),
            isUsed
        );
    }

    /// @notice возвращает индекс лоана в списке у токена
    function getIndexOfLoanInTokensLoanList(address storageAddress, uint256 tokenId, uint256 loanId)
        public
        view
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("indexOfLoanInTokensLoanList", tokenId, loanId))
        );
    }

    /// @notice записывает индекс под которым хранится лоан в списке у токена
    function setIndexOfLoanInTokensLoanList(address storageAddress, uint256 tokenId, uint256 loanId, uint256 index)
        public 
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("indexOfLoanInTokensLoanList", tokenId, loanId)),
            index
        );
    }

    /// @notice удаление токена из лоана. возможно выполнение только до момента старта лоана
    function cancelTokenInLoan(address storageAddress, uint256 tokenId) public {
        uint256[] memory loanList = getListOfLoansFromTokensLoanList(storageAddress, tokenId);
        for (uint256 i = 0; i < loanList.length; i++) {
            // убеждаемся, что удалять будем только в будущих лоанах
            require(
                getLoanSaleStatus(storageAddress, loanList[i]) != 2 &&
                getLoanSaleStatus(storageAddress, loanList[i]) != 3,
                "Loan can't be in 'Active' of 'Finished' status"
            );
            // перемещаем токен из Approved list в Declined list
            addTokenToListOfLoan(storageAddress, loanList[i], tokenId, 2);
            // удаляем из календаря токенов запланированные дни
            uint256 startDate = getStartDateOfLoan(storageAddress, loanList[i]);
            uint256 duration = getDurationOfLoan(storageAddress, loanList[i]);
            makeTokenFreeForPeriod(storageAddress, tokenId, startDate, duration);
            // удаляем из запросов к владельцам токенов
            deleteLoanRequestFromTokenOwner(storageAddress, loanList[i], tokenId);
        }
        if (loanList.length > 0) {
            emit TokenCanceledInLoans(tokenId, loanList);
        }
    }

}
