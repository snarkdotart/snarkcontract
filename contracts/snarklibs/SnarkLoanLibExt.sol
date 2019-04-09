pragma solidity >=0.5.0;

import "../openzeppelin/SafeMath.sol";
import "../SnarkStorage.sol";
import "./SnarkBaseLib.sol";


library SnarkLoanLibExt {

    using SafeMath for uint256;

    // /// @notice increase the number of loans in the system 
    // function increaseNumberOfLoans(address storageAddress) public returns (uint256) {
    //     uint256 totalNumber = getTotalNumberOfLoans(storageAddress).add(1);
    //     SnarkStorage(address(uint160(storageAddress))).setUint(keccak256("totalNumberOfLoans"), totalNumber);
    //     return totalNumber;
    // }

    // /// @notice returns total number of loans in the system 
    // function getTotalNumberOfLoans(address storageAddress) public view returns (uint256) {
    //     return SnarkStorage(address(uint160(storageAddress))).uintStorage(keccak256("totalNumberOfLoans"));
    // }

    // /// @notice returns loan owner 
    // function getOwnerOfLoan(address storageAddress, uint256 loanId) public view returns (address) {
    //     return SnarkStorage(address(uint160(storageAddress)))
    //         .addressStorage(keccak256(abi.encodePacked("loanOwner", loanId)));
    // }

    // /// @notice sets the loan owner
    // function setOwnerOfLoan(address storageAddress, address loanOwner, uint256 loanId) public {
    //     SnarkStorage(address(uint160(storageAddress))).setAddress(
    //         keccak256(abi.encodePacked("loanOwner", loanId)),
    //         loanOwner
    //     );
    // }

    // /// @notice check is the token is participating in a loan or not 
    // function isTokenIncludedInLoan(address storageAddress, uint256 loanId, uint256 tokenId)
    //     public 
    //     view 
    //     returns (bool)
    // {
    //     return SnarkStorage(address(uint160(storageAddress))).boolStorage(
    //         keccak256(abi.encodePacked("isTokenIncludedInLoan", loanId, tokenId))
    //     );
    // }

    // /// @notice set that the token is participating in the selected loan 
    // function setTokenAsIncludedInLoan(address storageAddress, uint256 loanId, uint256 tokenId, bool isIncluded) 
    //     public 
    // {
    //     SnarkStorage(address(uint160(storageAddress))).setBool(
    //         keccak256(abi.encodePacked("isTokenIncludedInLoan", loanId, tokenId)),
    //         isIncluded
    //     );
    // }

    // /// @notice return the list type the token belongs to
    // function getTypeOfTokenListForLoan(address storageAddress, uint256 loanId, uint256 tokenId) 
    //     public 
    //     view 
    //     returns (uint256) 
    // {
    //     return SnarkStorage(address(uint160(storageAddress))).uintStorage(
    //         keccak256(abi.encodePacked("typeOfTokenListForLoan", loanId, tokenId))
    //     );
    // }

    // /// @notice set to which list type the token belongs to 
    // function setTypeOfTokenListForLoan(address storageAddress, uint256 loanId, uint256 tokenId, uint256 listType) 
    //     public
    // {
    //     SnarkStorage(address(uint160(storageAddress))).setUint(
    //         keccak256(abi.encodePacked("typeOfTokenListForLoan", loanId, tokenId)),
    //         listType
    //     );
    // }

    // /// @notice returns the number of tokens in the specific list
    // function getNumberOfTokensInListByType(address storageAddress, uint256 loanId, uint256 listType) 
    //     public 
    //     view 
    //     returns (uint256) 
    // {
    //     return SnarkStorage(address(uint160(storageAddress))).uintStorage(
    //         keccak256(abi.encodePacked("numberOfTokensInListByType", loanId, listType))
    //     );
    // }

    // /// @notice increase the number of tokens in the specific list
    // function increaseNumberOfTokensInListByType(address storageAddress, uint256 loanId, uint256 listType) 
    //     public 
    //     returns (uint256) 
    // {
    //     uint256 numberOfTokens = getNumberOfTokensInListByType(storageAddress, loanId, listType).add(1);
    //     SnarkStorage(address(uint160(storageAddress))).setUint(
    //         keccak256(abi.encodePacked("numberOfTokensInListByType", loanId, listType)), 
    //         numberOfTokens
    //     );
    //     return numberOfTokens;
    // }

    // /// @notice decrease the number of tokens in the specific list 
    // function decreaseNumberOfTokensInListByType(address storageAddress, uint256 loanId, uint256 listType) 
    //     public 
    //     returns (uint256) 
    // {
    //     uint256 numberOfTokens = getNumberOfTokensInListByType(storageAddress, loanId, listType).sub(1);
    //     SnarkStorage(address(uint160(storageAddress))).setUint(
    //         keccak256(abi.encodePacked("numberOfTokensInListByType", loanId, listType)), 
    //         numberOfTokens
    //     );
    //     return numberOfTokens;
    // }

    // /// @notice receive token id from the list of specific type in a specific index
    // function getTokenForLoanListByTypeAndIndex(
    //     address storageAddress, 
    //     uint256 loanId, 
    //     uint256 listType, 
    //     uint256 index
    // ) 
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return SnarkStorage(address(uint160(storageAddress))).uintStorage(
    //         keccak256(abi.encodePacked("tokensListOfLoanByType", loanId, listType, index))
    //     );
    // }

    // /// @notice set token into the list of specific type and a specific index 
    // function setTokenForLoanListByTypeAndIndex(
    //     address storageAddress, 
    //     uint256 loanId, 
    //     uint256 listType, 
    //     uint256 index, 
    //     uint256 tokenId
    // ) 
    //     public
    // {
    //     SnarkStorage(address(uint160(storageAddress))).setUint(
    //         keccak256(abi.encodePacked("tokensListOfLoanByType", loanId, listType, index)), 
    //         tokenId
    //     );
    //     setTokenIndexInListOfLoanByType(storageAddress, loanId, tokenId, index);
    // }

    // /// @notice return tokens in a specific list (NotApproved, Approved, Declined)
    // function getTokensListOfLoanByType(address storageAddress, uint256 loanId, uint256 listType) 
    //     public 
    //     view 
    //     returns (uint256[] memory) 
    // {
    //     uint256 amount = getNumberOfTokensInListByType(storageAddress, loanId, listType);
    //     uint256[] memory list = new uint256[](amount);
    //     for (uint256 i = 0; i < amount; i++) {
    //         list[i] = getTokenForLoanListByTypeAndIndex(storageAddress, loanId, listType, i);
    //     }
    //     return list;
    // }

    // /// @notice return token index in the list, doesnt matter in which one since the token 
    // can only exist in only 1 of 3
    // function getTokenIndexInListOfLoanByType(
    //     address storageAddress,
    //     uint256 loanId,
    //     uint256 tokenId
    // ) 
    //     public 
    //     view 
    //     returns (uint256) 
    // {
    //     return SnarkStorage(address(uint160(storageAddress))).uintStorage(
    //         keccak256(abi.encodePacked("tokenIndexInsideListOfLoan", loanId, tokenId))
    //     );
    // }

    // /// @notice set under which index the token is in the list
    // function setTokenIndexInListOfLoanByType(
    //     address storageAddress,
    //     uint256 loanId,
    //     uint256 tokenId,
    //     uint256 index
    // )
    //     public 
    // {
    //     SnarkStorage(address(uint160(storageAddress))).setUint(
    //         keccak256(abi.encodePacked("tokenIndexInsideListOfLoan", loanId, tokenId)),
    //         index
    //     );
    // }

    // /// @notice return date of the loan start 
    // function getStartDateOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
    //     return SnarkStorage(address(uint160(storageAddress)))
    //         .uintStorage(keccak256(abi.encodePacked("loanToStartDate", loanId)));
    // }

    // /// @notice set date of the loan start 
    // function setStartDateOfLoan(address storageAddress, uint256 loanId, uint256 startDate) public {
    //     SnarkStorage(address(uint160(storageAddress)))
    //         .setUint(keccak256(abi.encodePacked("loanToStartDate", loanId)), startDate);
    // }

    // /// @notice return loan duration 
    // function getDurationOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
    //     return SnarkStorage(address(uint160(storageAddress)))
    //         .uintStorage(keccak256(abi.encodePacked("loanToDuration", loanId)));
    // }

    // /// @notice set loan duration 
    // function setDurationOfLoan(address storageAddress, uint256 loanId, uint256 duration) public {
    //     SnarkStorage(address(uint160(storageAddress)))
    //         .setUint(keccak256(abi.encodePacked("loanToDuration", loanId)), duration);
    // }

    // /// @notice return loan status
    // function getLoanSaleStatus(address storageAddress, uint256 loanId) public view returns (uint256) {
    //     return SnarkStorage(address(uint160(storageAddress)))
    //         .uintStorage(keccak256(abi.encodePacked("loanToSaleStatus", loanId)));
    // }

    // /// @notice set loan status
    // function setLoanSaleStatus(address storageAddress, uint256 loanId, uint256 saleStatus) public {
    //     SnarkStorage(address(uint160(storageAddress)))
    //         .setUint(keccak256(abi.encodePacked("loanToSaleStatus", loanId)), saleStatus);
    // }

    // /// @notice checks in the token calendar if it is busy on a specific date 
    // function isTokenBusyOnDay(address storageAddress, uint256 tokenId, uint256 day) public view returns (bool) {
    //     return SnarkStorage(address(uint160(storageAddress))).boolStorage(
    //         keccak256(abi.encodePacked("tokenCalendar", tokenId, day))
    //     );
    // }

    // /// @notice returns loan id from the token calendar on a specific date 
    // function getEventIdOnDayForToken(address storageAddress, uint256 tokenId, uint256 date) 
    //     public 
    //     view 
    //     returns (uint256) 
    // {
    //     uint256 day = date.div(86400000);
    //     SnarkStorage(address(uint160(storageAddress))).uintStorage(
    //         keccak256(abi.encodePacked("tokenCalendarDayToEventId", tokenId, day))
    //     );
    // }

    // /// @notice marks that the token is busy on a specific date and by which loan 
    // function makeTokenBusyOnDay(address storageAddress, uint256 loanId, uint256 tokenId, uint256 date) public {
    //     uint256 day = date.div(86400000);
    //     SnarkStorage(address(uint160(storageAddress))).setBool(
    //         keccak256(abi.encodePacked("tokenCalendar", tokenId, day)),
    //         true
    //     );
    //     SnarkStorage(address(uint160(storageAddress))).setUint(
    //         keccak256(abi.encodePacked("tokenCalendarDayToEventId", tokenId, day)),
    //         loanId
    //     );
    // }

    // /// @notice frees up in the calendar a specific token on a specific date 
    // function makeTokenFreeOnDay(address storageAddress, uint256 tokenId, uint256 day) public {
    //     SnarkStorage(address(uint160(storageAddress))).setBool(
    //         keccak256(abi.encodePacked("tokenCalendar", tokenId, day)),
    //         false
    //     );
    //     SnarkStorage(address(uint160(storageAddress))).setUint(
    //         keccak256(abi.encodePacked("tokenCalendarDayToEventId", tokenId, day)),
    //         0
    //     );
    // }

    // /// @notice returns maximum duration for which a token can be loaned  
    // function getDefaultLoanDuration(address storageAddress) public view returns (uint256) {
    //     return SnarkStorage(address(uint160(storageAddress))).uintStorage(keccak256("defaultLoanDuration"));
    // }

    // /// @notice set maximum duration for which a token can be loaned  
    // function setDefaultLoanDuration(address storageAddress, uint256 duration) public {
    //     SnarkStorage(address(uint160(storageAddress))).setUint(keccak256("defaultLoanDuration"), duration);
    // }

    // function isExistLoanRequestForTokenOwner(
    //     address storageAddress, 
    //     address tokenOwner, 
    //     uint256 tokenId, 
    //     uint256 loanId
    // )
    //     public
    //     view
    //     returns (bool)
    // {
    //     return SnarkStorage(address(uint160(storageAddress))).boolStorage(
    //         keccak256(abi.encodePacked("SignOfExistingLoanRequestForTokenOwner", tokenOwner, tokenId, loanId))
    //     );
    // }

    // /// @notice sets the token into request list for the token owner and index 
    // function setTokenForLoanRequestByTokenOwnerAndIndex(
    //     address storageAddress, 
    //     address tokenOwner, 
    //     uint256 index, 
    //     uint256 tokenId
    // )
    //     public
    // {
    //     SnarkStorage(address(uint160(storageAddress))).setUint(
    //         keccak256(abi.encodePacked("LoanRequestsForToken", tokenOwner, index)),
    //         tokenId
    //     );
    // }

    // /// @notice sets loan into request list for token owners and index 
    // function setLoanForLoanRequestByTokenOwnerAndIndex(
    //     address storageAddress, 
    //     address tokenOwner, 
    //     uint256 index, 
    //     uint256 loanId
    // )
    //     public
    // {
    //     SnarkStorage(address(uint160(storageAddress))).setUint(
    //         keccak256(abi.encodePacked("LoanRequestsForLoan", tokenOwner, index)),
    //         loanId
    //     );
    // }

    // /// @notice save loan request index for token owner 
    // function saveIndexOfLoanRequestForTokenOwnerByTokenAndLoan(
    //     address storageAddress,
    //     address tokenOwner,
    //     uint256 tokenId,
    //     uint256 loanId,
    //     uint256 index
    // ) 
    //     public 
    // {
    //     SnarkStorage(address(uint160(storageAddress))).setUint(
    //         keccak256(abi.encodePacked("IndexOfLoanRequestForTokenOwner", tokenOwner, tokenId, loanId)),
    //         index
    //     );
    // }

    ///////////////////////////////// FOR NEW LOAN LOGIC /////////////////////////////////

    // // TEMPORARY TEST FUNC
    // function isLoanActive(address storageAddress) public view returns (bool) {
    //     return SnarkStorage(address(uint160(storageAddress))).
    //         boolStorage(keccak256("isActiveLoan"));
    // }

    // function setActiveLoan(address storageAddress, bool isActive) public {
    //     SnarkStorage(address(uint160(storageAddress))).
    //         setBool(keccak256("isActiveLoan"), isActive);
    // }

    // TODO: add functions for array
    // public addElementToArray(address sa, string key, uint256 value)
    // public deleteElementFromArray(address sa, string key, uint256 value)
    // public getArrayLength(address sa, string key, uint256 value)
    // private setIndexOfElement()
    // TODO: loan list (not array)
    // function addLoanToList(address storageAddress, uint256 loanId) public {}
}
