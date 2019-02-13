pragma solidity ^0.4.24;

import "./snarklibs/SnarkLoanLib.sol";
import "./snarklibs/SnarkBaseLib.sol";

contract SnarkTestFunctions {
    using SnarkLoanLib for address;
    using SnarkBaseLib for address;

    address _storage;
    constructor(address storageAddress) public {
        _storage = storageAddress;
    }

    function getCountLoanRequestsForTokenOwner(address _tokenOwner) public view  returns (uint256) {
        return _storage.getCountLoanRequestsForTokenOwner(_tokenOwner);
    }

    function getIndexOfLoanRequestForTokenOwnerByTokenAndLoan(address tokenOwner, uint tokenId, uint loanId) public view returns (uint256) {
        return _storage.getIndexOfLoanRequestForTokenOwnerByTokenAndLoan(tokenOwner,tokenId,loanId);
    }

    function getListOfLoansFromTokensLoanList(uint256 tokenId) public view returns (uint256[]) 
    {
        return _storage.getListOfLoansFromTokensLoanList(tokenId);
    }

    function getNumberOfLoansInTokensLoanList(uint256 tokenId) public view returns (uint256) 
    {
        return _storage.getNumberOfLoansInTokensLoanList(tokenId);
    }

    function getSaleTypeToToken(uint256 tokenId) public view returns (uint256)
    {
        return _storage.getSaleTypeToToken(tokenId);
    }

    function getTypeOfTokenListForLoan(uint256 loanId, uint256 tokenId) 
        public 
        view 
        returns (uint256) 
    {
        return _storage.getTypeOfTokenListForLoan(loanId, tokenId);
    }

    function getTokenIndexInListOfLoanByType(uint256 loanId, uint256 tokenId) 
        public 
        view 
        returns (uint256) 
    {
        return _storage.getTokenIndexInListOfLoanByType(loanId, tokenId);
    }

    function getTokenForLoanListByTypeAndIndex(uint256 loanId, uint256 listType, uint256 index) 
        public
        view
        returns (uint256)
    {
        return _storage.getTokenForLoanListByTypeAndIndex(loanId, listType, index);
    }

    function getNumberOfTokensInListByType(uint256 loanId, uint256 listType) 
        public 
        view 
        returns (uint256) 
    {
        return _storage.getNumberOfTokensInListByType(loanId, listType);
    }

    function addTokenToListOfLoan(uint256 loanId, uint256 tokenId, uint256 listType) public {
        _storage.addTokenToListOfLoan(loanId, tokenId, listType);
    }

    function removeTokenFromListOfLoan(uint256 loanId, uint256 tokenId) public {
        _storage.removeTokenFromListOfLoan(loanId, tokenId);
    }

    function makeTokenFreeForPeriod(uint256 tokenId, uint256 startDate, uint256 duration) public {
        _storage.makeTokenFreeForPeriod(tokenId, startDate, duration);
    }

    function addLoanRequestToTokenOwner(address tokenOwner, uint256 tokenId, uint256 loanId) public {
        _storage.addLoanRequestToTokenOwner(tokenOwner, tokenId, loanId);
    }

    function deleteLoanRequestFromTokenOwner(uint256 loanId, uint256 tokenId) public {
        _storage.deleteLoanRequestFromTokenOwner(loanId, tokenId);
    }

}
