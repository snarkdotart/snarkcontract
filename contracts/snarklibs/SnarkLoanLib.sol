pragma solidity ^0.4.24;

import "../openzeppelin/SafeMath.sol";
import "../SnarkStorage.sol";


library SnarkLoanLib {

    using SafeMath for uint256;

    function createLoan(
        address storageAddress, 
        uint256[] tokensIds,
        uint256 startDate,
        uint256 duration,
        address destinationWallet
    )
        public
        returns (uint256)
    {
        uint256 loanId = increaseNumberOfLoans(storageAddress);
        for (uint256 index = 0; index < tokensIds.length; index++) {
            // Type of List: 0 - NotApproved, 1 - Approved, 2 - Declined
            addTokenToListOfLoan(storageAddress, loanId, tokensIds[index], 0); // 0 - NotApproved
            // FIXME: setLoanToToken - не будет работать, т.к. токен может принадлежать нескольким лоанам
            // можно создавать список лоанов для токена, в которых он участвует
            // возможно это делать совместно с расписанием, т.е. если добавили в расписание, 
            // то и отметили тогда, в каком лоане он задействован. Иначе - не участвует, т.е. принимать 
            // только тогда, когда токен лежит в Approved List.
            // setLoanToToken(storageAddress, tokensIds[index], loanId);
        }
        // FIXME: setTotalPriceOfLoan - на этом этапе не задаем. Будем ли задавать вообще - не понятно
        // setTotalPriceOfLoan(storageAddress, loanId, commonPrice);
        setStartDateOfLoan(storageAddress, loanId, startDate);
        setDurationOfLoan(storageAddress, loanId, duration);
        setDestinationWalletOfLoan(storageAddress, loanId, destinationWallet);
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

    /// @notice возвращает кошелек арендатора, куда будут переведены токены
    function getDestinationWalletOfLoan(address storageAddress, uint256 loanId) public view returns (address) {
        return SnarkStorage(storageAddress).addressStorage(
            keccak256(abi.encodePacked("loanToDestinationWallet", loanId))
        );
    }

    /// @notice утанавливает кошелек арендатора, на который будут переведены токены
    function setDestinationWalletOfLoan(address storageAddress, uint256 loanId, address destinationWallet) public {
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("loanToDestinationWallet", loanId)), 
            destinationWallet
        );
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
    function getLoanDetails(address storageAddress, uint256 loanId)
        public 
        view 
        returns 
    (
        uint256 amountOfNonApprovedTokens,
        uint256 amountOfApprovedTokens,
        uint256 amountOfDeclinedTokens,
        // uint256 price,
        uint256 startDate,
        uint256 duration,
        uint256 saleStatus,
        address destinationWallet)
    {
        amountOfNonApprovedTokens = getNumberOfTokensInListByType(storageAddress, loanId, 0);
        amountOfApprovedTokens = getNumberOfTokensInListByType(storageAddress, loanId, 1);
        amountOfDeclinedTokens = getNumberOfTokensInListByType(storageAddress, loanId, 2);
        // price = getTotalPriceOfLoan(storageAddress, loanId);
        startDate = getStartDateOfLoan(storageAddress, loanId);
        duration = getDurationOfLoan(storageAddress, loanId);
        saleStatus = getLoanSaleStatus(storageAddress, loanId);
        destinationWallet = getDestinationWalletOfLoan(storageAddress, loanId);
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

    /// @notice токен может принадлежать нескольким лоанам одновременно!!!!
    // function getLoanToToken(address storageAddress, uint256 tokenId) public view returns (uint256) {
    //     return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToToken", tokenId)));
    // }

    // function setLoanToToken(address storageAddress, uint256 tokenId, uint256 loanId) public {
    //     SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToToken", tokenId)), loanId);
    // }

    // function deleteLoanToToken(address storageAddress, uint256 tokenId) public {
    //     SnarkStorage(storageAddress).deleteUint(keccak256(abi.encodePacked("loanToToken", tokenId)));
    // }

    // function deleteTokenFromListOfLoan(address storageAddress, uint256 loanId, uint256 tokenId) public {
    //     uint256 totalNumber = getTotalNumberOfLoanTokens(storageAddress, loanId);
    //     uint256 lastTokenId = getTokenFromLoanList(storageAddress, loanId, totalNumber - 1);
    //     uint256 indexOfToken = getTokenIndexInsideListOfLoan(storageAddress, loanId, tokenId);

    //     if (indexOfToken < totalNumber - 1) {

    //         SnarkStorage(storageAddress).setUint(
    //             keccak256(abi.encodePacked("tokenToLoanList", loanId, indexOfToken)),
    //             lastTokenId
    //         );

    //         // save index of token in the list
    //         setTokenIndexInsideListOfLoan(storageAddress, loanId, lastTokenId, indexOfToken);

    //         SnarkStorage(storageAddress).deleteUint(
    //             keccak256(abi.encodePacked("tokenToLoanList", loanId, totalNumber - 1))
    //         );
    //     }
        
    //     SnarkStorage(storageAddress).setUint(
    //         keccak256(abi.encodePacked("totalNumberOfLoanTokens", loanId)), 
    //         totalNumber - 1
    //     );

    //     deleteTokenIndexInsideListOfLoan(storageAddress, loanId, tokenId);
    // }

    // function deleteTokenIndexInsideListOfLoan(address storageAddress, uint256 loanId, uint256 tokenId) public {
    //     SnarkStorage(storageAddress).deleteUint(
    //         keccak256(abi.encodePacked("tokenIndexInsideListOfLoan", loanId, tokenId))
    //     );
    // }

    
    // function setTotalPriceOfLoan(address storageAddress, uint256 loanId, uint256 price) public {
    //     SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("priceOfLoan", loanId)), price);
    // }


    // function acceptTokenForLoan(address storageAddress, uint256 loanId, uint256 tokenId) public {
    //     SnarkStorage(storageAddress).setBool(
    //         keccak256(abi.encodePacked("tokenAcceptedForLoan", loanId, tokenId)), 
    //         true
    //     );
    // }

    // function declineTokenForLoan(address storageAddress, uint256 loanId, uint256 tokenId) public {
    //     SnarkStorage(storageAddress).setBool(
    //         keccak256(abi.encodePacked("tokenAcceptedForLoan", loanId, tokenId)), 
    //         false
    //     );
    // }

    // function setCurrentTokenOwnerForLoan(
    //     address storageAddress, 
    //     uint256 loanId, 
    //     uint256 tokenId, 
    //     address tokenOwner
    // ) 
    //     public 
    // {
    //     SnarkStorage(storageAddress).setAddress(
    //         keccak256(abi.encodePacked("currentTokenOwnerForLoan", loanId, tokenId)),
    //         tokenOwner
    //     );
    // }


    // function getTokenIndexInsideListOfLoan(address storageAddress, uint256 loanId, uint256 tokenId)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return SnarkStorage(storageAddress).uintStorage(
    //         keccak256(abi.encodePacked("tokenIndexInsideListOfLoan", loanId, tokenId))
    //     );
    // }

    // function getTokenFromLoanList(address storageAddress, uint256 loanId, uint256 index) 
    //     public 
    //     view 
    //     returns (uint256) 
    // {
    //     return SnarkStorage(storageAddress).uintStorage(
    //         keccak256(abi.encodePacked("tokenToLoanList", loanId, index))
    //     );
    // }

    // function getLoanByToken(address storageAddress, uint256 tokenId) public view returns (uint256) {
    //     return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToToken", tokenId)));
    // }

    // function getTotalPriceOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
    //     return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("priceOfLoan", loanId)));
    // }

    // function isTokenAcceptedForLoan(address storageAddress, uint256 loanId, uint256 tokenId) 
    //     public 
    //     view 
    //     returns (bool) 
    // {
    //     return SnarkStorage(storageAddress).boolStorage(
    //         keccak256(abi.encodePacked("tokenAcceptedForLoan", loanId, tokenId))
    //     );
    // }

    // function getCurrentTokenOwnerForLoan(
    //     address storageAddress, 
    //     uint256 loanId, 
    //     uint256 tokenId
    // ) 
    //     public 
    //     view
    //     returns (address)
    // {
    //     return SnarkStorage(storageAddress).addressStorage(
    //         keccak256(abi.encodePacked("currentTokenOwnerForLoan", loanId, tokenId))
    //     );
    // }


}
