pragma solidity >=0.5.0;

import "./snarklibs/SnarkLoanLib.sol";
import "./snarklibs/SnarkLoanLibExt.sol";
import "./snarklibs/SnarkBaseLib.sol";


contract SnarkTestFunctions {

    using SnarkLoanLib for address;
    using SnarkLoanLibExt for address;
    using SnarkBaseLib for address;

    address private _storage;

    constructor(address storageAddress) public {
        _storage = storageAddress;
    }

    function getCountLoanRequestsForTokenOwner(address _tokenOwner) public view  returns (uint256) {
        return SnarkLoanLib.getCountLoanRequestsForTokenOwner(address(uint160(_storage)), _tokenOwner);
    }

    function getIndexOfLoanRequestForTokenOwnerByTokenAndLoan(address tokenOwner, uint tokenId, uint loanId) 
        public view returns (uint256) 
    {
        return SnarkLoanLib.getIndexOfLoanRequestForTokenOwnerByTokenAndLoan(
            address(uint160(_storage)), tokenOwner, tokenId, loanId);
    }

    function getListOfNotFinishedLoansForToken(uint256 tokenId) public view returns (uint256[] memory) 
    {
        return SnarkLoanLib.getListOfNotFinishedLoansForToken(address(uint160(_storage)), tokenId);
    }

    function getNumberOfLoansInTokensLoanList(uint256 tokenId) public view returns (uint256) 
    {
        return SnarkLoanLib.getNumberOfLoansInTokensLoanList(address(uint160(_storage)), tokenId);
    }

    function getSaleTypeToToken(uint256 tokenId) public view returns (uint256)
    {
        return SnarkBaseLib.getSaleTypeToToken(address(uint160(_storage)), tokenId);
    }

    function getTypeOfTokenListForLoan(uint256 loanId, uint256 tokenId) 
        public 
        view 
        returns (uint256) 
    {
        return SnarkLoanLibExt.getTypeOfTokenListForLoan(address(uint160(_storage)), loanId, tokenId);
    }

    function getTokenIndexInListOfLoanByType(uint256 loanId, uint256 tokenId) 
        public 
        view 
        returns (uint256) 
    {
        return SnarkLoanLibExt.getTokenIndexInListOfLoanByType(address(uint160(_storage)), loanId, tokenId);
    }

    function getTokenForLoanListByTypeAndIndex(uint256 loanId, uint256 listType, uint256 index) 
        public
        view
        returns (uint256)
    {
        return SnarkLoanLibExt.getTokenForLoanListByTypeAndIndex(address(uint160(_storage)), loanId, listType, index);
    }

    function getNumberOfTokensInListByType(uint256 loanId, uint256 listType) 
        public 
        view 
        returns (uint256) 
    {
        return SnarkLoanLibExt.getNumberOfTokensInListByType(address(uint160(_storage)), loanId, listType);
    }

    ///////////////////////////
    function addTokenToListOfLoan(uint256 loanId, uint256 tokenId, uint256 listType) public {
        SnarkLoanLib.addTokenToListOfLoan(address(uint160(_storage)), loanId, tokenId, listType);
    }

    function removeTokenFromListOfLoan(uint256 loanId, uint256 tokenId) public {
        SnarkLoanLib.removeTokenFromListOfLoan(address(uint160(_storage)), loanId, tokenId);
    }

    function makeTokenFreeForPeriod(uint256 tokenId, uint256 startDate, uint256 duration) public {
        SnarkLoanLib.makeTokenFreeForPeriod(address(uint160(_storage)), tokenId, startDate, duration);
    }

    ///////////////////////////
    function addLoanRequestToTokenOwner(address tokenOwner, uint256 tokenId, uint256 loanId) public {
        SnarkLoanLib.addLoanRequestToTokenOwner(address(uint160(_storage)), tokenOwner, tokenId, loanId);
    }

    function deleteLoanRequestFromTokenOwner(uint256 loanId, uint256 tokenId) public {
        SnarkLoanLib.deleteLoanRequestFromTokenOwner(address(uint160(_storage)), loanId, tokenId);
    }

    ///////////////////////////
    function addLoanToLoanListOfLoanOwner(address loanOwner, uint256 loanId) public {
        SnarkLoanLib.addLoanToLoanListOfLoanOwner(address(uint160(_storage)), loanOwner, loanId);
    }

    function deleteLoanFromLoanListOfLoanOwner(address loanOwner, uint256 loanId) public {
        SnarkLoanLib.deleteLoanFromLoanListOfLoanOwner(address(uint160(_storage)), loanOwner, loanId);
    }

    function isExistLoanInLoanListOfLoanOwner(address loanOwner, uint256 loanId) public view returns (bool) {
        return SnarkLoanLib.isExistLoanInLoanListOfLoanOwner(address(uint160(_storage)), loanOwner, loanId);
    }

    function getLoanFromLoanListOfLoanOwnerByIndex(address loanOwner, uint256 index) public view returns (uint256) {
        return SnarkLoanLib.getLoanFromLoanListOfLoanOwnerByIndex(address(uint160(_storage)), loanOwner, index);
    }

    function getCountOfLoansForLoanOwner(address loanOwner) public view returns (uint256) {
        return SnarkLoanLib.getCountOfLoansForLoanOwner(address(uint160(_storage)), loanOwner);
    }

    function getLoansListOfLoanOwner(address loanOwner) public view returns (uint256[] memory) {
        return SnarkLoanLib.getLoansListOfLoanOwner(address(uint160(_storage)), loanOwner);
    }
}
