pragma solidity >=0.5.4;

import "../openzeppelin/SafeMath.sol";
import "../SnarkStorage.sol";
import "./SnarkBaseLib.sol";
import "./SnarkLoanLibExt.sol";


/// @author Vitali Hurski
library SnarkLoanLib {

    using SafeMath for uint256;
    
    event TokenCanceledInLoans(uint256 tokenId, uint256 loanId);

    function createEmptyLoan(
        address storageAddress, 
        address loanOwner,
        uint256[3] memory loanPriceStartDateDuration
    ) 
        public
        returns (uint256)
    {
        uint256 loanPrice = loanPriceStartDateDuration[0];
        uint256 startDate = loanPriceStartDateDuration[1];
        uint256 duration = loanPriceStartDateDuration[2];
        uint256 loanId = SnarkLoanLibExt.increaseNumberOfLoans(storageAddress);
        SnarkLoanLibExt.setOwnerOfLoan(storageAddress, loanOwner, loanId);
        setPriceOfLoan(storageAddress, loanId, loanPrice);
        addLoanToLoanListOfLoanOwner(storageAddress, loanOwner, loanId);
        SnarkLoanLibExt.setStartDateOfLoan(storageAddress, loanId, startDate);
        SnarkLoanLibExt.setDurationOfLoan(storageAddress, loanId, duration);
        SnarkLoanLibExt.setLoanSaleStatus(storageAddress, loanId, 0);
        return loanId;
    }

    function attachTokenToLoan(address storageAddress, uint256 loanId, uint256 tokenId, uint256 typeOfList) public {
        // Type of List: 0 - NotApproved, 1 - Approved, 2 - Declined
        addTokenToListOfLoan(storageAddress, loanId, tokenId, typeOfList);
        addLoanToTokensLoanList(storageAddress, tokenId, loanId);
    }

    function createLoan(
        address storageAddress, 
        address loanOwner,
        uint256 loanPrice,
        uint256[] memory tokensIds,
        uint256 startDate,
        uint256 duration
    )
        public
        returns (uint256)
    {
        uint256 loanId = SnarkLoanLibExt.increaseNumberOfLoans(storageAddress);
        SnarkLoanLibExt.setOwnerOfLoan(storageAddress, loanOwner, loanId);
        setPriceOfLoan(storageAddress, loanId, loanPrice);
        addLoanToLoanListOfLoanOwner(storageAddress, loanOwner, loanId);
        for (uint256 index = 0; index < tokensIds.length; index++) {
            // Type of List: 0 - NotApproved, 1 - Approved, 2 - Declined
            addTokenToListOfLoan(storageAddress, loanId, tokensIds[index], 0); // 0 - NotApproved
            addLoanToTokensLoanList(storageAddress, tokensIds[index], loanId);
        }
        SnarkLoanLibExt.setStartDateOfLoan(storageAddress, loanId, startDate);
        SnarkLoanLibExt.setDurationOfLoan(storageAddress, loanId, duration);
        SnarkLoanLibExt.setLoanSaleStatus(storageAddress, loanId, 0); // 0 - Prepairing

        return loanId;
    }

    /// @notice Adds token to the list of a specific type 
    function addTokenToListOfLoan(address storageAddress, uint256 loanId, uint256 tokenId, uint256 listType) public {
        // check if the token was included in the loan previously or if it is the first time 
        if (SnarkLoanLibExt.isTokenIncludedInLoan(storageAddress, loanId, tokenId)) {
            // if it is not the first time, it means that the token transfer is happening from one list to another 
            // and that means that it needs to be removed from the previous list 
            // but before this is done we need to check if we are trying to move the token into the same list
            // in which it is already located. If yes, create exception, or we risk duplicating the token in the list.
            require(
                SnarkLoanLibExt.getTypeOfTokenListForLoan(storageAddress, loanId, tokenId) != listType, 
                "Token already belongs to selected type"
            );
            removeTokenFromListOfLoan(storageAddress, loanId, tokenId);
        } else {
            // if token addition is happing for the first time, mark it as added to the loan
            SnarkLoanLibExt.setTokenAsIncludedInLoan(storageAddress, loanId, tokenId, true);
        }
        // set the list type in which we added token
        SnarkLoanLibExt.setTypeOfTokenListForLoan(storageAddress, loanId, tokenId, listType);
        // add token to the end of the list 
        uint256 index = SnarkLoanLibExt.increaseNumberOfTokensInListByType(storageAddress, loanId, listType).sub(1);
        SnarkLoanLibExt.setTokenForLoanListByTypeAndIndex(storageAddress, loanId, listType, index, tokenId);
    }

    /// @notice remove token form the list in which it existed prior to calling this function 
    function removeTokenFromListOfLoan(address storageAddress, uint256 loanId, uint256 tokenId) public {
        if (SnarkLoanLibExt.isTokenIncludedInLoan(storageAddress, loanId, tokenId)) {
            // receive list type in which the token exists 
            uint256 listType = SnarkLoanLibExt.getTypeOfTokenListForLoan(storageAddress, loanId, tokenId);
            // remove token index from the token list
            uint256 indexOfToken = SnarkLoanLibExt.getTokenIndexInListOfLoanByType(storageAddress, loanId, tokenId);
            uint256 maxIndex = SnarkLoanLibExt.getNumberOfTokensInListByType(storageAddress, loanId, listType);
            if (maxIndex > 0) {
                maxIndex = maxIndex.sub(1);
                if (indexOfToken < maxIndex) {
                    uint256 tokenIdOnLastIndex = 
                        SnarkLoanLibExt.getTokenForLoanListByTypeAndIndex(storageAddress, loanId, listType, maxIndex);
                    SnarkLoanLibExt.setTokenForLoanListByTypeAndIndex(storageAddress, 
                        loanId, listType, indexOfToken, tokenIdOnLastIndex);
                }
                SnarkLoanLibExt.decreaseNumberOfTokensInListByType(storageAddress, loanId, listType);
            }
        }
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
        amountOfNonApprovedTokens = SnarkLoanLibExt.getNumberOfTokensInListByType(storageAddress, loanId, 0);
        amountOfApprovedTokens = SnarkLoanLibExt.getNumberOfTokensInListByType(storageAddress, loanId, 1);
        amountOfDeclinedTokens = SnarkLoanLibExt.getNumberOfTokensInListByType(storageAddress, loanId, 2);
        startDate = SnarkLoanLibExt.getStartDateOfLoan(storageAddress, loanId);
        duration = SnarkLoanLibExt.getDurationOfLoan(storageAddress, loanId);
        saleStatus = SnarkLoanLibExt.getLoanSaleStatus(storageAddress, loanId);
        loanPrice = getPriceOfLoan(storageAddress, loanId);
        loanOwner = SnarkLoanLibExt.getOwnerOfLoan(storageAddress, loanId);
    }

    /// @notice check is there is a schedule conflict for a specific token and specific period request
    function isTokenBusyForPeriod(
        address storageAddress, 
        uint256[3] memory tokenIdStartDateDuration 
    ) 
        public 
        view 
        returns (bool) 
    {
        uint256 tokenId = tokenIdStartDateDuration[0];
        uint256 startDate = tokenIdStartDateDuration[1];
        uint256 duration = tokenIdStartDateDuration[2];
        bool isBusy = false;
        uint256 numberDays = startDate.div(86400000);
        for (uint256 i = 0; i < duration; i++) {
            if (SnarkLoanLibExt.isTokenBusyOnDay(storageAddress, tokenId, numberDays.add(i))) {
                isBusy = true;
                break;
            }
        }
        return isBusy;
    }

    /// @notice marks the busy period for the token 
    function makeTokenBusyForPeriod(
        address storageAddress, 
        uint256 loanId, 
        uint256[3] memory tokenIdStartDateDuration
    ) 
        public 
    {
        uint256 tokenId = tokenIdStartDateDuration[0];
        uint256 startDate = tokenIdStartDateDuration[1];
        uint256 duration = tokenIdStartDateDuration[2];
        uint256 busyDay;
        for (uint256 i = 0; i < duration; i++) {
            busyDay = startDate + 86400000 * i;
            SnarkLoanLibExt.makeTokenBusyOnDay(storageAddress, loanId, tokenId, busyDay);
        }
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
            SnarkLoanLibExt.makeTokenFreeOnDay(storageAddress, tokenId, busyDay.add(i));
        }
    }

    // /// @notice returns total number of loans in the system 
    // function getTotalNumberOfLoans(address storageAddress) public view returns (uint256) {
    //     return SnarkLoanLibExt.getTotalNumberOfLoans(storageAddress);
    // }
    /// @notice creates new loan request for the token to the token owner
    function addLoanRequestToTokenOwner(address storageAddress, address tokenOwner, uint256 tokenId, uint256 loanId)
        public 
    {
        uint256 index = increaseCountLoanRequestsForTokenOwner(storageAddress, tokenOwner).sub(1);
        SnarkLoanLibExt.setTokenForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, index, tokenId);
        SnarkLoanLibExt.setLoanForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, index, loanId);
        SnarkLoanLibExt.saveIndexOfLoanRequestForTokenOwnerByTokenAndLoan(
            storageAddress, tokenOwner, tokenId, loanId, index);
        setExistingLoanRequestForTokenOwner(storageAddress, tokenOwner, tokenId, loanId, true);
    }

    function setExistingLoanRequestForTokenOwner(
        address storageAddress, 
        address tokenOwner, 
        uint256 tokenId, 
        uint256 loanId, 
        bool isExist
    )
        public
    {
        SnarkStorage(address(uint160(storageAddress))).setBool(
            keccak256(abi.encodePacked("SignOfExistingLoanRequestForTokenOwner", tokenOwner, tokenId, loanId)),
            isExist
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
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(
            keccak256(abi.encodePacked("IndexOfLoanRequestForTokenOwner", tokenOwner, tokenId, loanId))
        );
    }

    /// @notice remove loan request from the list of token owner 
    function deleteLoanRequestFromTokenOwner(address storageAddress, uint256 loanId, uint256 tokenId) public {
        address tokenOwner = SnarkBaseLib.getOwnerOfToken(address(uint160(storageAddress)), tokenId);
        if (SnarkLoanLibExt.isExistLoanRequestForTokenOwner(
                address(uint160(storageAddress)), tokenOwner, tokenId, loanId)
        ) {
            uint256 index = 
                getIndexOfLoanRequestForTokenOwnerByTokenAndLoan(
                    address(uint160(storageAddress)), tokenOwner, tokenId, loanId
                );
            uint256 maxIndex = getCountLoanRequestsForTokenOwner(address(uint160(storageAddress)), tokenOwner);
            if (maxIndex > 0) {
                maxIndex = maxIndex.sub(1);
                require(index <= maxIndex, 
                    "!!! deleteLoanRequestFromTokenOwner: index exceeds maxIndex of Loan requests");
                if (index < maxIndex) {
                    (uint256 maxIndexTokenId, uint256 maxIndexLoanId) = 
                        getLoanRequestForTokenOwnerByIndex(storageAddress, tokenOwner, maxIndex);
                    SnarkLoanLibExt.setTokenForLoanRequestByTokenOwnerAndIndex(
                        storageAddress, tokenOwner, index, maxIndexTokenId);
                    SnarkLoanLibExt.setLoanForLoanRequestByTokenOwnerAndIndex(
                        storageAddress, tokenOwner, index, maxIndexLoanId);
                    SnarkLoanLibExt.saveIndexOfLoanRequestForTokenOwnerByTokenAndLoan(
                        storageAddress, tokenOwner, maxIndexTokenId, maxIndexLoanId, index);
                }
                SnarkLoanLibExt.setTokenForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, maxIndex, 0);
                SnarkLoanLibExt.setLoanForLoanRequestByTokenOwnerAndIndex(storageAddress, tokenOwner, maxIndex, 0);
                decreaseCountLoanRequestsForTokenOwner(storageAddress, tokenOwner);
                setExistingLoanRequestForTokenOwner(storageAddress, tokenOwner, tokenId, loanId, false);
            }
        }
        
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
        tokenId = SnarkStorage(address(uint160(storageAddress))).uintStorage(
            keccak256(abi.encodePacked("LoanRequestsForToken", tokenOwner, index))
        );
        loanId = SnarkStorage(address(uint160(storageAddress))).uintStorage(
            keccak256(abi.encodePacked("LoanRequestsForLoan", tokenOwner, index))
        );
    }

    /// @notice returns total loan requests for token owner 
    function getCountLoanRequestsForTokenOwner(address storageAddress, address tokenOwner)
        public
        view
        returns (uint256)
    {
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(
            keccak256(abi.encodePacked("LoanRequestsCount", tokenOwner))
        );
    }

    /// @notice increases total loan requests for token owner 
    function increaseCountLoanRequestsForTokenOwner(address storageAddress, address tokenOwner)
        public
        returns (uint256)
    {
        uint256 count = getCountLoanRequestsForTokenOwner(storageAddress, tokenOwner).add(1);
        SnarkStorage(address(uint160(storageAddress))).setUint(
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
        SnarkStorage(address(uint160(storageAddress))).setUint(
            keccak256(abi.encodePacked("LoanRequestsCount", tokenOwner)),
            count
        );
        return count;
    }

    function getLoanRequestsListForTokenOwner(address storageAddress, address tokenOwner)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 count = getCountLoanRequestsForTokenOwner(storageAddress, tokenOwner);
        uint256[] memory listOfTokens = new uint256[](count);
        uint256[] memory listOfLoans = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            (listOfTokens[i], listOfLoans[i]) = getLoanRequestForTokenOwnerByIndex(storageAddress, tokenOwner, i);
        }
        return (listOfTokens, listOfLoans);
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
        return SnarkStorage(address(uint160(storageAddress))).addressStorage(
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
        SnarkStorage(address(uint160(storageAddress))).setAddress(
            keccak256(abi.encodePacked("actualTokenOwnerForLoan", loanId, tokenId)),
            tokenOwner
        );
    }

    /// @notice return the offered loan amount for all tokens in the loan  
    function getPriceOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress)))
            .uintStorage(keccak256(abi.encodePacked("priceOfLoan", loanId)));
    }

    /// @notice set the offered loan amount for all tokens in the loan  
    function setPriceOfLoan(address storageAddress, uint256 loanId, uint256 price) public {
        SnarkStorage(address(uint160(storageAddress)))
            .setUint(keccak256(abi.encodePacked("priceOfLoan", loanId)), price);
    }

    /// @notice add loan to the loan list of the loan owner 
    function addLoanToLoanListOfLoanOwner(address storageAddress, address loanOwner, uint256 loanId) public {
        uint256 index = increaseCountOfLoansForLoanOwner(storageAddress, loanOwner).sub(1);
        setLoanToLoanListOfLoanOwnerByIndex(storageAddress, loanOwner, index, loanId);
        saveIndexOfLoanInLoanListOfLoanOwner(storageAddress, loanOwner, loanId, index);
        setExistingLoanInLoanListOfLoanOwner(storageAddress, loanOwner, loanId, true);
    }

    /// @notice remove loan from the loan list of the loan owner 
    function deleteLoanFromLoanListOfLoanOwner(address storageAddress, address loanOwner, uint256 loanId) public {
        if (isExistLoanInLoanListOfLoanOwner(storageAddress, loanOwner, loanId)) {
            uint256 index = getIndexOfLoanInLoanListOfLoanOwner(storageAddress, loanOwner, loanId);
            uint256 maxIndex = getCountOfLoansForLoanOwner(storageAddress, loanOwner);
            if (maxIndex > 0) {
                maxIndex = maxIndex.sub(1);
                if (index < maxIndex) {
                    uint256 lastLoan = getLoanFromLoanListOfLoanOwnerByIndex(storageAddress, loanOwner, maxIndex);
                    setLoanToLoanListOfLoanOwnerByIndex(storageAddress, loanOwner, index, lastLoan);
                    saveIndexOfLoanInLoanListOfLoanOwner(storageAddress, loanOwner, lastLoan, index);
                }
                setLoanToLoanListOfLoanOwnerByIndex(storageAddress, loanOwner, maxIndex, 0);
                decreaseCountOfLoansForLoanOwner(storageAddress, loanOwner);
                setExistingLoanInLoanListOfLoanOwner(storageAddress, loanOwner, loanId, false);
            }
        }
    }

    function setExistingLoanInLoanListOfLoanOwner(
        address storageAddress, 
        address loanOwner, 
        uint256 loanId, 
        bool isExist
    ) 
        public 
    {
        SnarkStorage(address(uint160(storageAddress))).setBool(
            keccak256(abi.encodePacked("SignOfExistingLoanInLoanListOfLoanOwner", loanOwner, loanId)),
            isExist
        );
    }

    function isExistLoanInLoanListOfLoanOwner(
        address storageAddress, 
        address loanOwner, 
        uint256 loanId
    ) 
        public 
        view 
        returns (bool) 
    {
        return SnarkStorage(address(uint160(storageAddress))).boolStorage(
            keccak256(abi.encodePacked("SignOfExistingLoanInLoanListOfLoanOwner", loanOwner, loanId))
        );
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
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(
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
        SnarkStorage(address(uint160(storageAddress))).setUint(
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
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(
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
        SnarkStorage(address(uint160(storageAddress))).setUint(
            keccak256(abi.encodePacked("loanIndexInLoanListOfLoanOwner", loanOwner, loanId)),
            index
        );
    }

    /// @notice increase the number of loans in the loan owner list
    function increaseCountOfLoansForLoanOwner(address storageAddress, address loanOwner) public returns (uint256) {
        uint256 count = getCountOfLoansForLoanOwner(storageAddress, loanOwner).add(1);
        SnarkStorage(address(uint160(storageAddress))).setUint(
            keccak256(abi.encodePacked("LoansNumberOfLoanOwner", loanOwner)),
            count
        );
        return count;
    }

    /// @notice decrease the number of loans in the loan owner list
    function decreaseCountOfLoansForLoanOwner(address storageAddress, address loanOwner) public returns (uint256) {
        uint256 count = getCountOfLoansForLoanOwner(storageAddress, loanOwner).sub(1);
        SnarkStorage(address(uint160(storageAddress))).setUint(
            keccak256(abi.encodePacked("LoansNumberOfLoanOwner", loanOwner)),
            count
        );
        return count;
    }

    /// @notice return the number of loans in the loan owner list
    function getCountOfLoansForLoanOwner(address storageAddress, address loanOwner) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(
            keccak256(abi.encodePacked("LoansNumberOfLoanOwner", loanOwner))
        );
    }

    /// @notice return loan list of the loan owner  
    function getLoansListOfLoanOwner(address storageAddress, address loanOwner) public view returns (uint256[] memory) {
        uint256 countLoans = getCountOfLoansForLoanOwner(storageAddress, loanOwner);
        uint256[] memory list = new uint256[](countLoans);
        for (uint256 i = 0; i < countLoans; i++) {
            list[i] = getLoanFromLoanListOfLoanOwnerByIndex(storageAddress, loanOwner, i);
        }
        return list;
    }

    /// @notice return the cost of gas for the call of function StopLoan
    function getCostOfStopLoanOperationForLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(
            keccak256(abi.encodePacked("costOfDeleteLoanOperation", loanId))
        );
    }

    /// @notice set the cost of gas for the call of function StopLoan
    function setCostOfStopLoanOperationForLoan(address storageAddress, uint256 loanId, uint256 cost) public {
        SnarkStorage(address(uint160(storageAddress))).setUint(
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
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(
            keccak256(abi.encodePacked("numberOfLoansForToken", tokenId))
        );
    }

    /// @notice increases the number of loans for a token 
    function increaseNumberOfLoansInTokensLoanList(address storageAddress, uint256 tokenId) public returns (uint256) {
        uint256 number = getNumberOfLoansInTokensLoanList(storageAddress, tokenId).add(1);
        SnarkStorage(address(uint160(storageAddress))).setUint(
            keccak256(abi.encodePacked("numberOfLoansForToken", tokenId)),
            number
        );
        return number;
    }

    /// @notice decrease the number of loans for a token 
    function decreaseNumberOfLoansInTokensLoanList(address storageAddress, uint256 tokenId) public returns (uint256) {
        uint256 number = getNumberOfLoansInTokensLoanList(storageAddress, tokenId).sub(1);
        SnarkStorage(address(uint160(storageAddress))).setUint(
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
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(
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
        SnarkStorage(address(uint160(storageAddress))).setUint(
            keccak256(abi.encodePacked("loanListForToken", tokenId, index)),
            loanId
        );
    }

    /// @notice returns the loan list from the token loan list 
    function getListOfNotFinishedLoansForToken(address storageAddress, uint256 tokenId) 
        public view returns (uint256[] memory) 
    {
        uint256 numberOfLoans = getNumberOfLoansInTokensLoanList(storageAddress, tokenId);
        uint256[] memory loanList = new uint256[](numberOfLoans);
        uint256 countOfNotFinishedLoans = 0;
        for (uint256 i = 0; i < numberOfLoans; i++) {
            uint256 loanId = getLoanFromLoansInTokensLoanListByIndex(storageAddress, tokenId, i);
            uint256 saleStatus = SnarkLoanLibExt.getLoanSaleStatus(storageAddress, loanId);
            if (saleStatus < 3) {
                loanList[countOfNotFinishedLoans] = loanId;
                countOfNotFinishedLoans++;
            }
        }
        uint256[] memory resultList = new uint256[](countOfNotFinishedLoans);
        for (uint256 i = 0; i < countOfNotFinishedLoans; i++) {
            resultList[i] = loanList[i];
        }
        return resultList;
    }

    /// @notice returns the loan list from the token loan list 
    function getListOfNotStartedLoansForToken(address storageAddress, uint256 tokenId) 
        public view returns (uint256[] memory) 
    {
        uint256 numberOfLoans = getNumberOfLoansInTokensLoanList(storageAddress, tokenId);
        uint256[] memory loanList = new uint256[](numberOfLoans);
        uint256 countOfNotStartedLoans = 0;
        for (uint256 i = 0; i < numberOfLoans; i++) {
            uint256 loanId = getLoanFromLoansInTokensLoanListByIndex(storageAddress, tokenId, i);
            uint256 saleStatus = SnarkLoanLibExt.getLoanSaleStatus(storageAddress, loanId);
            if (saleStatus < 2) {
                loanList[countOfNotStartedLoans] = loanId;
                countOfNotStartedLoans++;
            }
        }
        uint256[] memory resultList = new uint256[](countOfNotStartedLoans);
        for (uint256 i = 0; i < countOfNotStartedLoans; i++) {
            resultList[i] = loanList[i];
        }
        return resultList;
    }

    /// @notice returns true or false depending is the loan is in the token loan list 
    function isLoanInTokensLoanList(address storageAddress, uint256 tokenId, uint256 loanId)
        public
        view
        returns (bool)
    {
        return SnarkStorage(address(uint160(storageAddress))).boolStorage(
            keccak256(abi.encodePacked("isLoanInTokensLoanList", tokenId, loanId))
        );
    }

    /// @notice sets that the loan is in the token loan list 
    function markLoanInTokensLoanListAsInUse(address storageAddress, uint256 tokenId, uint256 loanId, bool isUsed) 
        public 
    {
        SnarkStorage(address(uint160(storageAddress))).setBool(
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
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(
            keccak256(abi.encodePacked("indexOfLoanInTokensLoanList", tokenId, loanId))
        );
    }

    /// @notice sets the loan index into the token loan list 
    function setIndexOfLoanInTokensLoanList(address storageAddress, uint256 tokenId, uint256 loanId, uint256 index)
        public 
    {
        SnarkStorage(address(uint160(storageAddress))).setUint(
            keccak256(abi.encodePacked("indexOfLoanInTokensLoanList", tokenId, loanId)),
            index
        );
    }

    /// @notice removal of token from loan.  possible only prior to loan start.
    function cancelTokenInLoan(address storageAddress, uint256 tokenId, uint256 loanId) public {
        require(
            SnarkLoanLibExt.getLoanSaleStatus(storageAddress, loanId) != 3,
            "Loan can't be in 'Finished' status"
        );
        uint256 startDate = SnarkLoanLibExt.getStartDateOfLoan(storageAddress, loanId);
        uint256 duration = SnarkLoanLibExt.getDurationOfLoan(storageAddress, loanId);
        makeTokenFreeForPeriod(storageAddress, tokenId, startDate, duration);
        deleteLoanRequestFromTokenOwner(storageAddress, loanId, tokenId);
        removeTokenFromListOfLoan(storageAddress, loanId, tokenId);
        removeLoanFromTokensLoanList(storageAddress, tokenId, loanId);
        markLoanInTokensLoanListAsInUse(storageAddress, tokenId, loanId, false);
        SnarkBaseLib.setSaleTypeToToken(address(uint160(storageAddress)), tokenId, 0);

        emit TokenCanceledInLoans(tokenId, loanId);
    }

    function cancelTokenFromAllLoans(address storageAddress, uint256 tokenId) public {
        uint256[] memory loanList = getListOfNotFinishedLoansForToken(storageAddress, tokenId);
        for (uint256 i = 0; i < loanList.length; i++) {
            uint256 startDate = SnarkLoanLibExt.getStartDateOfLoan(storageAddress, loanList[i]);
            uint256 duration = SnarkLoanLibExt.getDurationOfLoan(storageAddress, loanList[i]);
            makeTokenFreeForPeriod(storageAddress, tokenId, startDate, duration);
            deleteLoanRequestFromTokenOwner(storageAddress, loanList[i], tokenId);
            removeTokenFromListOfLoan(storageAddress, loanList[i], tokenId);
            removeLoanFromTokensLoanList(storageAddress, tokenId, loanList[i]);
            markLoanInTokensLoanListAsInUse(storageAddress, tokenId, loanList[i], false);
            SnarkBaseLib.setSaleTypeToToken(address(uint160(storageAddress)), tokenId, 0);

            emit TokenCanceledInLoans(tokenId, loanList[i]);
        }
    }

    function cancelLoan(address storageAddress, uint256 loanId) public {
        SnarkLoanLibExt.setLoanSaleStatus(storageAddress, loanId, 3); // 3 - Finished
        address loanOwner = SnarkLoanLibExt.getOwnerOfLoan(storageAddress, loanId);
        uint256 startDate = SnarkLoanLibExt.getStartDateOfLoan(storageAddress, loanId);
        uint256 duration = SnarkLoanLibExt.getDurationOfLoan(storageAddress, loanId);
        uint256[] memory approvedTokens = SnarkLoanLibExt.getTokensListOfLoanByType(storageAddress, loanId, 1);
        for (uint256 i = 0; i < approvedTokens.length; i++) {
            makeTokenFreeForPeriod(storageAddress, approvedTokens[i], startDate, duration);
            deleteLoanRequestFromTokenOwner(storageAddress, loanId, approvedTokens[i]);
            SnarkBaseLib.setSaleTypeToToken(address(uint160(storageAddress)), approvedTokens[i], 0);
        }
        uint256[] memory notApprovedTokens = SnarkLoanLibExt.getTokensListOfLoanByType(storageAddress, loanId, 0);
        for (uint256 i = 0; i < notApprovedTokens.length; i++) {
            deleteLoanRequestFromTokenOwner(storageAddress, loanId, notApprovedTokens[i]);
        }
        uint256[] memory declinedTokens = SnarkLoanLibExt.getTokensListOfLoanByType(storageAddress, loanId, 2);
        for (uint256 i = 0; i < declinedTokens.length; i++) {
            deleteLoanRequestFromTokenOwner(storageAddress, loanId, declinedTokens[i]);
        }

        deleteLoanFromLoanListOfLoanOwner(storageAddress, loanOwner, loanId);
    }

}
