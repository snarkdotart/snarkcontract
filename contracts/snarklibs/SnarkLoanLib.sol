pragma solidity ^0.4.25;

import "../openzeppelin/SafeMath.sol";
import "../SnarkStorage.sol";
import "./SnarkBaseLib.sol";


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
            addLoanToTokensLoanList(storageAddress, tokensIds[index], loanId);
        }
        setStartDateOfLoan(storageAddress, loanId, startDate);
        setDurationOfLoan(storageAddress, loanId, duration);
        setLoanSaleStatus(storageAddress, loanId, 0); // 0 - Prepairing

        return loanId;
    }

    /// @notice increase the number of loans in the system 
    function increaseNumberOfLoans(address storageAddress) public returns (uint256) {
        uint256 totalNumber = getTotalNumberOfLoans(storageAddress).add(1);
        SnarkStorage(storageAddress).setUint(keccak256("totalNumberOfLoans"), totalNumber);
        return totalNumber;
    }

    /// @notice returns total number of loans in the system 
    function getTotalNumberOfLoans(address storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfLoans"));
    }

    /// @notice returns loan owner 
    function getOwnerOfLoan(address storageAddress, uint256 loanId) public view returns (address) {
        return SnarkStorage(storageAddress).addressStorage(keccak256(abi.encodePacked("loanOwner", loanId)));
    }

    /// @notice sets the loan owner
    function setOwnerOfLoan(address storageAddress, address loanOwner, uint256 loanId) public {
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("loanOwner", loanId)),
            loanOwner
        );
    }

    /// @notice Adds token to the list of a specific type 
    function addTokenToListOfLoan(address storageAddress, uint256 loanId, uint256 tokenId, uint256 listType) public {
        // check if the token was included in the loan previously or if it is the first time 
        if (isTokenIncludedInLoan(storageAddress, loanId, tokenId)) {
            // if it is not the first time, it means that the token transfer is happening from one list to another 
            // and that means that it needs to be removed from the previous list 
            // but before this is done we need to check if we are trying to move the token into the same list
            // in which it is already located. If yes, create exception, or we risk duplicating the token in the list.
            require(
                getTypeOfTokenListForLoan(storageAddress, loanId, tokenId) != listType, 
                "Token already belongs to selected type"
            );
            removeTokenFromListOfLoan(storageAddress, loanId, tokenId);
        } else {
            // if token addition is happing for the first time, mark it as added to the loan
            setTokenAsIncludedInLoan(storageAddress, loanId, tokenId, true);
        }
        // set the list type in which we added token
        setTypeOfTokenListForLoan(storageAddress, loanId, tokenId, listType);
        // add token to the end of the list 
        uint256 index = increaseNumberOfTokensInListByType(storageAddress, loanId, listType).sub(1);
        setTokenForLoanListByTypeAndIndex(storageAddress, loanId, listType, index, tokenId);
    }

    /// @notice remove token form the list in which it existed prior to calling this function 
    function removeTokenFromListOfLoan(address storageAddress, uint256 loanId, uint256 tokenId) public {
        // receive list type in which the token exists 
        uint256 listType = getTypeOfTokenListForLoan(storageAddress, loanId, tokenId);
        // remove token index from the token list
        uint256 indexOfToken = getTokenIndexInListOfLoanByType(storageAddress, loanId, tokenId);
        uint256 maxIndex = getNumberOfTokensInListByType(storageAddress, loanId, listType).sub(1);
        if (indexOfToken < maxIndex) {
            uint256 tokenIdOnLastIndex = getTokenForLoanListByTypeAndIndex(storageAddress, loanId, listType, maxIndex);
            setTokenForLoanListByTypeAndIndex(storageAddress, loanId, listType, indexOfToken, tokenIdOnLastIndex);
        }
        decreaseNumberOfTokensInListByType(storageAddress, loanId, listType);
    }

    /// @notice check is the token is participating in a loan or not 
    function isTokenIncludedInLoan(address storageAddress, uint256 loanId, uint256 tokenId)
        public 
        view 
        returns (bool)
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("isTokenIncludedInLoan", loanId, tokenId))
        );
    }

    /// @notice set that the token is participating in the selected loan 
    function setTokenAsIncludedInLoan(address storageAddress, uint256 loanId, uint256 tokenId, bool isIncluded) 
        public 
    {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("isTokenIncludedInLoan", loanId, tokenId)),
            isIncluded
        );
    }

    /// @notice return the list type the token belongs to
    function getTypeOfTokenListForLoan(address storageAddress, uint256 loanId, uint256 tokenId) 
        public 
        view 
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("typeOfTokenListForLoan", loanId, tokenId))
        );
    }

    /// @notice set to which list type the token belongs to 
    function setTypeOfTokenListForLoan(address storageAddress, uint256 loanId, uint256 tokenId, uint256 listType) 
        public
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("typeOfTokenListForLoan", loanId, tokenId)),
            listType
        );
    }

    /// @notice returns the number of tokens in the specific list
    function getNumberOfTokensInListByType(address storageAddress, uint256 loanId, uint256 listType) 
        public 
        view 
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfTokensInListByType", loanId, listType))
        );
    }

    /// @notice increase the number of tokens in the specific list
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

    /// @notice decrease the number of tokens in the specific list 
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

    /// @notice receive token id from the list of specific type in a specific index
    function getTokenForLoanListByTypeAndIndex(address storageAddress, uint256 loanId, uint256 listType, uint256 index) 
        public
        view
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokensListOfLoanByType", loanId, listType, index))
        );
    }

    /// @notice set token into the list of specific type and a specific index 
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

    /// @notice return tokens in a specific list (NotApproved, Approved, Declined)
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

    /// @notice return token index in the list, doesnt matter in which one since the token can only exist in only 1 of 3
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

    /// @notice set under which index the token is in the list
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

    /// @notice return date of the loan start 
    function getStartDateOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToStartDate", loanId)));
    }

    /// @notice set date of the loan start 
    function setStartDateOfLoan(address storageAddress, uint256 loanId, uint256 startDate) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToStartDate", loanId)), startDate);
    }

    /// @notice return loan duration 
    function getDurationOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToDuration", loanId)));
    }

    /// @notice set loan duration 
    function setDurationOfLoan(address storageAddress, uint256 loanId, uint256 duration) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToDuration", loanId)), duration);
    }

    /// @notice return loan status
    function getLoanSaleStatus(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToSaleStatus", loanId)));
    }

    /// @notice set loan status
    function setLoanSaleStatus(address storageAddress, uint256 loanId, uint256 saleStatus) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToSaleStatus", loanId)), saleStatus);
    }

    /// @notice return loan terms
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

    /// @notice check is there is a schedule conflict for a specific token and specific period request
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
        uint256 numberDays = startDate.div(86400000);
        for (uint256 i = 0; i < duration; i++) {
            if (isTokenBusyOnDay(storageAddress, tokenId, numberDays.add(i))) {
                isBusy = true;
                break;
            }
        }
        return isBusy;
    }

    /// @notice checks in the token calendar if it is busy on a specific date 
    function isTokenBusyOnDay(address storageAddress, uint256 tokenId, uint256 day) public view returns (bool) {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("tokenCalendar", tokenId, day))
        );
    }

    /// @notice returns loan id from the token calendar on a specific date 
    function getEventIdOnDayForToken(address storageAddress, uint256 tokenId, uint256 date) 
        public 
        view 
        returns (uint256) 
    {
        uint256 day = date.div(86400000);
        SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenCalendarDayToEventId", tokenId, day))
        );
    }

    /// @notice marks the busy period for the token 
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

    /// @notice marks that the token is busy on a specific date and by which loan 
    function makeTokenBusyOnDay(address storageAddress, uint256 loanId, uint256 tokenId, uint256 date) public {
        uint256 day = date.div(86400000);
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("tokenCalendar", tokenId, day)),
            true
        );
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("tokenCalendarDayToEventId", tokenId, day)),
            loanId
        );
    }

    /// @notice frees up the busy period for the token 
    function makeTokenFreeForPeriod(
        address storageAddress,
        uint256 tokenId,
        uint256 startDate,
        uint256 duration
    ) 
        public
    {
        uint256 busyDay = startDate.div(86400000);
        for (uint256 i = 0; i < duration; i++) {
            makeTokenFreeOnDay(storageAddress, tokenId, busyDay.add(i));
        }
    }

    /// @notice frees up in the calendar a specific token on a specific date 
    function makeTokenFreeOnDay(address storageAddress, uint256 tokenId, uint256 day) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("tokenCalendar", tokenId, day)),
            false
        );
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("tokenCalendarDayToEventId", tokenId, day)),
            0
        );
    }

    /// @notice returns maximum duration for which a token can be loaned  
    function getDefaultLoanDuration(address storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("defaultLoanDuration"));
    }

    /// @notice set maximum duration for which a token can be loaned  
    function setDefaultLoanDuration(address storageAddress, uint256 duration) public {
        SnarkStorage(storageAddress).setUint(keccak256("defaultLoanDuration"), duration);
    }

    /// @notice creates new loan request for the token to the token owner
    function addLoanRequestToTokenOwner(address storageAddress, address tokenOwner, uint256 tokenId, uint256 loanId)
        public 
    {
        uint256 index = increaseCountLoanRequestsForTokenOwner(storageAddress, tokenOwner).sub(1);
        setTokenForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, index, tokenId);
        setLoanForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, index, loanId);
        saveIndexOfLoanRequestForTokenOwnerByTokenAndLoan(storageAddress, tokenOwner, tokenId, loanId, index);
    }

    /// @notice sets the token into request list for the token owner and index 
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

    /// @notice sets loan into request list for token owners and index 
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

    /// @notice save loan request index for token owner 
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

    /// @notice returns loan request index for token owner by token id and loan id 
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

    /// @notice remove loan request from the list of token owner 
    function deleteLoanRequestFromTokenOwner(address storageAddress, uint256 loanId, uint256 tokenId) public {
        address tokenOwner = SnarkBaseLib.getOwnerOfToken(storageAddress, tokenId);
        uint256 index = getIndexOfLoanRequestForTokenOwnerByTokenAndLoan(storageAddress, tokenOwner, tokenId, loanId);
        uint256 maxIndex = getCountLoanRequestsForTokenOwner(storageAddress, tokenOwner).sub(1);
        require(index <= maxIndex, "!!! deleteLoanRequestFromTokenOwner: index exceeds maxIndex of Loan requests");
        if (index < maxIndex) {
            (uint256 maxIndexTokenId, uint256 maxIndexLoanId) = 
                getLoanRequestForTokenOwnerByIndex(storageAddress, tokenOwner, maxIndex);
            setTokenForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, index, maxIndexTokenId);
            setLoanForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, index, maxIndexLoanId);
            saveIndexOfLoanRequestForTokenOwnerByTokenAndLoan(
                storageAddress,
                tokenOwner,
                maxIndexTokenId,
                maxIndexLoanId,
                index
            );
        }
        setTokenForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, maxIndex, 0);
        setLoanForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, maxIndex, 0);
        decreaseCountLoanRequestsForTokenOwner(storageAddress, tokenOwner);
    }

    /// @notice Returns loan request information by index 
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

    /// @notice returns total loan requests for token owner 
    function getCountLoanRequestsForTokenOwner(address storageAddress, address tokenOwner)
        public
        view
        returns (uint256)
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("LoanRequestsCount", tokenOwner))
        );
    }

    /// @notice increases total loan requests for token owner 
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

    /// @notice decreases total loan requests for token owner 
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
    
    /// @notice returns the address of the current token owner for the loan
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

    /// @notice set the address of the current token owner for the loan 
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

    /// @notice return the offered loan amount for all tokens in the loan  
    function getPriceOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("priceOfLoan", loanId)));
    }

    /// @notice set the offered loan amount for all tokens in the loan  
    function setPriceOfLoan(address storageAddress, uint256 loanId, uint256 price) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("priceOfLoan", loanId)), price);
    }

    /// @notice add loan to the loan list of the loan owner 
    function addLoanToLoanListOfLoanOwner(address storageAddress, address loanOwner, uint256 loanId) public {
        uint256 index = increaseCountOfLoansForLoanOwner(storageAddress, loanOwner).sub(1);
        setLoanToLoanListOfLoanOwnerByIndex(storageAddress, loanOwner, index, loanId);
        saveIndexOfLoanInLoanListOfLoanOwner(storageAddress, loanOwner, loanId, index);
    }

    /// @notice remove loan from the loan list of the loan owner 
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

    /// @notice return loan from the list of loan owners by index 
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

    /// @notice sets loan into the list of loan owners for a specific position 
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

    /// @notice return loan index from the loan owner 
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

    /// @notice set loan index to the loan owner 
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

    /// @notice increase the number of loans in the loan owner list
    function increaseCountOfLoansForLoanOwner(address storageAddress, address loanOwner) public returns (uint256) {
        uint256 count = getCountOfLoansForLoanOwner(storageAddress, loanOwner).add(1);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("LoansNumberOfLoanOwner", loanOwner)),
            count
        );
        return count;
    }

    /// @notice decrease the number of loans in the loan owner list
    function decreaseCountOfLoansForLoanOwner(address storageAddress, address loanOwner) public returns (uint256) {
        uint256 count = getCountOfLoansForLoanOwner(storageAddress, loanOwner).sub(1);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("LoansNumberOfLoanOwner", loanOwner)),
            count
        );
        return count;
    }

    /// @notice return the number of loans in the loan owner list
    function getCountOfLoansForLoanOwner(address storageAddress, address loanOwner) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("LoansNumberOfLoanOwner", loanOwner))
        );
    }

    /// @notice return loan list of the loan owner  
    function getLoansListOfLoanOwner(address storageAddress, address loanOwner) public view returns (uint256[]) {
        uint256 countLoans = getCountOfLoansForLoanOwner(storageAddress, loanOwner);
        uint256[] memory list = new uint256[](countLoans);
        for (uint256 i = 0; i < countLoans; i++) {
            list[i] = getLoanFromLoanListOfLoanOwnerByIndex(storageAddress, loanOwner, i);
        }
        return list;
    }

    /// @notice return the cost of gas for the call of function StopLoan
    function getCostOfStopLoanOperationForLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("costOfDeleteLoanOperation", loanId))
        );
    }

    /// @notice set the cost of gas for the call of function StopLoan
    function setCostOfStopLoanOperationForLoan(address storageAddress, uint256 loanId, uint256 cost) public {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("costOfDeleteLoanOperation", loanId)),
            cost
        );
    }

    /*************************************************************************************/
    /// @notice add loan into the loan list of a token 
    function addLoanToTokensLoanList(address storageAddress, uint256 tokenId, uint256 loanId) public {
        if (!isLoanInTokensLoanList(storageAddress, tokenId, loanId)) {
            uint256 index = increaseNumberOfLoansInTokensLoanList(storageAddress, tokenId).sub(1);
            setLoanFromLoansInTokensLoanListByIndex(storageAddress, tokenId, index, loanId);
            setIndexOfLoanInTokensLoanList(storageAddress, tokenId, loanId, index);
            markLoanInTokensLoanListAsInUse(storageAddress, tokenId, loanId, true);
        }
    }

    /// @notice remove loan from the loan list of a token 
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
    
    /// @notice returns the number of loans for a token 
    function getNumberOfLoansInTokensLoanList(address storageAddress, uint256 tokenId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("numberOfLoansForToken", tokenId))
        );
    }

    /// @notice increases the number of loans for a token 
    function increaseNumberOfLoansInTokensLoanList(address storageAddress, uint256 tokenId) public returns (uint256) {
        uint256 number = getNumberOfLoansInTokensLoanList(storageAddress, tokenId).add(1);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfLoansForToken", tokenId)),
            number
        );
        return number;
    }

    /// @notice decrease the number of loans for a token 
    function decreaseNumberOfLoansInTokensLoanList(address storageAddress, uint256 tokenId) public returns (uint256) {
        uint256 number = getNumberOfLoansInTokensLoanList(storageAddress, tokenId).sub(1);
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("numberOfLoansForToken", tokenId)),
            number
        );
        return number;
    }

    /// @notice return the loan from the loan list by index 
    function getLoanFromLoansInTokensLoanListByIndex(address storageAddress, uint256 tokenId, uint256 index) 
        public 
        view 
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("loanListForToken", tokenId, index))
        );
    }

    /// @notice sets the loan into the loan list by index
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

    /// @notice returns the loan list from the token loan list 
    function getListOfLoansFromTokensLoanList(address storageAddress, uint256 tokenId) public view returns (uint256[]) {
        uint256 numberOfLoans = getNumberOfLoansInTokensLoanList(storageAddress, tokenId);
        uint256[] memory loanList = new uint256[](numberOfLoans);
        for (uint256 i = 0; i < numberOfLoans; i++) {
            loanList[i] = getLoanFromLoansInTokensLoanListByIndex(storageAddress, tokenId, i);
        }
        return loanList;
    }

    /// @notice returns true or false depending is the loan is in the token loan list 
    function isLoanInTokensLoanList(address storageAddress, uint256 tokenId, uint256 loanId)
        public
        view
        returns (bool)
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("isLoanInTokensLoanList", tokenId, loanId))
        );
    }

    /// @notice sets that the loan is in the token loan list 
    function markLoanInTokensLoanListAsInUse(address storageAddress, uint256 tokenId, uint256 loanId, bool isUsed) 
        public 
    {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("isLoanInTokensLoanList", tokenId, loanId)),
            isUsed
        );
    }

    /// @notice returns loan index from the token loan list 
    function getIndexOfLoanInTokensLoanList(address storageAddress, uint256 tokenId, uint256 loanId)
        public
        view
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("indexOfLoanInTokensLoanList", tokenId, loanId))
        );
    }

    /// @notice sets the loan index into the token loan list 
    function setIndexOfLoanInTokensLoanList(address storageAddress, uint256 tokenId, uint256 loanId, uint256 index)
        public 
    {
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("indexOfLoanInTokensLoanList", tokenId, loanId)),
            index
        );
    }

    /// @notice removal of token from loan.  possible only prior to loan start.
    function cancelTokenInLoan(address storageAddress, uint256 tokenId) public {
        uint256[] memory loanList = getListOfLoansFromTokensLoanList(storageAddress, tokenId);
        for (uint256 i = 0; i < loanList.length; i++) {
            // check that the removal is not for loans with Finished status
            require(
                getLoanSaleStatus(storageAddress, loanList[i]) != 3,
                "Loan can't be in 'Finished' status"
            );
            // transfer token from Approved list into Declined list
            addTokenToListOfLoan(storageAddress, loanList[i], tokenId, 2);
            // remove from the token calendar the booked days 
            uint256 startDate = getStartDateOfLoan(storageAddress, loanList[i]);
            uint256 duration = getDurationOfLoan(storageAddress, loanList[i]);
            makeTokenFreeForPeriod(storageAddress, tokenId, startDate, duration);
            // remove loan request from the token owners 
            deleteLoanRequestFromTokenOwner(storageAddress, loanList[i], tokenId);
            removeLoanFromTokensLoanList(storageAddress, tokenId, loanList[i]);
            removeTokenFromListOfLoan(storageAddress, loanList[i], tokenId);

        }
        if (loanList.length > 0) {
            emit TokenCanceledInLoans(tokenId, loanList);
        }
    }

}
